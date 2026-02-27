import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const TWILIO_ACCOUNT_SID = Deno.env.get('TWILIO_ACCOUNT_SID')!;
const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN')!;
const TWILIO_PHONE_NUMBER = Deno.env.get('TWILIO_PHONE_NUMBER')!;

const db = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

async function sendTwilioMessage(to: string, text: string) {
  const fromNumber = TWILIO_PHONE_NUMBER.replace('+', '');
  const toNumber = to.replace('+', '');

  const authHeader = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`);
  const formData = new URLSearchParams();
  formData.append('From', `whatsapp:+${fromNumber}`);
  formData.append('To', `whatsapp:+${toNumber}`);
  formData.append('Body', text);

  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${authHeader}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData.toString(),
    }
  );

  const data = await res.json();
  if (!res.ok) {
    console.error('Twilio error:', data);
    throw new Error(`Twilio error ${res.status}`);
  }
  return data;
}

serve(async (req: Request) => {
  if (req.method === 'POST') {
    try {
      const body = await req.json();
      console.log('📨 Webhook received');

      let phone = '';
      let content = '';

      // Twilio format
      if (body.From) {
        phone = body.From.replace('whatsapp:', '');
        content = body.Body || '';
        console.log(`📨 Twilio message from ${phone}`);
      }
      // Meta format
      else if (body.entry?.[0]?.changes?.[0]?.value?.messages?.[0]) {
        const msg = body.entry[0].changes[0].value.messages[0];
        phone = msg.from;
        content = msg.text?.body || '';
        console.log(`📨 Meta message from ${phone}`);
      }
      else {
        console.log('⚠️ No message');
        return new Response('OK', { status: 200 });
      }

      // Return 200 immediately
      const response = new Response('OK', { status: 200 });

      // Process async (non-blocking)
      (async () => {
        try {
          console.log(`Processing message: "${content.substring(0, 50)}"`);

          // Get or create conversation
          let convId = '';
          try {
            const { data } = await db
              .from('whatsapp_conversations')
              .select('id')
              .eq('phone', phone)
              .single();
            convId = data?.id || '';
          } catch {
            // Not found, create new
            convId = '';
          }

          if (!convId) {
            const { data } = await db
              .from('whatsapp_conversations')
              .insert({
                phone,
                message_count: 0,
                last_message_at: new Date().toISOString(),
              })
              .select('id')
              .single();
            convId = data?.id || '';
          }

          if (!convId) {
            console.error('Failed to get/create conversation');
            return;
          }

          // Save inbound message
          await db.from('whatsapp_messages').insert({
            conversation_id: convId,
            phone,
            direction: 'inbound',
            content,
            message_type: 'text',
            status: 'received',
          });

          console.log('✅ Inbound message saved');

          // Send reply via Twilio
          const reply = `✅ Ricevuto: "${content.substring(0, 30)}"`;
          console.log(`Sending reply: "${reply}"`);

          try {
            const twilioResp = await sendTwilioMessage(phone, reply);
            console.log('✅ Twilio reply sent:', twilioResp.sid);

            // Save outbound message
            await db.from('whatsapp_messages').insert({
              conversation_id: convId,
              phone,
              direction: 'outbound',
              content: reply,
              message_type: 'text',
              status: 'sent',
            });

            console.log('✅ Done - message processed successfully');
          } catch (e) {
            console.error('❌ Failed to send Twilio reply:', e);
            // Save as failed
            await db.from('whatsapp_messages').insert({
              conversation_id: convId,
              phone,
              direction: 'outbound',
              content: reply,
              message_type: 'text',
              status: 'failed',
            });
          }
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
