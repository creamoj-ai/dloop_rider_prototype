// NLU Pipeline — Dealer message processor for WhatsApp bot
// Architecture: keyword-first (instant, no AI cost) + GPT fallback for complex queries
import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { chatCompletion, transcribeAudio, type ChatMessage } from "../_shared/openai.ts";
import { dealerTools, executeDealerFunction } from "./dealer_functions.ts";
import { sendWhatsAppMessage, downloadMedia } from "./whatsapp_api.ts";

const MAX_FUNCTION_CALLS = 3;
const MESSAGE_HISTORY_LIMIT = 10;

interface InboundMessage {
  phone: string;
  text?: string;
  name?: string;
  audioMediaId?: string;
  imageMediaId?: string;
  imageCaption?: string;
  latitude?: number;
  longitude?: number;
}

interface DealerContact {
  id: string;
  rider_id: string;
  name: string;
}

/**
 * Process a message from a dealer through keyword detection + NLU fallback.
 */
export async function processDealerMessage(
  db: SupabaseClient,
  message: InboundMessage,
  dealer: DealerContact
): Promise<{ reply: string; conversationId: string }> {
  const { phone, name } = message;

  // 1. Get or create dealer conversation
  const conversation = await getOrCreateDealerConversation(
    db,
    phone,
    dealer.id,
    name ?? dealer.name
  );
  const conversationId = conversation.id as string;

  // 2. Resolve message content
  let messageContent = message.text ?? "";
  let messageType = "text";

  if (message.audioMediaId) {
    messageType = "voice";
    try {
      const audioData = await downloadMedia(message.audioMediaId);
      messageContent = await transcribeAudio(audioData);
    } catch (e) {
      messageContent = "[Messaggio vocale non riconosciuto]";
      console.error("Dealer voice transcription failed:", e);
    }
  } else if (message.imageMediaId) {
    messageType = "image";
    messageContent = message.imageCaption ?? "[Immagine ricevuta]";
  } else if (message.latitude !== undefined) {
    messageType = "location";
    messageContent = `[Posizione: ${message.latitude}, ${message.longitude}]`;
  }

  // 3. Save inbound message
  await db.from("whatsapp_messages").insert({
    conversation_id: conversationId,
    phone: phone,
    direction: "inbound",
    content: messageContent,
    message_type: messageType,
    wa_message_id: (message as any).id ?? null,
    status: "sent",
  });

  await db
    .from("whatsapp_conversations")
    .update({ last_message_at: new Date().toISOString() })
    .eq("id", conversationId);

  // 4. Try keyword command first (instant, no AI cost)
  const keywordResult = await tryKeywordCommand(
    messageContent,
    db,
    conversationId,
    dealer.id,
    dealer.rider_id
  );

  let reply: string;

  if (keywordResult !== null) {
    // Keyword matched — use direct result
    reply = keywordResult;
  } else {
    // 5. NLU fallback — use GPT-4o-mini
    reply = await processWithNLU(
      db,
      conversationId,
      dealer,
      messageContent
    );
  }

  // 6. Send WhatsApp reply
  const sendResult = await sendWhatsAppMessage(phone, reply);

  // 7. Save outbound message
  await db.from("whatsapp_messages").insert({
    conversation_id: conversationId,
    phone: phone,
    direction: "outbound",
    content: reply,
    message_type: "text",
    wa_message_id: sendResult.messageId ?? null,
    status: sendResult.success ? "sent" : "failed",
    tokens_used: 0, // Keywords don't use tokens
  });

  return { reply, conversationId };
}

// ── Keyword Command Processor ─────────────────────────────────────

/**
 * Try to match a keyword command. Returns reply text if matched, null if not.
 * Keyword commands bypass AI entirely — instant and free.
 */
