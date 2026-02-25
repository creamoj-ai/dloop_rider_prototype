import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req: Request) => {
  // GET: Webhook verification
  if (req.method === "GET") {
    const url = new URL(req.url);
    const challenge = url.searchParams.get("hub.challenge");
    return new Response(challenge || "", { status: 200 });
  }

  // POST: Accept all messages
  if (req.method === "POST") {
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" }
    });
  }

  // OPTIONS: CORS
  if (req.method === "OPTIONS") {
    return new Response("OK", { status: 200 });
  }

  return new Response("Method not allowed", { status: 405 });
});
