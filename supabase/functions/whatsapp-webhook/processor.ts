// NLU Pipeline — Core message processor for WhatsApp bot
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { chatCompletion, transcribeAudio, type ChatMessage } from "../_shared/openai.ts";
import { customerTools, executeCustomerFunction } from "./customer_functions.ts";
import { sendWhatsAppMessage, downloadMedia } from "./twilio_api.ts";

const MAX_FUNCTION_CALLS = 3;
const MESSAGE_HISTORY_LIMIT = 10;

interface InboundMessage {
  phone: string;
  text?: string;
  name?: string;
  // Voice message fields
  audioMediaId?: string;
  // Image message fields
  imageMediaId?: string;
  imageCaption?: string;
  // Location fields
  latitude?: number;
  longitude?: number;
}

/**
 * Process an inbound WhatsApp message through the full NLU pipeline.
 * This is the core function shared by both whatsapp-webhook and whatsapp-simulate.
 */
export async function processInboundMessage(
  db: SupabaseClient,
  message: InboundMessage
): Promise<{ reply: string; conversationId: string }> {
  const { phone, name } = message;

  // 1. Get or create conversation
  const conversation = await getOrCreateConversation(db, phone, name);
  const conversationId = conversation.id as string;

  // 2. Resolve message content (handle voice transcription)
  let messageContent = message.text ?? "";
  let messageType = "text";

  if (message.audioMediaId) {
    messageType = "voice";
    try {
      const audioData = await downloadMedia(message.audioMediaId);
      messageContent = await transcribeAudio(audioData);
    } catch (e) {
      messageContent = "[Messaggio vocale non riconosciuto]";
      console.error("Voice transcription failed:", e);
    }
  } else if (message.imageMediaId) {
    messageType = "image";
    messageContent = message.imageCaption ?? "[Immagine ricevuta]";
  } else if (message.latitude !== undefined) {
    messageType = "location";
    messageContent = `[Posizione: ${message.latitude}, ${message.longitude}]`;
  }

  // 3. Save inbound message to DB
  await db.from("whatsapp_messages").insert({
    conversation_id: conversationId,
    phone: phone,
    direction: "inbound",
    content: messageContent,
    message_type: messageType,
    wa_message_id: (message as any).id ?? null,
    status: "sent",
  });

  // Update last_message_at
  await db
    .from("whatsapp_conversations")
    .update({ last_message_at: new Date().toISOString() })
    .eq("id", conversationId);

  // 4. Fetch message history
  const { data: historyData } = await db
    .from("whatsapp_messages")
    .select("direction, content, message_type")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: false })
    .limit(MESSAGE_HISTORY_LIMIT);

  const history: ChatMessage[] = (historyData ?? [])
    .reverse()
    .map((m: Record<string, unknown>) => ({
      role: m.direction === "inbound" ? "user" as const : "assistant" as const,
      content: m.content as string,
    }));

  // 5. Build system prompt
  const systemPrompt = buildCustomerSystemPrompt(
    conversation.customer_name as string || name || "Cliente",
    conversation.state as string
  );

  // 6. Call OpenAI with function calling
  const messages: ChatMessage[] = [
    { role: "system", content: systemPrompt },
    ...history,
  ];

  let response = await chatCompletion({
    messages,
    tools: customerTools,
    maxTokens: 512,
    temperature: 0.7,
  });

  // 7. Function calling loop (max 3 iterations)
  let iterations = 0;
  while (response.toolCalls.length > 0 && iterations < MAX_FUNCTION_CALLS) {
    messages.push({
      role: "assistant",
      content: response.content,
      tool_calls: response.toolCalls,
    });

    for (const toolCall of response.toolCalls) {
      let args: Record<string, unknown> = {};
      try {
        args = JSON.parse(toolCall.function.arguments || "{}");
      } catch {
        console.error("Failed to parse tool args:", toolCall.function.arguments);
      }
      const result = await executeCustomerFunction(
        toolCall.function.name,
        args,
        db,
        conversationId,
        phone
      );

      messages.push({
        role: "tool",
        content: result,
        tool_call_id: toolCall.id,
      });
    }

    response = await chatCompletion({
      messages,
      tools: customerTools,
    });

    iterations++;
  }

  const reply =
    response.content?.trim() ??
    "Mi dispiace, non sono riuscito a capire. Puoi riprovare?";

  // 8. Send reply via WhatsApp API
  const sendResult = await sendWhatsAppMessage(phone, reply);

  // 9. Save outbound message to DB
  await db.from("whatsapp_messages").insert({
    conversation_id: conversationId,
    phone: phone,
    direction: "outbound",
    content: reply,
    message_type: "text",
    wa_message_id: sendResult.messageId ?? null,
    status: sendResult.success ? "sent" : "failed",
    tokens_used: response.usage.total_tokens,
  });

  return { reply, conversationId };
}

// ── Helpers ──────────────────────────────────────────────────────

