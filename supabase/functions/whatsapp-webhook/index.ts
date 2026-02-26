import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient } from "../_shared/supabase.ts";
import { normalizePhone } from "../_shared/phone_utils.ts";
import { processInboundMessage } from "./processor.ts";
import { processDealerMessage } from "./dealer_processor.ts";

const VERIFY_TOKEN = "dloop_wa_verify_2026";

serve(async (req: Request) => {
  // GET: Webhook verification
  if (req.method === "GET") {
    const url = new URL(req.url);
    const challenge = url.searchParams.get("hub.challenge");
    const token = url.searchParams.get("hub.verify_token");

    if (token === VERIFY_TOKEN) {
      return new Response(challenge, { status: 200 });
    }
    return new Response("Forbidden", { status: 403 });
  }

  // POST: Process incoming messages
  if (req.method === "POST") {
    try {
      const body = await req.json();

      // Always return 200 to Meta immediately (async processing)
      const response = new Response("OK", { status: 200 });

      // Process message asynchronously
      (async () => {
        try {
          console.log("[1] Getting service client...");
          const db = getServiceClient();

          // Parse Meta webhook structure
          if (!body.entry?.[0]?.changes?.[0]?.value?.messages) {
            console.log("[2] Invalid webhook structure");
            return;
          }

          console.log("[3] Extracting message data...");
          const value = body.entry[0].changes[0].value;
          const message = value.messages[0];
          const contact = value.contacts[0];
          const phone = normalizePhone(message.from);

          let content = "";
          if (message.type === "text") {
            content = message.text.body;
          } else if (message.type === "audio") {
            content = `[Audio: ${message.audio.id}]`;
          } else {
            content = `[${message.type} message]`;
          }

          console.log(`[4] 📨 Message from ${phone}: "${content.substring(0, 50)}"`);

          // Check if dealer
          console.log("[5] Checking if dealer message...");
          const { data: dealerContacts, error: dealerError } = await db
            .from("rider_contacts")
            .select("id, rider_id, name, phone")
            .eq("contact_type", "dealer");

          if (dealerError) {
            console.error("[5-ERROR] Failed to fetch dealer contacts:", dealerError);
            throw dealerError;
          }

          const isDealerMessage = dealerContacts?.some(
            (d: any) => normalizePhone(d.phone) === phone
          );

          // Route and process
          if (isDealerMessage) {
            const dealer = dealerContacts.find(
              (d: any) => normalizePhone(d.phone) === phone
            );
            console.log(`[6] 🏬 Routing to dealer: ${dealer.name}`);
            await processDealerMessage(db, { phone, text: content, name: contact?.profile?.name }, {
              id: dealer.id,
              rider_id: dealer.rider_id,
              name: dealer.name,
            });
          } else {
            console.log("[6] 👤 Routing to customer - calling processInboundMessage...");
            const result = await processInboundMessage(db, {
              phone,
              text: content,
              name: contact?.profile?.name,
            });
            console.log("[7] Customer processing result:", result);
          }

          console.log("[8] ✅ Message processed successfully");
        } catch (error) {
          console.error("[ERROR] ❌ Processing error:", error);
          console.error("[ERROR] Details:", error instanceof Error ? error.message : String(error));
          console.error("[ERROR] Stack:", error instanceof Error ? error.stack : "N/A");
          console.error("[ERROR] Full object:", JSON.stringify(error, null, 2));
        }
      })();

      return response;
    } catch (error) {
      console.error("Webhook error:", error);
      return new Response("OK", { status: 200 });
    }
  }

  if (req.method === "OPTIONS") {
    return new Response("OK", { status: 200 });
  }

  return new Response("Not found", { status: 404 });
});
