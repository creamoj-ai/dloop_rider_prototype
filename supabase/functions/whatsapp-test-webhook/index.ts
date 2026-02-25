// WEBHOOK TEST — Simula i messaggi Meta per testare il webhook localmente
// Senza aspettare Meta, senza dipendenze, pura funzionalità
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient, corsHeaders } from "../_shared/supabase.ts";

serve(async (req: Request) => {
  // Test endpoint — simula un messaggio da Meta
  if (req.method === "POST") {
    try {
      const db = getServiceClient();

      // Simula il payload di Meta
      const testPayload = {
        entry: [{
          id: "test-entry",
          changes: [{
            field: "messages",
            value: {
              messaging_product: "whatsapp",
              metadata: {
                display_phone_number: "39328185464",
                phone_number_id: "979991158533832"
              },
              contacts: [{
                wa_id: "393331234567",
                profile: { name: "Test User" }
              }],
              messages: [{
                from: "393331234567",
                id: "wamid.test123",
                timestamp: Date.now().toString(),
                type: "text",
                text: { body: "Ciao test" }
              }]
            }
          }]
        }]
      };

      console.log("🧪 TEST WEBHOOK: Simulating Meta message...");
      console.log("Payload:", JSON.stringify(testPayload, null, 2));

      // Chiama il webhook vero con il payload simulato
      const webhookUrl = new URL(req.url);
      webhookUrl.pathname = "/functions/v1/whatsapp-webhook";

      const webhookReq = new Request(webhookUrl.toString(), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(testPayload)
      });

      const webhookRes = await fetch(webhookReq);
      const webhookBody = await webhookRes.text();

      return new Response(JSON.stringify({
        test_success: true,
        webhook_status: webhookRes.status,
        webhook_response: webhookBody,
        message: "✅ Test message sent to webhook. Check database for results."
      }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });

    } catch (error) {
      console.error("Test webhook error:", error);
      return new Response(JSON.stringify({
        error: error.message,
        stack: error.stack
      }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      });
    }
  }

  return new Response("Test webhook ready. POST to test.", { status: 200 });
});
