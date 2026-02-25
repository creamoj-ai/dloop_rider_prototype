// WEBHOOK MINIMALE E ROBUSTO — Solo ricezione e salvataggio
// Niente NLU, niente routing, niente complessità
// Se questo non funziona, il problema è Meta o Supabase, non il codice

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const VERIFY_TOKEN = Deno.env.get("WHATSAPP_VERIFY_TOKEN") ?? "dloop_wa_verify_2026";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

serve(async (req: Request) => {
  // GET: Webhook verification
  if (req.method === "GET") {
    const url = new URL(req.url);
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    if (mode === "subscribe" && token === VERIFY_TOKEN) {
      console.log("✅ Webhook verified by Meta");
      return new Response(challenge, { status: 200 });
    }
    return new Response("Forbidden", { status: 403 });
  }

  // POST: Process messages
  if (req.method === "POST") {
    console.log("📨 Received POST request");

    try {
      const bodyText = await req.text();
      console.log("📦 Raw body:", bodyText.substring(0, 200));

      let body: any;
      try {
        body = JSON.parse(bodyText);
      } catch (e) {
        console.error("❌ JSON parse error:", e.message);
        return new Response(
          JSON.stringify({ error: "Invalid JSON", detail: e.message }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      console.log("✅ JSON parsed successfully");

      // Create Supabase client
      const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

      // Extract messages from Meta payload
      const entries = body.entry ?? [];
      let messageCount = 0;

      for (const entry of entries) {
        const changes = entry.changes ?? [];
        for (const change of changes) {
          if (change.field !== "messages") continue;

          const value = change.value;
          const messages = value?.messages ?? [];
          const contacts = value?.contacts ?? [];

          console.log(`📬 Processing ${messages.length} messages`);

          for (let i = 0; i < messages.length; i++) {
            const msg = messages[i];
            const contact = contacts[i] ?? contacts[0];
            const phone = msg.from;
            const contact_name = (contact?.profile as any)?.name;
            const text = (msg.text as any)?.body ?? "[no text]";

            console.log(`  📌 Message from ${phone}: "${text}"`);

            try {
              // Create conversation
              const { data: conversation, error: convError } = await db
                .from("whatsapp_conversations")
                .upsert({
                  phone: phone,
                  customer_name: contact_name,
                  conversation_type: "customer",
                  state: "idle",
                  message_count: 1,
                  last_message_at: new Date().toISOString(),
                  updated_at: new Date().toISOString(),
                }, { onConflict: "phone" })
                .select()
                .single();

              if (convError) {
                console.error(`    ❌ Conversation error:`, convError);
                continue;
              }

              const conversationId = conversation.id;
              console.log(`    ✅ Conversation created/updated: ${conversationId}`);

              // Save message
              const { error: msgError } = await db
                .from("whatsapp_messages")
                .insert({
                  conversation_id: conversationId,
                  phone: phone,
                  direction: "inbound",
                  content: text,
                  message_type: msg.type ?? "text",
                  wa_message_id: msg.id,
                  status: "sent",
                });

              if (msgError) {
                console.error(`    ❌ Message save error:`, msgError);
                continue;
              }

              console.log(`    ✅ Message saved`);
              messageCount++;

            } catch (e) {
              console.error(`    ❌ Error processing message:`, e.message);
            }
          }
        }
      }

      console.log(`✅ Processed ${messageCount} messages successfully`);

      return new Response(
        JSON.stringify({ status: "ok", messages_processed: messageCount }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );

    } catch (error) {
      console.error("❌ Fatal error:", error.message);
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }

  // OPTIONS: CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  return new Response("Method not allowed", { status: 405 });
});
