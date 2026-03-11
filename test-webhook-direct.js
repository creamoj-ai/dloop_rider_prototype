// Test webhook direttamente (simula richiesta Meta)
const WEBHOOK_URL = "https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook";

const testPayload = {
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "123456789",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "39328185463",
              "phone_number_id": "191359627217151"
            },
            "contacts": [
              {
                "profile": {
                  "name": "Test User"
                },
                "wa_id": "393281854639"
              }
            ],
            "messages": [
              {
                "from": "393281854639",
                "id": "wamid.test123",
                "timestamp": Math.floor(Date.now() / 1000),
                "type": "text",
                "text": {
                  "body": "Ciao test"
                }
              }
            ]
          },
          "field": "messages"
        }
      ],
      "timestamp": Math.floor(Date.now() / 1000)
    }
  ]
};

console.log("🧪 Testing webhook directly (simulating Meta request)...\n");
console.log(`📤 POST ${WEBHOOK_URL}`);
console.log(`📦 Sending test payload\n`);

(async () => {
  try {
    const res = await fetch(WEBHOOK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "Meta-Webhook-Test"
      },
      body: JSON.stringify(testPayload)
    });

    console.log(`✅ Response Status: ${res.status}`);
    const body = await res.text();
    console.log(`📄 Response Body: ${body}\n`);

    if (res.status === 200) {
      console.log("✅ Webhook is reachable!");
      console.log("✅ Now check Supabase logs for function invocation\n");
      console.log("📋 Steps to check logs:");
      console.log("   1. Go to: https://app.supabase.com");
      console.log("   2. Project: aqpwfurradxbnqvycvkm");
      console.log("   3. Functions > whatsapp-webhook > Invocations");
      console.log("   4. Look for the most recent invocation\n");
    } else {
      console.log("❌ Webhook returned error status!");
    }
  } catch (e) {
    console.error("❌ Error calling webhook:", e.message);
  }
})();
