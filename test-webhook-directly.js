/**
 * SOLUZIONE DRASTICA — Testa il webhook mandando un messaggio simulato
 * Questo bypassa Meta completamente e testa il vero codice
 */

const https = require('https');
const anonKey = 'sb_publishable_NBWU-byCV0TIsj5-8Mixog_CEV7IkrB';
const supabaseUrl = 'https://aqpwfurradxbnqvycvkm.supabase.co';

// Payload che Meta manderebbe
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
          "wa_id": "393331234567",
          "profile": { "name": "Test Customer" }
        }],
        "messages": [{
          "from": "393331234567",
          "id": "wamid.test_msg_12345",
          "timestamp": Math.floor(Date.now() / 1000).toString(),
          "type": "text",
          "text": { "body": "Ciao! Questo è un test." }
        }]
      },
      "field": "messages"
    }]
  }]
};

console.log('🧪 TESTING WEBHOOK — Sending simulated Meta message...\n');
console.log('Payload:', JSON.stringify(testPayload, null, 2), '\n');

const postData = JSON.stringify(testPayload);

const options = {
  hostname: 'aqpwfurradxbnqvycvkm.supabase.co',
  port: 443,
  path: '/functions/v1/whatsapp-webhook',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': postData.length,
    'Authorization': `Bearer ${anonKey}`,
    'apikey': anonKey
  }
};

const req = https.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('✅ WEBHOOK RESPONSE:');
    console.log('Status:', res.statusCode);
    console.log('Headers:', res.headers);
    console.log('Body:', data);
    console.log('\n');

    if (res.statusCode === 200) {
      console.log('✅ Webhook accepted the message!\n');
      console.log('Next steps:');
      console.log('1. Wait 5 seconds...');
      setTimeout(() => {
        console.log('\n2. Run: node diagnose-bot.js');
        console.log('   You should now see messages in the database!\n');
      }, 5000);
    } else {
      console.log('❌ Webhook returned error. Check the response above.\n');
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Request failed:', error.message);
});

req.write(postData);
req.end();
