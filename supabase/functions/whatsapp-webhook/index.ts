import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";
import { processInboundMessage } from "./processor.ts";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const TWILIO_ACCOUNT_SID = Deno.env.get('TWILIO_ACCOUNT_SID')!;
const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN')!;
const TWILIO_PHONE_NUMBER = Deno.env.get('TWILIO_PHONE_NUMBER')!;

const db = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

serve(async (req: Request) => {
  if (req.method === 'POST') {
    try {
      const contentType = req.headers.get('content-type') || '';
      let body: Record<string, unknown> = {};

      // Parse request body - handle both JSON and form-encoded
      if (contentType.includes('application/json')) {
        body = await req.json();
      } else if (contentType.includes('application/x-www-form-urlencoded')) {
        const formData = await req.formData();
        for (const [key, value] of formData) {
          body[key] = value;
        }
      } else {
        try {
          body = await req.json();
        } catch {
          console.log('⚠️ Could not parse request body');
          return new Response('OK', { status: 200 });
        }
      }

      console.log('📨 Webhook received');

      let phone = '';
      let content = '';

      // Twilio format (form-encoded)
      if (body.From) {
        phone = (body.From as string).replace('whatsapp:', '');
        content = (body.Body as string) || '';
        console.log(`📨 Twilio message from ${phone}`);
      }
      // Meta format (JSON)
      else if ((body.entry as any)?.[0]?.changes?.[0]?.value?.messages?.[0]) {
        const msg = (body.entry as any)[0].changes[0].value.messages[0];
        phone = msg.from as string;
        content = msg.text?.body as string || '';
        console.log(`📨 Meta message from ${phone}`);
      }
      else {
        console.log('⚠️ No message found in request');
        return new Response('OK', { status: 200 });
      }

      // Return 200 immediately (webhook pattern)
      const response = new Response('OK', { status: 200 });

      // Process async (non-blocking) - let processor.ts handle EVERYTHING
      (async () => {
        try {
          console.log(`📨 Processing message: "${content.substring(0, 50)}"`);

          // processor.ts handles:
          // - Getting/creating conversation
          // - Saving inbound message
          // - ChatGPT processing
          // - Sending reply via Twilio
          // - Saving outbound message
          const { reply } = await processInboundMessage(db, {
            phone,
            text: content,
          });

          console.log(`✅ Message processed. Reply: "${reply.substring(0, 80)}..."`);
        } catch (e) {
          console.error('❌ Processing error:', e);
        }
      })();

      return response;
    } catch (e) {
      console.error('❌ Parse error:', e);
      return new Response('OK', { status: 200 });
    }
  }

  return new Response('Not found', { status: 404 });
});
