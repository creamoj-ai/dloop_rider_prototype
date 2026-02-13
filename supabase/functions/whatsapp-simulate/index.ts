// Edge Function: whatsapp-simulate — Test endpoint for WhatsApp NLU pipeline
// Simulates a WhatsApp message without requiring Meta Business verification.
//
// Usage:
//   curl -X POST https://<project>.supabase.co/functions/v1/whatsapp-simulate \
//     -H "Content-Type: application/json" \
//     -d '{"phone":"+393331234567","text":"Vorrei ordinare un profumo","name":"Mario Rossi"}'
//
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";
import { processInboundMessage } from "../whatsapp-webhook/processor.ts";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = await req.json();
    const { phone, text, name, audioMediaId } = body;

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

    // Process through the same pipeline as real WhatsApp messages,
    // but the WhatsApp API send will fail silently (no real WA credentials in test)
    const result = await processInboundMessage(db, {
      phone,
      text,
      name,
      audioMediaId,
    });

    return new Response(
      JSON.stringify({
        success: true,
        reply: result.reply,
        conversation_id: result.conversationId,
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
