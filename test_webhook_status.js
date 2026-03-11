const WEBHOOK_URL = "https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook";
const VERIFY_TOKEN = "dloop_wa_verify_2026";

// Test 1: GET verification (should work)
console.log("🔍 TEST 1: GET Webhook Verification\n");
fetch(`${WEBHOOK_URL}?hub.verify_token=${VERIFY_TOKEN}&hub.challenge=test_challenge_123`)
  .then(r => {
    console.log(`Status: ${r.status}`);
    return r.text();
  })
  .then(text => {
    console.log(`Response: ${text}\n`);
    
    // Test 2: POST test
    console.log("🔍 TEST 2: POST Webhook (with test payload)\n");
    return fetch(WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        entry: [{
          changes: [{
            value: {
              messages: [{
                from: "393281854639",
                text: { body: "Test message" },
                id: "test_123"
              }],
              contacts: [{ profile: { name: "Test User" } }]
            }
          }]
        }]
      })
    });
  })
  .then(r => {
    console.log(`Status: ${r.status}`);
    return r.text();
  })
  .then(text => console.log(`Response: ${text}`))
  .catch(e => console.error("❌ Error:", e.message));
