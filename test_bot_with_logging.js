const WEBHOOK_URL = "https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook";

console.log("🧪 TESTING BOT WITH DIAGNOSTIC LOGGING\n");
console.log("═══════════════════════════════════════════════════════════════\n");

// Send a test message
const testPayload = {
  object: "whatsapp_business_account",
  entry: [{
    id: "0",
    changes: [{
      value: {
        messaging_product: "whatsapp",
        metadata: {
          display_phone_number: "39328185",
          phone_number_id: "123456789",
          business_account_id: "123456789"
        },
        messages: [{
          from: "393281854639",
          id: "wamid.test_" + Date.now(),
          timestamp: Math.floor(Date.now() / 1000),
          type: "text",
          text: {
            body: "🤖 Test automatico: Ciao, funzioni?"
          }
        }],
        contacts: [{
          profile: {
            name: "Test Rider"
          },
          wa_id: "393281854639"
        }]
      }
    }]
  }]
};

console.log("📤 Sending test message to webhook...\n");
console.log("Payload:", JSON.stringify(testPayload, null, 2).substring(0, 300) + "...\n");

fetch(WEBHOOK_URL, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(testPayload)
})
.then(r => {
  console.log(`✅ Webhook Response Status: ${r.status}\n`);
  return r.text();
})
.then(body => {
  console.log(`Response Body: "${body}"\n`);
  
  console.log("═══════════════════════════════════════════════════════════════\n");
  console.log("📝 EXPECTED BEHAVIOR:\n");
  console.log("✅ If webhook logs show:");
  console.log("   - '📨 Webhook received' → META RECEIVES MESSAGES");
  console.log("   - '🤖 Starting ChatGPT' → OPENAI_API_KEY IS SET ✅");
  console.log("   - '✅ Meta sent to' → MESSAGE SENT BACK ✅");
  console.log("   - '❌ OPENAI_API_KEY not configured' → NEED TO SET IT\n");
  
  console.log("📊 TO SEE LOGS:\n");
  console.log("1. Go to: https://app.supabase.com");
  console.log("2. Project: aqpwfurradxbnqvycvkm");
  console.log("3. Functions > whatsapp-webhook > Logs");
  console.log("4. Look for messages from the last 10 seconds\n");
  
  console.log("🔑 MISSING SECRETS WILL SHOW:");
  console.log("   - ❌ OPENAI_API_KEY not configured");
  console.log("   - ❌ Meta credentials missing");
  console.log("   - ❌ OpenAI API error 401\n");
})
.catch(e => console.error("Error:", e.message));
