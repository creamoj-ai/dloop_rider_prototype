/**
 * Test il webhook usando il NUMERO DI TEST di Meta
 * Se questo funziona, il webhook è OK e il problema è Meta
 */

const https = require('https');

// Questo è il payload che Meta manda quando riceve un messaggio
// da uno dei numeri di TEST di Meta (15551505103)
const testPayload = {
  "object": "whatsapp_business_account",
  "entry": [{
    "id": "979991158533832",
    "changes": [{
      "value": {
        "messaging_product": "whatsapp",
        "metadata": {
          "display_phone_number": "39328185464",
          "phone_number_id": "979991158533832"
        },
        "contacts": [{
          "wa_id": "15551505103",
          "profile": { "name": "Meta Test Number" }
        }],
        "messages": [{
          "from": "15551505103",
          "id": "wamid.meta_test_" + Date.now(),
          "timestamp": Math.floor(Date.now() / 1000).toString(),
          "type": "text",
          "text": { "body": "Messaggio dal numero di test Meta" }
        }]
      },
      "field": "messages"
    }]
  }]
};

const postData = JSON.stringify(testPayload);

const options = {
  hostname: 'aqpwfurradxbnqvycvkm.supabase.co',
  port: 443,
  path: '/functions/v1/whatsapp-webhook',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(postData)
  }
};

console.log('\n🧪 TEST CON NUMERO DI TEST META (15551505103)\n');
console.log('Inviando messaggio simulato dal numero di test...\n');

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('📨 WEBHOOK RESPONSE:');
    console.log('Status Code:', res.statusCode);
    console.log('Response Body:', data);
    console.log('\n');

    if (res.statusCode === 200) {
      console.log('✅ SUCCESSO! Webhook ha accettato il messaggio!\n');
      console.log('Adesso:');
      console.log('1. Attendi 5 secondi...');
      setTimeout(() => {
        console.log('2. Esegui: node diagnose-bot.js');
        console.log('   Dovresti vedere il messaggio nel database!\n');
      }, 5000);
    } else {
      console.log('❌ ERRORE nel webhook. Status:', res.statusCode);
      console.log('Response:', data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Errore nella richiesta:', error);
});

req.write(postData);
req.end();
