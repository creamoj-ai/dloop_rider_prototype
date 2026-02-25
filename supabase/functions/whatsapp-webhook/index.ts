import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req: Request) => {
  if (req.method === "GET") {
    const url = new URL(req.url);
    const challenge = url.searchParams.get("hub.challenge");
    return new Response(challenge, { status: 200 });
  }

  if (req.method === "POST") {
    return new Response("OK", { status: 200 });
  }

  if (req.method === "OPTIONS") {
    return new Response("OK", { status: 200 });
  }

  return new Response("Not found", { status: 404 });
});
