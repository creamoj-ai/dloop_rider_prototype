// Diagnostic: test full WhatsApp bot pipeline step by step
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { getServiceClient } from "../_shared/supabase.ts";

serve(async (req: Request) => {
  // Handle GET — Meta webhook verification
  if (req.method === "GET") {
    const url = new URL(req.url);
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");
    console.log("Verification attempt:", { mode, token, challenge });
    if (mode === "subscribe" && token === "dloop_wa_verify_2026") {
      return new Response(challenge ?? "", { status: 200, headers: { "Content-Type": "text/plain" } });
    }
    return new Response("Forbidden", { status: 403 });
  }

  const steps: Record<string, unknown>[] = [];

  // Step 1: Check env vars
  const WA_PHONE_NUMBER_ID = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID") ?? "";
  const WA_ACCESS_TOKEN = Deno.env.get("WHATSAPP_ACCESS_TOKEN") ?? "";
  const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
  const HAS_SERVICE_KEY = (Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "").length > 0;
  const HAS_OPENAI = (Deno.env.get("OPENAI_API_KEY") ?? "").length > 0;

  const VERIFY_TOKEN = Deno.env.get("WHATSAPP_VERIFY_TOKEN") ?? "";

  steps.push({
    step: "1_env_vars",
    phoneNumberId: WA_PHONE_NUMBER_ID.substring(0, 5) + "...",
    hasAccessToken: WA_ACCESS_TOKEN.length > 0,
    supabaseUrl: SUPABASE_URL.substring(0, 30) + "...",
    hasServiceRoleKey: HAS_SERVICE_KEY,
    hasOpenAiKey: HAS_OPENAI,
    verifyToken: VERIFY_TOKEN,
    verifyTokenLength: VERIFY_TOKEN.length,
  });

  // Step 2: Test DB connection
  try {
    const db = getServiceClient();
    const { data, error } = await db.from("rider_contacts").select("id, name").limit(2);
    steps.push({
      step: "2_db_connection",
      ok: !error,
      error: error?.message ?? null,
      rowCount: data?.length ?? 0,
    });
  } catch (e) {
    steps.push({ step: "2_db_connection", ok: false, error: String(e) });
  }

  // Step 3: Test whatsapp_conversations table
  try {
    const db = getServiceClient();
    const { data, error } = await db.from("whatsapp_conversations").select("id, phone, role").order("created_at", { ascending: false }).limit(3);
    steps.push({
      step: "3_conversations",
      ok: !error,
      error: error?.message ?? null,
      data: data,
    });
  } catch (e) {
    steps.push({ step: "3_conversations", ok: false, error: String(e) });
  }

  // Step 4: Test whatsapp_messages table (last 5)
  try {
    const db = getServiceClient();
    const { data, error } = await db.from("whatsapp_messages").select("id, direction, content, status, created_at").order("created_at", { ascending: false }).limit(5);
    steps.push({
      step: "4_messages",
      ok: !error,
      error: error?.message ?? null,
      data: data,
    });
  } catch (e) {
    steps.push({ step: "4_messages", ok: false, error: String(e) });
  }

  // Step 5: Test OpenAI
  try {
    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
    const resp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [{ role: "user", content: "Rispondi solo OK" }],
        max_tokens: 5,
      }),
    });
    const data = await resp.json();
    steps.push({
      step: "5_openai",
      ok: resp.ok,
      status: resp.status,
      reply: data.choices?.[0]?.message?.content ?? data.error?.message,
    });
  } catch (e) {
    steps.push({ step: "5_openai", ok: false, error: String(e) });
  }

  // Step 6: Test sendWhatsAppMessage using the SAME code as webhook
  try {
    const { sendWhatsAppMessage } = await import("../whatsapp-webhook/whatsapp_api.ts");
    const sendResult = await sendWhatsAppMessage("393281854639", "Test invio da wa-test via whatsapp_api.ts!");
    steps.push({
      step: "6_send_via_whatsapp_api",
      ...sendResult,
    });
  } catch (e) {
    steps.push({ step: "6_send_via_whatsapp_api", ok: false, error: String(e) });
  }

  return new Response(JSON.stringify({ steps }, null, 2), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
