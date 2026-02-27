// WhatsApp Webhook — Twilio Integration (simplified)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { normalizePhone } from "../_shared/phone_utils.ts";
import { processInboundMessage } from "./processor.ts";
import { processDealerMessage } from "./dealer_processor.ts";

serve(async (req: Request) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("OK", { headers: corsHeaders });
  }

  // POST: Process WhatsApp messages (Twilio or Meta)
  if (req.method === "POST") {
    try {
      const body = await req.json();
      console.log("📨 Webhook received:", JSON.stringify(body).substring(0, 100));

      let phone = "";
      let content = "";
      let contactName = "";

      // Twilio webhook format
      if (body.From) {
        console.log("📨 Source: Twilio");
        phone = normalizePhone(body.From.replace("whatsapp:", ""));
        content = body.Body || "";
        contactName = "";
      }
      // Meta webhook format
      else if (body.entry?.[0]?.changes?.[0]?.value?.messages?.[0]) {
        console.log("📨 Source: Meta");
        const message = body.entry[0].changes[0].value.messages[0];
        const contact = body.entry[0].changes[0].value.contacts?.[0];
        phone = normalizePhone(message.from);

        if (message.type === "text") {
          content = message.text.body;
        } else {
          content = `[${message.type}]`;
        }
        contactName = contact?.profile?.name || "";
      }
      else {
        console.log("⚠️ No messages found");
        return new Response("OK", { status: 200 });
      }

      console.log(`📨 Message from ${phone}: "${content.substring(0, 50)}"`);

      // Return 200 immediately
      const response = new Response("OK", { status: 200 });

      // Process async
      (async () => {
        try {
          const db = getServiceClient();

          // Check if dealer
          const { data: dealerContacts } = await db
            .from("rider_contacts")
            .select("id, rider_id, name, phone")
            .eq("contact_type", "dealer");

          const dealer = (dealerContacts ?? []).find(
            (d: any) => normalizePhone(d.phone) === phone
          );

          if (dealer) {
            console.log(`🏬 Dealer: ${dealer.name}`);
            await processDealerMessage(db,
              { phone, text: content, name: contactName },
              { id: dealer.id, rider_id: dealer.rider_id, name: dealer.name }
            );
          } else {
            console.log(`👤 Customer`);
            await processInboundMessage(db, {
              phone,
              text: content,
              name: contactName,
            });
          }

          console.log("✅ Done");
        } catch (error) {
          console.error("❌ Error:", error instanceof Error ? error.message : String(error));
        }
      })();

      return response;
    } catch (error) {
      console.error("❌ Parse error:", error);
      return new Response("OK", { status: 200 });
    }
  }

  return new Response("Not found", { status: 404 });
});
