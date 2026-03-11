import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

console.log('🚀 [INIT] Webhook function starting - MINIMAL TEST');

let db: any;

try {
  console.log('📦 [INIT] Importing dependencies...');
  const { createClient } = await import("npm:@supabase/supabase-js@2.46.1");
  const { processInboundMessage } = await import("./processor.ts");

  console.log('✅ [INIT] Imports successful');

  const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
  const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

  console.log(`🔐 [INIT] SUPABASE_URL: ${SUPABASE_URL ? 'SET' : 'MISSING'}`);
  console.log(`🔐 [INIT] SERVICE_KEY: ${SERVICE_KEY ? 'SET (' + SERVICE_KEY.length + ' chars)' : 'MISSING'}`);

  if (!SUPABASE_URL || !SERVICE_KEY) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  }

  console.log('✅ [INIT] Environment variables OK');
  db = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });
  console.log('✅ [INIT] Supabase client created successfully');
} catch (initError) {
  console.error('❌ [INIT] Initialization failed:', initError);
}

serve(async (req: Request) => {
  // ✅ GET request (Meta webhook verification)
  if (req.method === 'GET') {
    const url = new URL(req.url);
    const hubChallenge = url.searchParams.get('hub.challenge');
    const hubVerifyToken = url.searchParams.get('hub.verify_token');

    // Meta webhook verification
    if (hubChallenge && hubVerifyToken === 'dloop_wa_verify_2026') {
      return new Response(hubChallenge, { status: 200 });
    }

    return new Response('WhatsApp webhook is running (Meta API Only)', { status: 200 });
  }

  // ✅ POST request (incoming messages from Twilio or Meta WhatsApp)
  if (req.method === 'POST') {
    try {
      const contentType = req.headers.get('content-type') || '';
      let body: Record<string, unknown> = {};
      let phone = '';
      let content = '';
      let profileName = '';

      console.log('📨 Webhook received');

      // ── DETECT MESSAGE SOURCE (Twilio vs Meta) ──
      if (contentType.includes('application/x-www-form-urlencoded')) {
        // ── TWILIO FORMAT (form-encoded) ──
        console.log('📨 Twilio WhatsApp format detected');
        const text = await req.text();
        const params = new URLSearchParams(text);

        // Twilio sends: From=whatsapp:+39328..., Body=message
        const from = params.get('From') || '';
        content = params.get('Body') || '';

        // Extract phone from "whatsapp:+39328..."
        phone = from.replace('whatsapp:', '').trim();

        // ✅ FILTER: Ignore status callbacks and empty messages
        const messageStatus = params.get('MessageStatus');
        if (messageStatus && messageStatus !== 'received') {
          console.log(`⏭️ Ignoring status callback: ${messageStatus}`);
          return new Response('OK', { status: 200 });
        }

        if (!content || content.trim().length === 0) {
          console.log('⏭️ Skipping empty message');
          return new Response('OK', { status: 200 });
        }

        console.log(`📨 Twilio WhatsApp - From: ${phone}`);
        console.log(`📝 Content: "${content.substring(0, 100)}${content.length > 100 ? '...' : ''}"`);
      } else {
        // ── META FORMAT (JSON) ──
        console.log('📨 Meta WhatsApp format detected');
        try {
          body = await req.json();
        } catch (e) {
          console.log('⚠️ Could not parse JSON:', e);
          return new Response('OK', { status: 200 });
        }

        // ── EXTRACT META MESSAGE ──
        const msg = (body as any).entry?.[0]?.changes?.[0]?.value?.messages?.[0];
        if (!msg) {
          console.log('⏭️ No message in webhook payload');
          return new Response('OK', { status: 200 });
        }

        phone = msg.from as string;
        content = msg.text?.body as string || '';
        profileName = (body as any).entry[0].changes[0].value.contacts?.[0]?.profile?.name;

        // ✅ FILTER: Ignore empty messages
        if (!content || content.trim().length === 0) {
          console.log('⏭️ Skipping empty message');
          return new Response('OK', { status: 200 });
        }

        console.log(`📨 Meta WhatsApp - From: ${phone}`);
        console.log(`📝 Content: "${content.substring(0, 100)}${content.length > 100 ? '...' : ''}"`);
      }

      // ✅ Return 200 immediately (webhook pattern - non-blocking)
      const response = new Response('OK', { status: 200 });

      // ✅ Process message asynchronously (non-blocking)
      (async () => {
        try {
          console.log(`🤖 Starting ChatGPT processing for ${phone}...`);

          if (!db) {
            console.error('❌ Database not initialized - cannot process message');
            return;
          }

          const { processInboundMessage } = await import("./processor.ts");
          const { reply } = await processInboundMessage(db, {
            phone,
            text: content,
            name: profileName,
          });

          console.log(`✅ Reply sent to ${phone}: "${reply.substring(0, 80)}${reply.length > 80 ? '...' : ''}"`);
        } catch (e) {
          console.error('❌ Processing error:', e);
          console.error('Stack:', e instanceof Error ? e.stack : 'No stack trace');
        }
      })();

      return response;
    } catch (e) {
      console.error('❌ Webhook error:', e);
      console.error('Stack:', e instanceof Error ? e.stack : 'No stack trace');

      // ✅ Always return 200 to prevent webhook retries
      return new Response('OK', { status: 200 });
    }
  }

  // ✅ Method not allowed
  return new Response('Method not allowed', { status: 405 });
});
