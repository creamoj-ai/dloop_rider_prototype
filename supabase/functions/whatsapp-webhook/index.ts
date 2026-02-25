// WEBHOOK ULTRA MINIMALISTA - Solo logging
// Se questo fallisce, il problema è in Deno/Supabase stesso, non nel nostro codice

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const VERIFY_TOKEN = Deno.env.get("WHATSAPP_VERIFY_TOKEN") ?? "dloop_wa_verify_2026";

serve(async (req: Request) => {
  console.log("=".repeat(50));
  console.log("📨 WEBHOOK REQUEST RECEIVED");
  console.log("Method:", req.method);
  console.log("URL:", req.url);
  console.log("=".repeat(50));

  // GET: Webhook verification
  if (req.method === "GET") {
    const url = new URL(req.url);
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");

    console.log("✅ GET request - Webhook verification");
    console.log("  Mode:", mode, "Token:", token === VERIFY_TOKEN ? "✅" : "❌");

    if (mode === "subscribe" && token === VERIFY_TOKEN) {
      return new Response(challenge, { status: 200 });
    }
    return new Response("Forbidden", { status: 403 });
  }

  // POST: Process messages
  if (req.method === "POST") {
    console.log("📬 POST request - Processing message");

    try {
      const bodyText = await req.text();
      console.log("Body length:", bodyText.length);
      console.log("Body preview:", bodyText.substring(0, 100));

      let body: any;
      try {
        body = JSON.parse(bodyText);
        console.log("✅ JSON parsed");
        console.log("Entries:", body.entry?.length ?? 0);
      } catch (e) {
        console.error("❌ JSON parse failed:", e.message);
        return new Response(JSON.stringify({ error: "Invalid JSON" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }

      // Process messages
      let processed = 0;
      const entries = body.entry ?? [];
      for (const entry of entries) {
        const changes = entry.changes ?? [];
        for (const change of changes) {
          if (change.field !== "messages") continue;
          const messages = change.value?.messages ?? [];
          processed += messages.length;
          console.log(`✅ Found ${messages.length} messages`);
        }
      }

      console.log(`✅ Successfully processed ${processed} messages`);

      return new Response(JSON.stringify({ status: "ok", processed }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });

    } catch (error) {
      console.error("❌ Unhandled error:", error);
      console.error("Stack:", error.stack);
      return new Response(JSON.stringify({ error: String(error) }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      },
    });
  }

  return new Response("Method not allowed", { status: 405 });
});
