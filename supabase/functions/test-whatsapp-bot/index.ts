import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

console.log('🧪 WhatsApp Bot Test Endpoint Started');

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('POST only', { status: 405 });
  }

  try {
    const { message, phone } = await req.json() as { message: string; phone: string };

    const response = {
      status: 'OK',
      received: { message, phone },
      tests: {
        openai_key: checkOpenAIKey(),
        twilio_sid: Deno.env.get('TWILIO_ACCOUNT_SID') ? '✅ SET' : '❌ MISSING',
        twilio_token: Deno.env.get('TWILIO_AUTH_TOKEN') ? '✅ SET' : '❌ MISSING',
        twilio_phone: Deno.env.get('TWILIO_PHONE_NUMBER') ?? '❌ MISSING',
        supabase_url: Deno.env.get('SUPABASE_URL') ? '✅ SET' : '❌ MISSING',
      },
      echo: `Bot riceve: "${message}" da ${phone}`,
    };

    return new Response(JSON.stringify(response, null, 2), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});

function checkOpenAIKey(): string {
  const key = Deno.env.get('OPENAI_API_KEY');
  if (!key) return '❌ MISSING';
  if (key.startsWith('sk-proj')) return '✅ SET (valid format)';
  return '⚠️ SET (invalid format)';
}
