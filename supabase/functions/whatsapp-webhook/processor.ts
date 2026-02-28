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

## Come aiutare il cliente (PER TE, NON PER IL CLIENTE)
1. **Se il cliente ha una domanda generica** → Usa get_faq per rispondere (non dire che lo stai facendo)
2. **Se cerca prodotti** → Usa search_products e mostra le opzioni con prezzi
3. **Se vuole ordinare** → Chiedi l'indirizzo e il nome del negozio, poi usa create_delivery_order
4. **Se chiede lo stato dell'ordine** → Usa check_order_status
5. **Se vuole pagare online** → Usa get_payment_link
6. **Se sa già cosa vuole** → Suggerisci subito di creare l'ordine

## Stile di conversazione
- ✅ "Ciao! Che tipo di cibo/prodotto cerchi?"
- ✅ "Perfetto! Allora te lo portiamo a casa in 30-45 minuti"
- ✅ "Qual è il tuo indirizzo per la consegna?"
- ❌ NON dire: "Sto usando la funzione search_products"
- ❌ NON menzionare funzioni tecniche ai clienti
- ❌ NON inventare prezzi o prodotti

## Flow naturale di un ordine
1. Cliente dice cosa vuole → Tu rispondi amichevolmente e mostra opzioni
2. Cliente sceglie → Tu confermi (prezzo, quantità, indirizzo)
3. Tu crei l'ordine e comunichi il codice + tempo stimato (30-45 min)
4. Tu offri il link di pagamento se online, oppure contanti/POS
5. Dopo la consegna → Chiedi un giudizio (1-5 stelle)

## Regole importanti
- Chiedi SEMPRE l'indirizzo completo prima di creare un ordine
- Se il cliente dà una posizione GPS, usa quella
- Non creare ordini incompleti (manca indirizzo o negozio)
- Sii sempre positivo e incoraggiante
- Se una domanda è fuori dalla tua competenza, suggerisci il supporto

## Tono a seconda dello stato (${conversationState})
- **idle**: "Ciao! Che tipo di cibo/prodotto cerchi oggi?"
- **ordering**: "Perfetto! Mostrami cosa ti interessa"
- **confirming**: "Riepiloghiamo l'ordine... è tutto corretto?"
- **tracking**: "Il tuo ordine è in arrivo! Hai domande?"
- **support**: "Mi dispiace del problema. Come posso aiutarti?"`;
}
