// Edge Function: whatsapp-simulate — Test endpoint for WhatsApp NLU pipeline
// Simulates a WhatsApp message without requiring Meta Business verification.
// Supports both customer and dealer pipelines via the 'role' parameter.
//
// Usage (customer):
//   curl -X POST https://<project>.supabase.co/functions/v1/whatsapp-simulate \
//     -H "Content-Type: application/json" \
//     -d '{"phone":"+393331234567","text":"Vorrei ordinare un profumo","name":"Mario Rossi"}'
//
// Usage (dealer):
//   curl -X POST https://<project>.supabase.co/functions/v1/whatsapp-simulate \
//     -H "Content-Type: application/json" \
//     -d '{"phone":"+393331111111","text":"OK","name":"Marco Bianchi","role":"dealer"}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { normalizePhone } from "../_shared/phone_utils.ts";
import { processInboundMessage } from "../whatsapp-webhook/processor.ts";
import { processDealerMessage } from "../whatsapp-webhook/dealer_processor.ts";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = await req.json();
    const { phone, text, name, audioMediaId, role } = body;

    if (!phone) {
      return new Response(
        JSON.stringify({ error: "Missing 'phone' field" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!text && !audioMediaId) {
      return new Response(
        JSON.stringify({ error: "Missing 'text' or 'audioMediaId' field" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const db = getServiceClient();
    const inbound = { phone, text, name, audioMediaId };

    let result: { reply: string; conversationId: string };
    let routedTo: string;

    if (role === "dealer") {
      // Force dealer pipeline — find or create a matching dealer contact
      const normalized = normalizePhone(phone);
      const { data: dealerContacts } = await db
        .from("rider_contacts")
        .select("id, rider_id, name, phone")
        .eq("contact_type", "dealer");

      const matchedDealer = (dealerContacts ?? []).find(
        (d: Record<string, unknown>) =>
          normalizePhone(d.phone as string) === normalized
      );

      if (matchedDealer) {
        result = await processDealerMessage(db, inbound, {
          id: matchedDealer.id as string,
          rider_id: matchedDealer.rider_id as string,
          name: matchedDealer.name as string,
        });
        routedTo = `dealer (${matchedDealer.name})`;
      } else {
        return new Response(
          JSON.stringify({
            error: "No dealer found with this phone number in rider_contacts. Add the dealer first or use a matching phone.",
            phone: normalized,
          }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } else {
      // Auto-route: check if phone is a dealer, otherwise customer
      const normalized = normalizePhone(phone);
      const { data: dealerContacts } = await db
        .from("rider_contacts")
        .select("id, rider_id, name, phone")
        .eq("contact_type", "dealer");

      const matchedDealer = (dealerContacts ?? []).find(
        (d: Record<string, unknown>) =>
          normalizePhone(d.phone as string) === normalized
      );

      if (matchedDealer && role !== "customer") {
        result = await processDealerMessage(db, inbound, {
          id: matchedDealer.id as string,
          rider_id: matchedDealer.rider_id as string,
          name: matchedDealer.name as string,
        });
        routedTo = `dealer (${matchedDealer.name})`;
      } else {
        result = await processInboundMessage(db, inbound);
        routedTo = "customer";
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        reply: result.reply,
        conversation_id: result.conversationId,
        routed_to: routedTo,
        note: "Simulated — WhatsApp API send may have failed (no credentials). Check DB for messages.",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Simulate error:", error);
    return new Response(
      JSON.stringify({
        error: "Processing failed",
        details: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
