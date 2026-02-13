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
    direction: "inbound",
    content: messageContent,
    message_type: messageType,
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
      const args = JSON.parse(toolCall.function.arguments || "{}");
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
  // Try to find existing conversation
  const { data: existing } = await db
    .from("whatsapp_conversations")
    .select("*")
    .eq("phone", phone)
    .single();

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

  // Create new conversation
  const { data: created, error } = await db
    .from("whatsapp_conversations")
    .insert({
      phone,
      customer_name: name ?? null,
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
  return `Sei l'assistente WhatsApp di dloop, il servizio di delivery locale.
Parli in italiano, in modo cordiale e professionale.
Rispondi in massimo 2-3 frasi brevi, adatte a WhatsApp.

## Cliente
- Nome: ${customerName}
- Stato conversazione: ${conversationState}

## Cosa puoi fare
- Cercare prodotti nel catalogo (profumi, abbigliamento, gioielli, cosmetici)
- Creare ordini (chiedi sempre: prodotto, quantità, indirizzo di consegna)
- Controllare lo stato di un ordine esistente
- Annullare ordini (solo se ancora in attesa)
- Rispondere a domande generali sul servizio dloop

## Come funziona dloop
- Delivery locale veloce (30-60 min) per prodotti di negozi partner
- Negozi partner: Yamamay, Jolie profumerie, gioiellerie, fashion boutique
- Pagamento alla consegna (contanti o POS del rider)
- Consegna gratuita sopra €50, altrimenti €3.50

## Flow ordine tipico
1. Cliente chiede un prodotto → usa search_products
2. Mostra risultati con prezzo → chiedi conferma e indirizzo
3. Cliente conferma → usa create_order (imposta stato a "confirming" poi "tracking")
4. Ordine creato → comunica ID e tempo stimato

## Regole
- Usa SEMPRE le funzioni per azioni reali (ricerca, ordini). Non inventare prodotti o prezzi.
- Se il cliente chiede qualcosa che non puoi gestire, suggerisci di chiamare il supporto.
- Non rivelare dettagli tecnici interni.
- Gestisci la state machine: usa set_conversation_state per transizioni.
- Se il messaggio è un vocale trascritto, rispondi normalmente al contenuto.`;
}
