// Edge Function: relay-dealer — Send WhatsApp notification to dealer
// Notifies a dealer about a new order relay and updates relay status.
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/relay-dealer \
//     -H "Content-Type: application/json" \
//     -H "X-Admin-Key: <WOZ_ADMIN_KEY>" \
//     -d '{"relay_id":"<uuid>","dealer_phone":"+393331234567","dealer_name":"Mario","order_details":"1x Margherita"}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { sendWhatsAppMessage } from "../whatsapp-webhook/whatsapp_api.ts";

const WOZ_ADMIN_KEY = Deno.env.get("WOZ_ADMIN_KEY") ?? "";

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // Authenticate via admin key
    const adminKey = req.headers.get("X-Admin-Key");
    if (!WOZ_ADMIN_KEY || adminKey !== WOZ_ADMIN_KEY) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { relay_id, dealer_phone, dealer_name, order_details } = body;

    if (!relay_id || !dealer_phone || !dealer_name) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields",
          required: ["relay_id", "dealer_phone", "dealer_name"],
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Compose WhatsApp message
    const details = order_details || "nuovo ordine";
    const message =
      `Ciao ${dealer_name}! Nuovo ordine DLOOP:\n` +
      `${details}\n\n` +
      `Rispondi OK per confermare la preparazione.`;

    // Send WhatsApp message
    const waResult = await sendWhatsAppMessage(dealer_phone, message);

    if (!waResult.success) {
      console.error("WhatsApp send failed:", waResult.error);
      return new Response(
        JSON.stringify({
          error: "WhatsApp send failed",
          details: waResult.error,
          relay_id,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update relay status to 'sent'
    const db = getServiceClient();
    const { error: updateError } = await db
      .from("order_relays")
      .update({
        status: "sent",
        relayed_at: new Date().toISOString(),
      })
      .eq("id", relay_id);

    if (updateError) {
      console.error("Relay update error:", updateError);
    }

    return new Response(
      JSON.stringify({
        success: true,
        relay_id,
        wa_message_id: waResult.messageId,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("relay-dealer error:", error);
    return new Response(
      JSON.stringify({
        error: "Processing failed",
        details: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
