const webhookUrl = 'https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook';

// Simula un messaggio WhatsApp da Meta
const testPayload = {
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "123456",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "39328185463900391",
              "phone_number_id": "979991158533832"
            },
            "messages": [
              {
                "from": "393911234567",
                "id": "wamid.test123",
                "timestamp": "1708881704",
                "type": "text",
                "text": {
                  "body": "Ciao, mi servono prodotti per il gatto"
                }
              }
            ],
            "contacts": [
              {
                "profile": {
                  "name": "Test User"
                },
                "wa_id": "393911234567"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
};

console.log(`
╔════════════════════════════════════════════════════════════════╗
║        Testing Webhook Directly with Test Payload              ║
╚════════════════════════════════════════════════════════════════╝

📤 Sending POST to webhook...
`);

fetch(webhookUrl, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(testPayload)
})
  .then(r => {
    console.log(`✅ Response: ${r.status} ${r.statusText}`);
    return r.text();
  })
  .then(text => {
    console.log(`📝 Body: ${text.substring(0, 200)}`);
  })
  .catch(e => {
    console.error(`❌ Error: ${e.message}`);
  });