async function tryKeywordCommand(
  text: string,
  db: SupabaseClient,
  conversationId: string,
  dealerContactId: string,
  riderId: string
): Promise<string | null> {
  const cmd = text.trim().toUpperCase();

  // ── Confirm order
  if (["OK", "CONFERMA", "SI", "SÌ", "VA BENE", "CONFERMO"].includes(cmd)) {
    const result = await executeDealerFunction(
      "confirm_order",
      {},
      db,
      conversationId,
      dealerContactId,
      riderId
    );
    const parsed = JSON.parse(result);
    return parsed.message ?? parsed.error ?? result;
  }

  // ── Mark order ready
  if (["PRONTO", "READY", "FATTO", "PREPARATO"].includes(cmd)) {
    const result = await executeDealerFunction(
      "mark_order_ready",
      {},
      db,
      conversationId,
      dealerContactId,
      riderId
    );
    const parsed = JSON.parse(result);
    return parsed.message ?? parsed.error ?? result;
  }

  // ── Decline order
  if (["NO", "RIFIUTA", "RIFIUTO", "NON POSSO", "ANNULLA"].includes(cmd)) {
    const result = await executeDealerFunction(
      "decline_order",
      {},
      db,
      conversationId,
      dealerContactId,
      riderId
    );
    const parsed = JSON.parse(result);
    return parsed.message ?? parsed.error ?? result;
  }

  // ── View pending orders
  if (["ORDINI", "LISTA", "ATTIVI", "STATO"].includes(cmd)) {
    const result = await executeDealerFunction(
      "view_pending_orders",
      {},
      db,
      conversationId,
      dealerContactId,
      riderId
    );
    const parsed = JSON.parse(result);
    if (parsed.count === 0) {
      return parsed.message;
    }
    // Format orders list
    const lines = (parsed.orders as Record<string, unknown>[]).map(
      (o: Record<string, unknown>) =>
        `${o.relay_id} | ${o.status} | ${o.dettagli} | ${o.importo}`
    );
    return `Ordini attivi (${parsed.count}):\n${lines.join("\n")}`;
  }

  // ── Close / pause
  if (["CHIUSO", "PAUSA", "CHIUDI", "STOP"].includes(cmd)) {
    const result = await executeDealerFunction(
      "update_availability",
      { available: false },
      db,
      conversationId,
      dealerContactId,
      riderId
    );
    const parsed = JSON.parse(result);
    return parsed.message ?? parsed.error ?? result;
  }

  // ── Open / available
  if (["APERTO", "DISPONIBILE", "APRI", "VIA"].includes(cmd)) {
    const result = await executeDealerFunction(
      "update_availability",
      { available: true },
      db,
      conversationId,
      dealerContactId,
      riderId
    );
    const parsed = JSON.parse(result);
    return parsed.message ?? parsed.error ?? result;
  }

  // ── Help
  if (["?", "AIUTO", "HELP", "COMANDI"].includes(cmd)) {
    return (
      "Comandi DLOOP:\n" +
      "OK = Conferma ordine\n" +
      "PRONTO = Ordine pronto per ritiro\n" +
      "NO = Rifiuta ordine\n" +
      "ORDINI = Vedi ordini attivi\n" +
      "CHIUSO = Vai in pausa\n" +
      "APERTO = Torna disponibile\n" +
      "Oppure scrivi liberamente!"
    );
  }

  // No keyword match
  return null;
}

// ── NLU Fallback (GPT-4o-mini) ────────────────────────────────────

