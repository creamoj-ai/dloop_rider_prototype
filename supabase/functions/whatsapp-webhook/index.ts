// WhatsApp Webhook — Clean implementation based on working simulate endpoint
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { normalizePhone } from "../_shared/phone_utils.ts";
import { processInboundMessage } from "./processor.ts";
import { processDealerMessage } from "./dealer_processor.ts";

const VERIFY_TOKEN = "dloop_wa_verify_2026";

serve(async (req: Request) => {
  // GET: Meta webhook verification
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

  // OPTIONS: CORS
  if (req.method === "OPTIONS") {
    return new Response("OK", { headers: corsHeaders });
  }

  // POST: Process WhatsApp messages from Twilio or Meta
  if (req.method === "POST") {
    try {
      const body = await req.json();

      // Detect webhook source (Twilio or Meta)
      let phone = "";
      let content = "";
      let contactName = "";

      if (body.From) {
        // Twilio webhook format
        console.log("📨 Webhook received from Twilio");
        phone = normalizePhone(body.From.replace("whatsapp:", ""));
        content = body.Body || "";
        // Twilio doesn't provide contact name in webhook
        contactName = "";
      } else if (body.entry?.[0]?.changes?.[0]?.value?.messages?.[0]) {
        // Meta webhook format
        console.log("📨 Webhook received from Meta");
        const value = body.entry[0].changes[0].value;
        const message = value.messages[0];
        const contact = value.contacts?.[0];
        phone = normalizePhone(message.from);

        if (message.type === "text") {
          content = message.text.body;
        } else if (message.type === "audio") {
          content = `[Audio: ${message.audio.id}]`;
        } else {
          content = `[${message.type} message]`;
        }
        contactName = contact?.profile?.name || "";
      } else {
        console.log("⚠️ No messages in webhook");
        return new Response("OK", { status: 200 });
      }

      // Return 200 immediately (async processing)
      const response = new Response("OK", { status: 200 });

      // Process asynchronously
      (async () => {
        try {

          console.log(`📨 Message from ${phone}: "${content.substring(0, 50)}"`);

          // Get database client
          const db = getServiceClient();

          // Check if sender is a dealer
          const { data: dealerContacts } = await db
            .from("rider_contacts")
            .select("id, rider_id, name, phone")
            .eq("contact_type", "dealer");

          const matchedDealer = (dealerContacts ?? []).find(
            (d: any) => normalizePhone(d.phone) === phone
          );

          // Route to dealer or customer
          if (matchedDealer) {
            console.log(`🏬 Dealer message from ${matchedDealer.name}`);
            await processDealerMessage(db,
              { phone, text: content, name: contactName },
              {
                id: matchedDealer.id,
                rider_id: matchedDealer.rider_id,
                name: matchedDealer.name,
              }
            );
          } else {
            console.log(`👤 Customer message`);
            await processInboundMessage(db, {
              phone,
              text: content,
              name: contactName,
            });
          }

          console.log("✅ Message processed and response sent");
        } catch (error) {
          console.error("❌ Processing error:", error instanceof Error ? error.message : String(error));
          console.error("Stack:", error instanceof Error ? error.stack : "N/A");
        }
      })();

      return response;
    } catch (error) {
      console.error("❌ Webhook parse error:", error);
      return new Response("OK", { status: 200 }); // Return 200 anyway
    }
  }

  return new Response("Not found", { status: 404 });
});
