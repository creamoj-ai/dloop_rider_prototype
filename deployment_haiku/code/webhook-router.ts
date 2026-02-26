/**
 * WhatsApp Webhook Router
 * Routes messages to appropriate processors (customer vs dealer)
 *
 * Entry point: Meta → POST /functions/v1/whatsapp-webhook
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { normalizePhone } from "../_shared/phone_utils.ts";

const VERIFY_TOKEN = "dloop_wa_verify_2026";

serve(async (req: Request) => {
  // ============================================================
  // GET: Meta webhook verification (required for setup)
  // ============================================================
  if (req.method === "GET") {
    const url = new URL(req.url);
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    // Meta sends: ?hub.mode=subscribe&hub.verify_token=XXX&hub.challenge=TOKEN
    // We respond with the challenge if token matches
    if (mode === "subscribe" && token === VERIFY_TOKEN) {
      console.log("✅ Webhook verified by Meta");
      return new Response(challenge, { status: 200 });
    }

    console.log("❌ Webhook verification failed");
    return new Response("Forbidden", { status: 403 });
  }

  // ============================================================
  // POST: Receive messages from Meta
  // ============================================================
  if (req.method === "POST") {
    try {
      const body = await req.json();
      const db = getServiceClient();

      console.log("📨 Webhook received message from Meta");
      console.log("Payload:", JSON.stringify(body, null, 2));

      // Parse Meta webhook structure
      if (!body.entry || !body.entry[0] || !body.entry[0].changes) {
        console.log("⚠️ Invalid payload structure");
        return new Response(JSON.stringify({ ok: true }), { status: 200 });
      }

      const change = body.entry[0].changes[0];
      if (change.field !== "messages" || !change.value.messages) {
        console.log("ℹ️ Not a message event, ignoring");
        return new Response(JSON.stringify({ ok: true }), { status: 200 });
      }

      const value = change.value;
      const message = value.messages[0];
      const contact = value.contacts[0];

      // ========================================================
      // Extract message details
      // ========================================================
      const phone = normalizePhone(message.from);
      const messageId = message.id;
      const timestamp = message.timestamp;
      const senderName = contact?.profile?.name || "Unknown";
      let content = "";

      // Support different message types
      if (message.type === "text") {
        content = message.text.body;
      } else if (message.type === "audio") {
        content = `[Audio message: ${message.audio.id}]`;
      } else if (message.type === "image") {
        content = `[Image: ${message.image.caption || ""}]`;
      } else {
        content = `[${message.type.toUpperCase()} message]`;
      }

      console.log(`📱 From: ${senderName} (${phone})`);
      console.log(`📝 Message: "${content.substring(0, 50)}..."`);

      // ========================================================
      // Check if phone is a dealer
      // ========================================================
      const { data: dealerContacts } = await db
        .from("rider_contacts")
        .select("id, rider_id, name")
        .eq("contact_type", "dealer")
        .eq("phone", phone);

      const isDealerMessage = dealerContacts && dealerContacts.length > 0;

      if (isDealerMessage) {
        console.log(`🏬 Routing to DEALER pipeline: ${dealerContacts[0].name}`);
        // TODO: Call dealer processor
        // await processDealerMessage(db, phone, content, senderName)
      } else {
        console.log("👤 Routing to CUSTOMER pipeline");
        // TODO: Call customer processor
        // await processCustomerMessage(db, phone, content, senderName)
      }

      // ========================================================
      // Store inbound message in database
      // ========================================================
      const inboundMessage = {
        phone,
        direction: "inbound" as const,
        content,
        type: message.type,
        meta_message_id: messageId,
        meta_response: { timestamp },
      };

      // Find or create conversation
      const { data: conversation, error: convError } = await db
        .from("whatsapp_conversations")
        .select("id")
        .eq("phone", phone)
        .single();

      let conversationId = conversation?.id;

      if (!conversationId) {
        // Create new conversation
        const { data: newConv, error: createError } = await db
          .from("whatsapp_conversations")
          .insert({
            phone,
            conversation_type: isDealerMessage ? "dealer" : "customer",
            message_count: 1,
          })
          .select()
          .single();

        if (createError) {
          throw new Error(`Failed to create conversation: ${createError.message}`);
        }

        conversationId = newConv.id;
        console.log(`✨ New conversation created: ${conversationId}`);
      }

      // Store message
      const { error: msgError } = await db
        .from("whatsapp_messages")
        .insert({
          conversation_id: conversationId,
          ...inboundMessage,
        });

      if (msgError) {
        console.error("❌ Failed to store message:", msgError);
        throw msgError;
      }

      console.log("✅ Message stored in database");

      // Always return 200 to Meta immediately
      // Processing happens asynchronously
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });

    } catch (error) {
      console.error("❌ Webhook error:", error);
      // Still return 200 to Meta to prevent retries
      return new Response(JSON.stringify({ ok: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  return new Response("Not allowed", { status: 405 });
});