async function processWithNLU(
  db: SupabaseClient,
  conversationId: string,
  dealer: DealerContact,
  currentMessage: string
): Promise<string> {
  // Fetch message history
  const { data: historyData } = await db
    .from("whatsapp_messages")
    .select("direction, content, message_type")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: false })
    .limit(MESSAGE_HISTORY_LIMIT);

  const history: ChatMessage[] = (historyData ?? [])
    .reverse()
    .map((m: Record<string, unknown>) => ({
      role:
        m.direction === "inbound"
          ? ("user" as const)
          : ("assistant" as const),
      content: m.content as string,
    }));

  // Count pending orders for context
  const { count: pendingCount } = await db
    .from("whatsapp_order_relays")
    .select("id", { count: "exact", head: true })
    .eq("dealer_id", dealer.id)
    .in("status", ["pending", "confirmed", "preparing"]);

  // Build system prompt
  const systemPrompt = buildDealerSystemPrompt(
    dealer.name,
    pendingCount ?? 0
  );

  const messages: ChatMessage[] = [
    { role: "system", content: systemPrompt },
    ...history,
  ];

  let response = await chatCompletion({
    messages,
    tools: dealerTools,
    maxTokens: 512,
    temperature: 0.7,
  });

  // Function calling loop
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
        console.error(
          "Failed to parse dealer tool args:",
          toolCall.function.arguments
        );
      }
      const result = await executeDealerFunction(
        toolCall.function.name,
        args,
        db,
        conversationId,
        dealer.id,
        dealer.rider_id
      );

      messages.push({
        role: "tool",
        content: result,
        tool_call_id: toolCall.id,
      });
    }

    response = await chatCompletion({
      messages,
      tools: dealerTools,
    });

    iterations++;
  }

  // Update tokens in last outbound message
  const tokensUsed = response.usage?.total_tokens ?? 0;

  return (
    response.content?.trim() ??
    "Non ho capito. Scrivi AIUTO per vedere i comandi."
  );
}

// ── Helpers ───────────────────────────────────────────────────────

async function getOrCreateDealerConversation(
  db: SupabaseClient,
  phone: string,
  dealerContactId: string,
  dealerName: string
): Promise<Record<string, unknown>> {
  // Try to find existing dealer conversation
  const { data: existing } = await db
    .from("whatsapp_conversations")
    .select("*")
    .eq("phone", phone)
    .eq("conversation_type", "dealer")
    .maybeSingle();

  if (existing) return existing;

  // Create new dealer conversation
  const { data: created, error } = await db
    .from("whatsapp_conversations")
    .insert({
      phone,
      customer_name: dealerName,
      conversation_type: "dealer",
      state: "idle",
    })
    .select("*")
    .single();

  if (error || !created) {
    throw new Error(`Failed to create dealer conversation: ${error?.message}`);
  }

  return created;
}

function buildDealerSystemPrompt(
  dealerName: string,
  pendingOrderCount: number
): string {
  return `Sei l'assistente DLOOP per esercenti. Parli in italiano, breve e diretto.
Rispondi in massimo 2 frasi. Il dealer riceve ordini via rider DLOOP e conferma la preparazione.

## Dealer
- Nome: ${dealerName}
- Ordini attivi: ${pendingOrderCount}

## Comandi rapidi (il dealer può anche scrivere direttamente)
- OK / CONFERMA → Conferma l'ultimo ordine in attesa
- PRONTO → Ordine pronto per il ritiro del rider
- NO / RIFIUTA → Rifiuta l'ultimo ordine
- ORDINI → Vedi ordini attivi
- CHIUSO → Non disponibile
- APERTO → Torna disponibile

## Cosa puoi fare
- Confermare o rifiutare ordini in arrivo
- Segnare ordini come pronti per il ritiro
- Mostrare la lista ordini attivi
- Aggiornare la disponibilità (aperto/chiuso)
- Mostrare il riepilogo del giorno

## Come funziona
1. Un rider DLOOP invia un ordine
2. Rispondi OK per confermare → inizi a preparare
3. Quando è pronto, scrivi PRONTO → il rider viene a ritirare
4. Se non puoi, rispondi NO con motivo opzionale

## Regole
- USA SEMPRE le funzioni per azioni sugli ordini.
- Sii conciso: i dealer sono impegnati.
- Se il dealer chiede qualcosa fuori scope, suggerisci di contattare il rider direttamente.
- Non rivelare dettagli tecnici.`;
}
