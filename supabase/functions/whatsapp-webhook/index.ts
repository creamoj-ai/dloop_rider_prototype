import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

console.log('🚀 [WEBHOOK v2 PRODUCTION] Starting...');

let db: any;

try {
  const { createClient } = await import("npm:@supabase/supabase-js@2.46.1");
  const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
  const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  if (SUPABASE_URL && SERVICE_KEY) {
    db = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });
    console.log('✅ Supabase initialized');
  }
} catch (e) {
  console.error('⚠️ Supabase init failed:', e);
}

serve(async (req: Request) => {
  const method = req.method;
  const url = new URL(req.url);

  // ✅ GET (Meta verification)
  if (method === 'GET') {
    const challenge = url.searchParams.get('hub.challenge');
    const token = url.searchParams.get('hub.verify_token');

    if (challenge && token === 'dloop_wa_verify_2026') {
      console.log('✅ Meta webhook verified');
      return new Response(challenge, { status: 200 });
    }
    return new Response('OK', { status: 200 });
  }

  // ✅ POST (incoming messages)
  if (method === 'POST') {
    try {
      const contentType = req.headers.get('content-type') || '';
      let phone = '';
      let text = '';
      let profileName = '';

      console.log(`📨 [${method}] Webhook received`);

      // ── TWILIO FORMAT ──
      if (contentType.includes('application/x-www-form-urlencoded')) {
        console.log('📨 [TWILIO FORMAT]');
        const body = await req.text();
        const params = new URLSearchParams(body);

        phone = params.get('From')?.replace('whatsapp:', '').trim() || '';
        text = params.get('Body')?.trim() || '';

        if (!text) {
          console.log('⏭️ Empty message');
          return new Response('OK', { status: 200 });
        }
      }
      // ── META FORMAT ──
      else {
        console.log('📨 [META FORMAT]');
        try {
          const body = await req.json() as Record<string, any>;
          const msg = body.entry?.[0]?.changes?.[0]?.value?.messages?.[0];

          if (!msg) {
            return new Response('OK', { status: 200 });
          }

          phone = msg.from as string;
          text = msg.text?.body as string || '';
          profileName = body.entry[0].changes[0].value.contacts?.[0]?.profile?.name;
        } catch (e) {
          return new Response('OK', { status: 200 });
        }
      }

      console.log(`📩 From: ${phone}`);
      console.log(`📝 Text: "${text.substring(0, 60)}${text.length > 60 ? '...' : ''}"`);

      // ✅ Return 200 immediately (non-blocking)
      const response = new Response('OK', { status: 200 });

      // ✅ Process asynchronously
      (async () => {
        try {
          if (!db) {
            console.warn('⚠️ DB not available');
            return;
          }

          // Import processor for ChatGPT
          const { processInboundMessage } = await import("./processor.ts");
          console.log('🤖 Processing with ChatGPT...');
          const { reply } = await processInboundMessage(db, {
            phone,
            text,
            name: profileName,
          });

          console.log(`✅ Reply generated: "${reply.substring(0, 60)}..."`);

          // Import Twilio API
          const { sendWhatsAppMessage } = await import("./twilio_api.ts");
          const formattedPhone = phone.startsWith("+") ? phone : `+${phone}`;
          const sendResult = await sendWhatsAppMessage(formattedPhone, reply);

          if (sendResult.success) {
            console.log(`✅ Message sent via Twilio! ID: ${sendResult.messageId}`);
          } else {
            console.error(`❌ Twilio failed: ${sendResult.error}`);
          }

        } catch (e) {
          console.error('❌ Processing error:', e);
        }
      })();

      return response;

    } catch (e) {
      console.error('❌ Webhook error:', e);
      return new Response('OK', { status: 200 });
    }
  }

  return new Response('Method not allowed', { status: 405 });
});
