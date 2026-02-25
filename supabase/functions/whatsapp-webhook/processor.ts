// NLU Pipeline — Core message processor for WhatsApp bot
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { chatCompletion, transcribeAudio, type ChatMessage } from "../_shared/openai.ts";
import { customerTools, executeCustomerFunction } from "./customer_functions.ts";
import { sendWhatsAppMessage, downloadMedia } from "./whatsapp_api.ts";

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
Parli in italiano, in modo cordiale, rapido e professionale.
Rispondi in massimo 2-3 frasi brevi, adatte a WhatsApp.

## Cliente
- Nome: ${customerName}
- Stato conversazione: ${conversationState}

## Cosa puoi fare
- Cercare prodotti nel catalogo (search_products) o menu di un negozio (browse_dealer_menu)
- Creare ordini prodotto singolo (create_order) o ordini delivery completi (create_delivery_order)
- Controllare lo stato di un ordine (check_order_status)
- Annullare ordini solo se in attesa (cancel_order)
- Generare link di pagamento Stripe (get_payment_link)
- Raccogliere feedback post-consegna (submit_feedback)
- Rispondere a FAQ su tempi, costi, zone, pagamento (get_faq)

## Come funziona dloop
- Delivery locale veloce (30-60 min) per prodotti di negozi partner
- Negozi partner: ristoranti, pizzerie, fashion boutique, profumerie, gioiellerie
- Il rider personale (DLOOPER) ritira dal negozio e consegna a te
- Pagamento: link Stripe (carta online), contanti, o POS del rider
- Consegna: da €3.50 (gratuita sopra €50)
- Zone: Napoli e provincia

## Flow ordine tipico
1. Cliente chiede un prodotto o tipo di cibo → usa browse_dealer_menu o search_products
2. Mostra opzioni con prezzo → chiedi conferma e indirizzo di consegna
3. Cliente conferma → usa create_delivery_order (con nome negozio, articoli, indirizzo)
4. Ordine creato → comunica ID e tempo stimato (~30-45 min)
5. Se il cliente vuole pagare online → usa get_payment_link
6. Dopo la consegna → chiedi feedback con submit_feedback (voto 1-5)

## Regole
- USA SEMPRE le funzioni per azioni reali. Non inventare prodotti, prezzi o stati.
- Chiedi SEMPRE l'indirizzo completo prima di creare un ordine.
- Se il cliente manda la posizione GPS, usala come indirizzo di consegna.
- Per domande generali (tempi, costi, zone, pagamento), usa get_faq.
- Se il cliente chiede qualcosa fuori scope, suggerisci di chiamare il supporto.
- Non rivelare dettagli tecnici interni.
- Se il messaggio è un vocale trascritto, rispondi normalmente al contenuto.

## State machine (stato: ${conversationState})
Le transizioni avvengono automaticamente. Rispetta lo stato corrente:
- **idle**: Il cliente non ha ordini in corso. Aiutalo a cercare prodotti o negozi.
- **ordering**: Il cliente sta scegliendo cosa ordinare. Chiedi articoli, negozio e indirizzo prima di confermare.
- **confirming**: Il cliente ha scelto, sta confermando. Riepilogalo e crea l'ordine con create_delivery_order.
- **tracking**: Un ordine è in corso. Rispondi su stato, pagamento, tempi. Chiedi feedback solo dopo la consegna.
- **support**: Il cliente ha bisogno di aiuto. Rispondi e poi torna a idle.

Regole di stato:
- NON creare ordini (create_delivery_order) senza: 1) nome dealer, 2) articoli, 3) indirizzo completo.
- Se manca qualcosa, chiedi al cliente prima di procedere.
- Dopo aver creato un ordine, proponi il link di pagamento.
- Dopo la consegna, chiedi una valutazione (submit_feedback 1-5 stelle).`;
}
