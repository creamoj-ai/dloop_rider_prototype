/**
 * Message Processor (Haiku)
 * Processes inbound messages and generates responses using ChatGPT
 *
 * This is the core NLU pipeline for customer and dealer messages
 */

import { getServiceClient } from "../_shared/supabase.ts";

interface InboundMessage {
  phone: string;
  text: string;
  name?: string;
}

interface ProcessedMessage {
  reply: string;
  conversationId: string;
  intent?: string;
  confidence?: number;
}

/**
 * Process customer message through NLU pipeline
 */
export async function processCustomerMessage(
  db: any,
  inbound: InboundMessage
): Promise<ProcessedMessage> {
  const { phone, text, name } = inbound;

  console.log(`[CUSTOMER] Processing message from ${phone}: "${text.substring(0, 50)}"`);

  // ============================================================
  // 1. Find or create conversation
  // ============================================================
  let { data: conversation } = await db
    .from("whatsapp_conversations")
    .select("id, context")
    .eq("phone", phone)
    .single();

  if (!conversation) {
    const { data: newConv } = await db
      .from("whatsapp_conversations")
      .insert({
        phone,
        conversation_type: "customer",
        message_count: 1,
      })
      .select()
      .single();

    conversation = newConv;
  }

  const conversationId = conversation.id;
  const context = conversation.context || {};

  // ============================================================
  // 2. Classify intent using ChatGPT
  // ============================================================
  const systemPrompt = `
Tu sei un assistente di servizio clienti amichevole per Dloop.

RESPONSABILITÀ:
1. Classifica la richiesta come: ordine, prodotto, supporto, o chat
2. Se è un ordine: estrai i prodotti richiesti
3. Se è una domanda su prodotti: suggerisci alternanze
4. Se è un supporto: offri di contattare il team
5. Se è chat: rispondi cordialmente

LINGUA: Rispondi SEMPRE in italiano

STILE: Amichevole, breve (max 150 caratteri), professionale

Se non capisci: chiedi chiarimenti.
  `.trim();

  const openaiResponse = await callOpenAI(systemPrompt, text);

  if (!openaiResponse.ok) {
    console.error("❌ OpenAI error:", openaiResponse.error);
    return {
      reply: "Mi scusi, non ho potuto elaborare la richiesta. Il supporto verrà contattato.",
      conversationId,
      intent: "error",
    };
  }

  const reply = openaiResponse.text;

  // ============================================================
  // 3. Store messages in database
  // ============================================================
  // Store inbound
  await db.from("whatsapp_messages").insert({
    conversation_id: conversationId,
    phone,
    direction: "inbound",
    content: text,
    type: "text",
    status: "pending",
  });

  // Store outbound response
  await db.from("whatsapp_messages").insert({
    conversation_id: conversationId,
    phone,
    direction: "outbound",
    content: reply,
    type: "text",
    status: "sent",
  });

  // ============================================================
  // 4. Update conversation context
  // ============================================================
  await db
    .from("whatsapp_conversations")
    .update({
      context: {
        ...context,
        last_intent: openaiResponse.intent,
        last_message: text.substring(0, 100),
        updated_at: new Date().toISOString(),
      },
      message_count: (conversation.message_count || 0) + 2,
      last_message_at: new Date(),
    })
    .eq("id", conversationId);

  console.log(`✅ [CUSTOMER] Response generated: "${reply.substring(0, 50)}..."`);

  return {
    reply,
    conversationId,
    intent: openaiResponse.intent,
    confidence: openaiResponse.confidence,
  };
}

/**
 * Process dealer message through NLU pipeline
 */
export async function processDealerMessage(
  db: any,
  inbound: InboundMessage,
  dealer: { id: string; rider_id: string; name: string }
): Promise<ProcessedMessage> {
  const { phone, text, name } = inbound;

  console.log(`[DEALER] Processing message from ${dealer.name} (${phone}): "${text.substring(0, 50)}"`);

  // Similar flow but with dealer-specific logic
  let { data: conversation } = await db
    .from("whatsapp_conversations")
    .select("id, context")
    .eq("phone", phone)
    .single();

  if (!conversation) {
    const { data: newConv } = await db
      .from("whatsapp_conversations")
      .insert({
        phone,
        conversation_type: "dealer",
        message_count: 1,
      })
      .select()
      .single();

    conversation = newConv;
  }

  const conversationId = conversation.id;

  // Dealer-specific system prompt
  const systemPrompt = `
Tu sei un assistente supporto per dealer Dloop.

RESPONSABILITÀ:
1. Rispondi a domande su ordini, stock, e pagamenti
2. Fornisci informazioni sul supporto
3. Escalate a team se necessario

LINGUA: Italiano

STILE: Professionale, informativo
  `.trim();

  const openaiResponse = await callOpenAI(systemPrompt, text);

  if (!openaiResponse.ok) {
    return {
      reply: "Errore di elaborazione. Contattando il supporto...",
      conversationId,
      intent: "error",
    };
  }

  const reply = openaiResponse.text;

  // Store messages
  await db.from("whatsapp_messages").insertMultiple([
    {
      conversation_id: conversationId,
      phone,
      direction: "inbound",
      content: text,
      type: "text",
      status: "pending",
    },
    {
      conversation_id: conversationId,
      phone,
      direction: "outbound",
      content: reply,
      type: "text",
      status: "sent",
    },
  ]);

  return {
    reply,
    conversationId,
    intent: openaiResponse.intent,
  };
}

/**
 * Call OpenAI ChatGPT API
 */
async function callOpenAI(
  systemPrompt: string,
  userMessage: string
): Promise<{
  ok: boolean;
  text?: string;
  intent?: string;
  confidence?: number;
  error?: string;
}> {
  const apiKey = Deno.env.get("OPENAI_API_KEY");

  if (!apiKey) {
    console.error("❌ Missing OPENAI_API_KEY");
    return { ok: false, error: "OpenAI key not configured" };
  }

  try {
    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage },
        ],
        temperature: 0.7,
        max_tokens: 150,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error("❌ OpenAI error:", response.status, error);
      return { ok: false, error: `OpenAI ${response.status}` };
    }

    const data = await response.json();
    const text = data.choices[0].message.content.trim();

    return {
      ok: true,
      text,
      intent: "chat",
      confidence: 0.85,
    };
  } catch (error) {
    console.error("❌ OpenAI call error:", error);
    return { ok: false, error: error.message };
  }
}

/**
 * Intent classification (could be improved with NLU)
 */
export function classifyIntent(
  text: string
): "order" | "product" | "support" | "chat" {
  const lower = text.toLowerCase();

  if (/ordina|voglio|compra|acquista|vorrei/.test(lower)) {
    return "order";
  }

  if (/prezzo|disponibile|avete|quali|prodotto|marca/.test(lower)) {
    return "product";
  }

  if (/aiuto|problema|errore|reclamo|supporto/.test(lower)) {
    return "support";
  }

  return "chat";
}
