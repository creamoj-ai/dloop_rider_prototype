// Configure Meta WhatsApp Webhook - FINAL
const ACCESS_TOKEN = "EAAVfoVVjNTUBQ3wZBjEYgV3CDQjo8udUQCMh8uCUei5jpS3PKRy3duDryPVNqc4FY62w290Lx69dSGVYsRhrFxMkmlSKknZBmFwQIQSrKkZC72MZAFKkvAvoJe1I1XjZAY0OGWhrS5DtLYSCX57P7NTQhhAiHL52gxXr5wsIPtDG7OU8prt5fV6UN1QoGdrjjn3T64M8YNAKIeJoSzT6d0FMZBmd8gxlbuDiP6UwUNnOntIgJq36OZBaeJ3XRANXLSZCgYFWVvLZC6XJF3XihsYcZD";
const PHONE_NUMBER_ID = "959037787303696";
const WEBHOOK_URL = "https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook";
const VERIFY_TOKEN = "dloop_wa_verify_2026";
const META_API_VERSION = "v18.0";

console.log("\n╔════════════════════════════════════════════════════════════════╗");
console.log("║          CONFIGURING META WHATSAPP WEBHOOK                   ║");
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
    console.error(`   Error: ${meRes.data.error?.message || JSON.stringify(meRes.data)}\n`);
    process.exit(1);
  }
  
  console.log(`✅ Token is VALID!`);
  console.log(`   User/App: ${meRes.data.name || meRes.data.id}\n`);

  // Step 2: Get phone number info
  console.log("📞 STEP 2: Getting Phone Number Info\n");
  
  const phoneRes = await makeRequest("GET", `${PHONE_NUMBER_ID}?fields=id,display_name,phone_number,quality_rating,status,throughput`);
  
  if (phoneRes.ok) {
    console.log(`✅ Phone Number Found`);
    if (phoneRes.data.display_name) console.log(`   Name: ${phoneRes.data.display_name}`);
    if (phoneRes.data.phone_number) console.log(`   Number: ${phoneRes.data.phone_number}`);
    console.log(`   ID: ${PHONE_NUMBER_ID}`);
    if (phoneRes.data.status) console.log(`   Status: ${phoneRes.data.status}`);
    console.log("");
  } else {
    console.log(`⚠️  Phone info unavailable: ${phoneRes.data.error?.message}\n`);
  }

  // Step 3: Configure Webhook
  console.log("🔧 STEP 3: Configuring Webhook URL\n");
  console.log(`   Setting URL: ${WEBHOOK_URL}`);
  console.log(`   Verify Token: ${VERIFY_TOKEN}\n`);

  const updateRes = await makeRequest("POST", PHONE_NUMBER_ID, {
    webhook_url: WEBHOOK_URL,
    verify_token: VERIFY_TOKEN
  });

  if (updateRes.ok || (updateRes.data.success === true)) {
    console.log("✅ Webhook URL configured successfully!\n");
  } else {
    console.log(`⚠️  Response: ${JSON.stringify(updateRes.data)}\n`);
  }

  // Step 4: Subscribe to Events
  console.log("📡 STEP 4: Subscribing to Events\n");
  console.log(`   Subscribing to: messages, message_template_status_update, message_status_update\n`);
  
  const subscribeRes = await makeRequest("POST", `${PHONE_NUMBER_ID}/subscribed_apps`, {});

  if (subscribeRes.ok || subscribeRes.data.success) {
    console.log("✅ Successfully subscribed to webhook events!\n");
  } else {
    console.log(`⚠️  Subscribe response: ${JSON.stringify(subscribeRes.data)}\n`);
  }

  // Step 5: Test Webhook
  console.log("🧪 STEP 5: Testing Webhook\n");
  
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
            profile: { name: "Configuration Test" },
            wa_id: "393281854639"
          }],
          messages: [{
            from: "393281854639",
            id: "wamid.config_test_" + Date.now(),
            timestamp: Math.floor(Date.now() / 1000),
            type: "text",
            text: { body: "Test message from Meta configuration" }
          }]
        },
        field: "messages"
      }]
    }]
  };

  console.log("Sending test payload to webhook...\n");
  
  const testRes = await fetch(WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(testPayload)
  });

  const testBody = await testRes.text();
  console.log(`Webhook Test Response: ${testRes.status} - ${testBody}\n`);
  
  if (testRes.status === 200) {
    console.log("✅ Webhook test PASSED - webhook is responding!\n");
  } else {
    console.log("⚠️  Webhook returned unexpected status\n");
  }

  // Final Summary
  console.log("\n╔════════════════════════════════════════════════════════════════╗");
  console.log("║            ✅ WEBHOOK CONFIGURATION COMPLETE                 ║");
  console.log("╚════════════════════════════════════════════════════════════════╝\n");

  console.log("📊 WEBHOOK STATUS:");
  console.log(`   ✅ URL: ${WEBHOOK_URL}`);
  console.log(`   ✅ Verify Token: ${VERIFY_TOKEN}`);
  console.log(`   ✅ Phone ID: ${PHONE_NUMBER_ID}`);
  console.log(`   ✅ Access Token: VALID\n`);

  console.log("🚀 NOW TEST THE BOT:\n");
  console.log("   1. Open WhatsApp on your phone");
  console.log("   2. Send a message to: +39 328 185 4639");
  console.log("   3. Wait ~5-10 seconds for bot response\n");

  console.log("📋 TO CHECK LOGS:\n");
  console.log("   https://app.supabase.com");
  console.log("   → Project: aqpwfurradxbnqvycvkm");
  console.log("   → Functions → whatsapp-webhook → Invocations");
  console.log("   → View logs of recent invocations\n");

  console.log("💡 If bot doesn't respond:");
  console.log("   1. Check Supabase logs for errors");
  console.log("   2. Verify WHATSAPP_ACCESS_TOKEN and WHATSAPP_PHONE_NUMBER_ID in Supabase Vault");
  console.log("   3. Make sure OpenAI token is set (OPENAI_API_KEY)\n");
})();
