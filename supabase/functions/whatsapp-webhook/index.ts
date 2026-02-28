import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";
import { processInboundMessage } from "./processor.ts";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const db = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

serve(async (req: Request) => {
  // ✅ GET request (health check + Twilio webhook verification)
  if (req.method === 'GET') {
    const url = new URL(req.url);
    const hubChallenge = url.searchParams.get('hub.challenge');
    const hubVerifyToken = url.searchParams.get('hub.verify_token');

    // Meta webhook verification
    if (hubChallenge && hubVerifyToken === 'dloop_wa_verify_2026') {
      return new Response(hubChallenge, { status: 200 });
    }

    return new Response('WhatsApp webhook is running (Production Ready)', { status: 200 });
  }

  // ✅ POST request (incoming messages)
  if (req.method === 'POST') {
    try {
      const contentType = req.headers.get('content-type') || '';
      let body: Record<string, string> = {};

      console.log('📨 Webhook received:', contentType);

      // ── PARSE REQUEST BODY (CRITICAL: Content-Type detection) ──
      if (contentType.includes('application/json')) {
        // Meta WhatsApp API (JSON)
        body = await req.json();
        console.log('📦 JSON body (Meta format):', Object.keys(body));
      } else if (contentType.includes('application/x-www-form-urlencoded')) {
        // Twilio WhatsApp API (form-encoded)
        const text = await req.text();
        console.log('📦 Form data received (Twilio format)');

        // Parse form-encoded safely
        const params = new URLSearchParams(text);
        for (const [key, value] of params.entries()) {
          body[key] = value;
        }
        console.log('📦 Parsed fields:', Object.keys(body).join(', '));
      } else {
        console.log('⚠️ Unknown content-type, attempting JSON fallback');
        try {
          body = await req.json();
        } catch (e) {
          console.log('⚠️ Could not parse request body:', e);
          return new Response('OK', { status: 200 });
        }
      }

      // ── TWILIO FORMAT (form-encoded) ──────────────────────────────────
      if (body.From && body.MessageSid) {
        const messageStatus = body.MessageStatus || body.SmsStatus || '';

        console.log(`📨 Twilio webhook - MessageSid: ${body.MessageSid}, Status: ${messageStatus}`);

        // ✅ CRITICAL FILTER: Only process INBOUND messages (status = "received")
        // Ignore ALL status callbacks (delivered, read, sent, failed, undelivered)
        if (messageStatus && messageStatus !== 'received') {
          console.log(`⏭️ Skipping status callback: ${messageStatus} (not a new message)`);
          return new Response('OK', { status: 200 });
        }

        // ✅ FILTER: Ignore messages without body text
        if (!body.Body || body.Body.trim().length === 0) {
          console.log('⏭️ Skipping empty message (no text content)');
          return new Response('OK', { status: 200 });
        }

        // ✅ Extract message data
        const phone = (body.From as string).replace('whatsapp:', '').replace('tel:', '');
        const content = body.Body.trim();
        const profileName = body.ProfileName || undefined;

        console.log(`✅ Processing Twilio inbound message from ${phone}`);
        console.log(`📝 Content: "${content.substring(0, 100)}${content.length > 100 ? '...' : ''}"`);

        // ✅ Return 200 immediately (webhook pattern - non-blocking)
        const response = new Response('OK', { status: 200 });

        // ✅ Process message asynchronously (non-blocking)
        (async () => {
          try {
            console.log(`🤖 Starting ChatGPT processing for ${phone}...`);

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
      }

      // ── META FORMAT (JSON) ────────────────────────────────────────────
      else if ((body as any).entry?.[0]?.changes?.[0]?.value?.messages?.[0]) {
        const msg = (body as any).entry[0].changes[0].value.messages[0];
        const phone = msg.from as string;
        const content = msg.text?.body as string || '';
        const profileName = (body as any).entry[0].changes[0].value.contacts?.[0]?.profile?.name;

        console.log(`📨 Meta webhook - From: ${phone}`);
        console.log(`📝 Content: "${content.substring(0, 100)}${content.length > 100 ? '...' : ''}"`);

        // Return 200 immediately
        const response = new Response('OK', { status: 200 });

        // Process async
        (async () => {
          try {
            console.log(`🤖 Starting ChatGPT processing for ${phone}...`);

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
      }

      // ── UNKNOWN FORMAT ────────────────────────────────────────────────
      else {
        console.log('⚠️ No valid message found in webhook payload');
        console.log('Body keys:', Object.keys(body).join(', '));

        // Log first few fields for debugging
        const preview = Object.entries(body).slice(0, 5).map(([k, v]) => `${k}: ${v}`).join(', ');
        console.log('Preview:', preview);

        return new Response('OK', { status: 200 });
      }
    } catch (e) {
      console.error('❌ Webhook error:', e);
      console.error('Stack:', e instanceof Error ? e.stack : 'No stack trace');

      // ✅ CRITICAL: Always return 200 to prevent Twilio retries
      return new Response('OK', { status: 200 });
    }
  }

  // ✅ Method not allowed
  return new Response('Method not allowed', { status: 405 });
});
