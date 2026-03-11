import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

console.log('🚀 WhatsApp Simple Bot - NO EXTERNAL DEPS');

serve(async (req: Request) => {
  if (req.method === 'POST') {
    try {
      const contentType = req.headers.get('content-type') || '';

      // Parse Twilio format
      if (contentType.includes('application/x-www-form-urlencoded')) {
        const text = await req.text();
        const params = new URLSearchParams(text);

        const from = params.get('From') || '';
        const body = params.get('Body') || '';
        const phone = from.replace('whatsapp:', '').trim();

        console.log(`📨 Message from ${phone}: "${body}"`);

        // SUPER SIMPLE RESPONSE
        let reply = '';

        if (body.toLowerCase().includes('maglietta') || body.toLowerCase().includes('fashion')) {
          reply = '👔 Perfetto! Vai su https://dloop-pwa.vercel.app e ordina da YAMAMAY per le migliori magliette! 🎉';
        } else if (body.toLowerCase().includes('animali') || body.toLowerCase().includes('pet')) {
          reply = '🐾 Ottima scelta! Visita https://dloop-pwa.vercel.app - TOELETTATURA PET ha tutto per i tuoi amici a 4 zampe! 🐶';
        } else if (body.toLowerCase().includes('spesa') || body.toLowerCase().includes('cibo')) {
          reply = '🛒 Abbiamo quello che serve! Vai su https://dloop-pwa.vercel.app e ordina da PICCOLO SUPERMARKET! 🥬';
        } else {
          reply = `✅ Ho ricevuto: "${body}"\n\n📱 Visita https://dloop-pwa.vercel.app per ordinare dai migliori negozi di Napoli!\n\n${getRandomEmoji()} Cosa ti serve oggi?`;
        }

        console.log(`✅ Sending: ${reply}`);
        return new Response(JSON.stringify({ status: 'OK', reply, phone }), {
          headers: { 'Content-Type': 'application/json' }
        });
      }
    } catch (e) {
      console.error('Error:', e);
    }
  }

  return new Response('OK', { status: 200 });
});

function getRandomEmoji(): string {
  const emojis = ['🎁', '⚡', '🔥', '💎', '🌟', '✨'];
  return emojis[Math.floor(Math.random() * emojis.length)];
}
