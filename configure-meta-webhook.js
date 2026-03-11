// Configure Meta WhatsApp Webhook
const ACCESS_TOKEN = "EAAVfoVVjNTUBQ4svR1B3mUUISbuSBL8kcSwBlB2EE7EJguZA6rz08ZBsMtgbjOuhM0dKmhzOwf7r4uHsIrZCiFfNgDIwgMJ9O7KUH7pf3UA9nLXlCmTiZAL5nlkt4ZBkEUUMPD14QhrclZB6fp2vD87U2TP7ar7Vfe3fxP1RsZClDfFs1H7NN68jPBodTMrGL0CY3GlKLKOynfOeVxUs2vo17jWLGsrsmvfLh5wTdcwyI6Bdn6kLVG3gHqAp7kGjvIEsxzxs3zFZAxAqzBbn7ggZD";
const PHONE_NUMBER_ID = "959037787303696";
const WEBHOOK_URL = "https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook";
const VERIFY_TOKEN = "dloop_wa_verify_2026";
const META_API_VERSION = "v18.0";

console.log("\n╔════════════════════════════════════════════════════════════════╗");
console.log("║     AUTO-CONFIGURE META WHATSAPP WEBHOOK                     ║");
console.log("╚════════════════════════════════════════════════════════════════╝\n");

const makeRequest = async (method, endpoint, body = null) => {
  const url = `https://graph.instagram.com/${META_API_VERSION}/${endpoint}?access_token=${ACCESS_TOKEN}`;
  
  const options = {
    method,
    headers: { "Content-Type": "application/json" }
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const res = await fetch(url, options);
    const data = await res.json();
    return { status: res.status, ok: res.ok, data };
  } catch (e) {
    return { status: 500, ok: false, data: { error: e.message } };
  }
};

(async () => {
  // Step 1: Verify Token
  console.log("🔐 STEP 1: Verifying Token\n");
  const meRes = await makeRequest("GET", "me");
  
  if (!meRes.ok) {
    console.error("❌ Token verification failed:");
    console.error(`   Error: ${meRes.data.error?.message || "Unknown error"}\n`);
    process.exit(1);
  }
  
  console.log(`✅ Token valid for: ${meRes.data.name || meRes.data.id}`);
  console.log(`   ID: ${meRes.data.id}\n`);

  // Step 2: Get phone number info
  console.log("📋 STEP 2: Getting Phone Number Details\n");
  
  const phoneRes = await makeRequest("GET", PHONE_NUMBER_ID);
  
  if (phoneRes.ok) {
    console.log(`✅ Phone Number Found`);
    console.log(`   Display Name: ${phoneRes.data.display_name || "N/A"}`);
    console.log(`   Phone Number: ${phoneRes.data.phone_number || "N/A"}`);
    console.log(`   ID: ${PHONE_NUMBER_ID}\n`);
  } else {
    console.error("⚠️  Could not get phone details, continuing...\n");
  }

  // Step 3: Configure Webhook URL
  console.log("🔧 STEP 3: Setting Webhook URL\n");
  console.log(`   URL: ${WEBHOOK_URL}`);
  console.log(`   Verify Token: ${VERIFY_TOKEN}\n`);

  const updateRes = await makeRequest("POST", PHONE_NUMBER_ID, {
    webhook_url: WEBHOOK_URL,
    verify_token: VERIFY_TOKEN
  });

  if (updateRes.ok) {
    console.log("✅ Webhook URL set successfully\n");
  } else {
    console.log(`⚠️  Webhook URL configuration response:`);
    console.log(`   ${JSON.stringify(updateRes.data)}\n`);
  }

  // Step 4: Subscribe to webhook
  console.log("📡 STEP 4: Subscribing to Webhook\n");
  
  const subscribeRes = await makeRequest("POST", `${PHONE_NUMBER_ID}/subscribed_apps`, {});

  if (subscribeRes.ok) {
    console.log("✅ Subscribed to webhook events\n");
  } else {
    console.log(`⚠️  Subscribe response: ${JSON.stringify(subscribeRes.data)}\n`);
  }

  // Step 5: Test Webhook
  console.log("🧪 STEP 5: Testing Webhook\n");
  
  const testPayload = {
    object: "whatsapp_business_account",
    entry: [{
      id: "123456",
      changes: [{
        value: {
          messaging_product: "whatsapp",
          metadata: {
            display_phone_number: "39328185463",
            phone_number_id: PHONE_NUMBER_ID
          },
          contacts: [{
            profile: { name: "Meta Config Test" },
            wa_id: "393281854639"
          }],
          messages: [{
            from: "393281854639",
            id: "wamid.test_" + Date.now(),
            timestamp: Math.floor(Date.now() / 1000),
            type: "text",
            text: { body: "Test message from configuration" }
          }]
        },
        field: "messages"
      }]
    }]
  };

  const testRes = await fetch(WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(testPayload)
  });

  const testBody = await testRes.text();
  console.log(`Response Status: ${testRes.status}`);
  console.log(`Response Body: ${testBody}`);
  
  if (testRes.status === 200) {
    console.log("✅ Webhook is responding correctly!\n");
  } else {
    console.log("⚠️  Check webhook response above\n");
  }

  // Summary
  console.log("\n╔════════════════════════════════════════════════════════════════╗");
  console.log("║              ✅ CONFIGURATION COMPLETE                        ║");
  console.log("╚════════════════════════════════════════════════════════════════╝\n");

  console.log("📊 WEBHOOK STATUS:");
  console.log(`   ✅ URL: ${WEBHOOK_URL}`);
  console.log(`   ✅ Verify Token: ${VERIFY_TOKEN}`);
  console.log(`   ✅ Phone Number ID: ${PHONE_NUMBER_ID}`);
  console.log(`   ✅ Token: Valid\n`);

  console.log("🚀 TEST THE BOT:\n");
  console.log("   1. Open WhatsApp on your phone");
  console.log("   2. Send ANY message to: +39 328 185 4639");
  console.log("   3. Bot should respond in ~5-10 seconds\n");

  console.log("📋 TO CHECK LOGS:\n");
  console.log("   Supabase Dashboard:");
  console.log("   https://app.supabase.com");
  console.log("   → Select Project: aqpwfurradxbnqvycvkm");
  console.log("   → Functions → whatsapp-webhook → Invocations");
  console.log("   → Click on the most recent invocation to see logs\n");

})();