async function getOrCreateConversation(
  db: SupabaseClient,
  phone: string,
  name?: string
): Promise<Record<string, unknown>> {
  // Try to find existing customer conversation
  const { data: existing } = await db
    .from("whatsapp_conversations")
    .select("*")
    .eq("phone", phone)
    .eq("conversation_type", "customer")
    .maybeSingle();

  if (existing) {
    // Update name if provided and not set
    if (name && !existing.customer_name) {
      await db
        .from("whatsapp_conversations")
        .update({ customer_name: name })
        .eq("id", existing.id);
    }
    return existing;
  }

  // Create new customer conversation
  const { data: created, error } = await db
    .from("whatsapp_conversations")
    .insert({
      phone,
      customer_name: name ?? null,
      conversation_type: "customer",
      state: "idle",
    })
    .select("*")
    .single();

  if (error || !created) {
    throw new Error(`Failed to create conversation: ${error?.message}`);
  }

  return created;
}

function buildCustomerSystemPrompt(
  customerName: string,
  conversationState: string
): string {
  return `Sei l'assistente WhatsApp di dloop, il servizio di delivery locale in Campania.
Parli in italiano in modo naturale, cordiale, e sempre utile.
Rispondi in 3-5 frasi brevi ma complete, adatte a WhatsApp.
IMPORTANTE: Sii sempre amichevole e disponibile. Non menzionare funzioni tecniche ai clienti.

## Chi sei
- Sei l'assistente di dloop, qui per aiutare il cliente a trovare prodotti e ordinare
- Dloop offre delivery veloce (30-60 min) da negozi partner a Napoli e provincia
- Rispondi in modo naturale, come farebbe un amico simpatico

## Cliente
- Nome: ${customerName}
- Stato: ${conversationState}

## ⭐ DEALER ROUTING (MOLTO IMPORTANTE!)
Dloop ha 4 negozi partner, ognuno specializzato in una categoria:

🐾 **TOELETTATURA PET** → Prodotti per animali, toelettatura, accessori pet
🛒 **PICCOLO SUPERMARKET** → Generi alimentari, spesa, prodotti freschi
🥬 **NATURASÌ VOMERO** → Prodotti biologici, alimenti naturali, benessere
👔 **YAMAMAY/CARPISA** → Moda, abbigliamento, accessori, lusso

**REGOLA D'ORO**: Quando il cliente chiede un tipo di prodotto, suggerisci SEMPRE il negozio specializzato per quella categoria!

Esempi:
- Cliente: "Mi servono boccette di shampoo per cani" → Suggerisci TOELETTATURA PET
- Cliente: "Voglio frutta e verdura fresca" → Suggerisci PICCOLO SUPERMARKET
- Cliente: "Mi interessa roba biologica" → Suggerisci NATURASÌ VOMERO
- Cliente: "Cerco una maglietta bella" → Suggerisci YAMAMAY/CARPISA

## Come aiutare il cliente (PER TE, NON PER IL CLIENTE)
1. **Ascolta cosa cerca il cliente** → Identifica la categoria (PET/GROCERY/ORGANIC/FASHION)
2. **Suggerisci il negozio giusto** → "Perfetto! Abbiamo TOELETTATURA PET che fa esattamente quello"
3. **Mostra i prodotti** → Usa browse_dealer_menu con il nome del negozio (es. "Toelettatura Pet")
4. **Cliente sceglie** → Chiedi indirizzo di consegna
5. **Crea l'ordine** → Usa create_delivery_order con il nome del negozio scelto
6. **Pagamento** → Offri link Stripe o contanti/POS

## Stile di conversazione DEALER-FOCUSED
- ✅ "Ciao! Cerchi prodotti per animali? Abbiamo TOELETTATURA PET con tutto quello che serve!"
- ✅ "Perfetto! Da PICCOLO SUPERMARKET trovi frutta fresca, verdure e tanta qualità"
- ✅ "Per roba bio, NATURASÌ VOMERO è il top! Cosa ti interessa?"
- ✅ "Se cerchi moda e stile, YAMAMAY/CARPISA ha le ultime collezioni"
- ❌ NON dire: "Sto usando browse_dealer_menu"
- ❌ NON menzionare funzioni tecniche
- ❌ NON suggerire negozi sbagliati per la categoria

## Flow naturale DEALER-BASED
1. Cliente dice cosa vuole → Tu identifichi la categoria
2. Tu suggerisci il negozio specializzato (con entusiasmo!)
3. Tu mostri i prodotti disponibili da quel negozio (prezzi + descrizioni)
4. Cliente sceglie → Tu chiedi indirizzo
5. Tu crei l'ordine dal negozio scelto
6. Tu comunichi il codice + tempo stimato (30-45 min) + link di pagamento

## Regole importanti
- SEMPRE suggerire il negozio SPECIALIZZATO per la categoria che il cliente cerca
- Chiedi SEMPRE l'indirizzo completo prima di creare un ordine
- Usa il nome ESATTO del negozio quando crei l'ordine (es. "Toelettatura Pet", non "Pet Shop")
- Se il cliente non sa cosa vuole, offri tutte le 4 categorie
- Sii sempre positivo e incoraggiante

## Tono a seconda dello stato (${conversationState})
- **idle**: "Ciao ${customerName}! Cerchi prodotti per animali, cibo, biologico, o fashion? Dimmi pure!"
- **ordering**: "Fantastico! Vediamo cosa abbiamo disponibile da ${customerName}..."
- **confirming**: "Perfetto! Ricapitolando l'ordine... tutto ok?"
- **tracking**: "Il tuo ordine è in arrivo in 30-45 minuti! Hai domande?"
- **support**: "Mi dispiace del problema. Contatta il nostro supporto per aiutarti meglio!"`;
}
