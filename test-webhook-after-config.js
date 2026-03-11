// Test Webhook After Meta Configuration
const WEBHOOK_URL = "https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook";
const PHONE_NUMBER_ID = "959037787303696";

console.log("\n╔════════════════════════════════════════════════════════════════╗");
console.log("║              TESTING WEBHOOK AFTER CONFIGURATION              ║");
console.log("╚════════════════════════════════════════════════════════════════╝\n");

(async () => {
  // Test 1: Verify GET request (Meta webhook verification)
  console.log("🔍 TEST 1: GET Verification (Meta checks webhook)\n");
  
  try {
    const getRes = await fetch(WEBHOOK_URL + "?hub.challenge=test_challenge_123&hub.verify_token=dloop_wa_verify_2026");
    const getText = await getRes.text();
    
    if (getText === "test_challenge_123") {
      console.log("✅ GET verification: SUCCESS");
      console.log(`   Webhook returns the challenge correctly\n`);
    } else {
      console.log(`⚠️  GET verification: Unexpected response "${getText}"\n`);
    }
  } catch (e) {
    console.error(`❌ GET request failed: ${e.message}\n`);
  }

  // Test 2: Send test message (simulating Meta webhook)
  console.log("📨 TEST 2: POST Message (Simulating Meta sending a message)\n");
  
  const testPayload = {
    object: "whatsapp_business_account",
    entry: [{
      id: "123456789",
      changes: [{
        value: {
          messaging_product: "whatsapp",
          metadata: {
            display_phone_number: "39328185463",
            phone_number_id: PHONE_NUMBER_ID
          },
          contacts: [{
            profile: { name: "Test User" },
            wa_id: "393281854639"
          }],
          messages: [{
            from: "393281854639",
            id: "wamid.test_" + Date.now(),
            timestamp: Math.floor(Date.now() / 1000),
            type: "text",
            text: { body: "Ciao, test del bot!" }
          }]
        },
        field: "messages"
      }]
    }]
  };

  try {
    const postRes = await fetch(WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(testPayload)
    });

    const postText = await postRes.text();
    
    console.log(`✅ POST request: Status ${postRes.status}`);
    console.log(`   Response: "${postText}"\n`);

    if (postRes.status === 200) {
      console.log("✅ Webhook is working correctly!\n");
    }
  } catch (e) {
    console.error(`❌ POST request failed: ${e.message}\n`);
  }

  // Summary
  console.log("╔════════════════════════════════════════════════════════════════╗");
  console.log("║                        NEXT STEPS                             ║");
  console.log("╚════════════════════════════════════════════════════════════════╝\n");

  console.log("🚀 SEND A REAL MESSAGE:\n");
  console.log("   1. Open WhatsApp on your phone");
  console.log("   2. Send a message to: +39 328 185 4639");
  console.log("   3. Bot should respond in 5-10 seconds\n");

  console.log("📋 CHECK SUPABASE LOGS:\n");
  console.log("   https://app.supabase.com");
  console.log("   → Project: aqpwfurradxbnqvycvkm");
  console.log("   → Functions → whatsapp-webhook → Invocations");
  console.log("   → Look for recent webhook calls and their output\n");

  console.log("⚠️  IMPORTANT: Make sure you saved these in Supabase Vault:\n");
  console.log("   ✅ WHATSAPP_ACCESS_TOKEN = (the Webhook Access Token from Meta)");
  console.log("   ✅ WHATSAPP_PHONE_NUMBER_ID = 959037787303696");
  console.log("   ✅ OPENAI_API_KEY = (your OpenAI API key)\n");
})();
