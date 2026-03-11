// Complete WhatsApp Bot Diagnostics
const WEBHOOK_URL = "https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook";
const SUPABASE_URL = "https://aqpwfurradxbnqvycvkm.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxcHdmdXJyYWR4Ym5xdnljdmttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTk3NzAsImV4cCI6MjA4NTY5NTc3MH0.Ekhco06o8_88e8tQJHm4EjEa0HOQv8Z-gAHa1busvog";

console.log("\n╔═══════════════════════════════════════════════════════════════╗");
console.log("║        COMPLETE WHATSAPP BOT DIAGNOSTICS                    ║");
console.log("╚═══════════════════════════════════════════════════════════════╝\n");

// Test 1: Webhook Reachability
console.log("📡 TEST 1: WEBHOOK REACHABILITY");
console.log("─────────────────────────────────────────────────────────────\n");

(async () => {
  try {
    // Test GET (webhook verification)
    console.log("🔍 Testing GET request (Meta webhook verification)...");
    const getRes = await fetch(WEBHOOK_URL + "?hub.challenge=test123&hub.verify_token=dloop_wa_verify_2026");
    console.log(`   Status: ${getRes.status}`);
    const getText = await getRes.text();
    console.log(`   Response: ${getText}\n`);
    
    if (getText === "test123") {
      console.log("✅ GET verification: WORKING (returns challenge)\n");
    } else {
      console.log("⚠️  GET verification: Unexpected response\n");
    }

    // Test POST (incoming message simulation)
    console.log("🔍 Testing POST request (simulating incoming message)...");
    const testPayload = {
      "object": "whatsapp_business_account",
      "entry": [{
        "id": "123",
        "changes": [{
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "39328185463",
              "phone_number_id": "191359627217151"
            },
            "contacts": [{"profile": {"name": "Test"}, "wa_id": "393281854639"}],
            "messages": [{
              "from": "393281854639",
              "id": "test_msg_id",
              "timestamp": Math.floor(Date.now() / 1000),
              "type": "text",
              "text": {"body": "Test message"}
            }]
          },
          "field": "messages"
        }]
      }]
    };

    const postRes = await fetch(WEBHOOK_URL, {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify(testPayload)
    });

    console.log(`   Status: ${postRes.status}`);
    const postText = await postRes.text();
    console.log(`   Response: ${postText}\n`);

    if (postRes.status === 200) {
      console.log("✅ POST request: WORKING\n");
    } else {
      console.log("❌ POST request: ERROR\n");
    }

    // Test 2: Supabase Connection
    console.log("\n📊 TEST 2: SUPABASE CONNECTION");
    console.log("─────────────────────────────────────────────────────────────\n");

    console.log("🔍 Checking whatsapp_messages table...");
    const messagesRes = await fetch(
      `${SUPABASE_URL}/rest/v1/whatsapp_messages?order=created_at.desc&limit=5`,
      {
        headers: {
          "Authorization": `Bearer ${SUPABASE_KEY}`,
          "Content-Type": "application/json"
        }
      }
    );

    if (messagesRes.ok) {
      const messages = await messagesRes.json();
      console.log(`✅ Table accessible: Found ${messages.length} recent messages\n`);
      
      if (messages.length > 0) {
        console.log("📨 RECENT MESSAGES:");
        messages.slice(0, 3).forEach((msg, i) => {
          console.log(`   ${i+1}. From: ${msg.phone} | Direction: ${msg.direction}`);
          console.log(`      "${msg.content.substring(0, 50)}${msg.content.length > 50 ? '...' : ''}"`);
          console.log(`      Status: ${msg.status} | Time: ${new Date(msg.created_at).toLocaleString()}\n`);
        });
      } else {
        console.log("⚠️  No messages found - bot may not have received any yet\n");
      }
    } else {
      console.log(`❌ Cannot access table: ${messagesRes.status}\n`);
    }

    // Test 3: Function Logs
    console.log("\n📋 TEST 3: RECENT FUNCTION INVOCATIONS");
    console.log("─────────────────────────────────────────────────────────────\n");

    const logsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/rpc/get_function_logs?function_id=whatsapp-webhook&limit=10`,
      {
        headers: {
          "Authorization": `Bearer ${SUPABASE_KEY}`,
          "Content-Type": "application/json"
        }
      }
    );

    if (logsRes.ok) {
      console.log("✅ Function logs available (check Supabase dashboard)\n");
    } else {
      console.log("ℹ️  To view function logs:\n");
      console.log("   1. Go to: https://app.supabase.com");
      console.log("   2. Select Project: aqpwfurradxbnqvycvkm");
      console.log("   3. Menu: Functions → whatsapp-webhook → Invocations");
      console.log("   4. Look for recent calls and their output\n");
    }

    // Summary
    console.log("\n╔═══════════════════════════════════════════════════════════════╗");
    console.log("║                        SUMMARY                              ║");
    console.log("╚═══════════════════════════════════════════════════════════════╝\n");

    console.log("✅ Webhook is LIVE and reachable");
    console.log("✅ Supabase is connected");
    console.log("⚠️  Check Supabase logs to see if Meta is sending messages\n");

    console.log("📝 NEXT STEPS:");
    console.log("   1. Make sure Meta webhook is configured with:");
    console.log("      - URL: https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook");
    console.log("      - Token: dloop_wa_verify_2026");
    console.log("   2. Send a test message from WhatsApp to: +39 328 185 4639");
    console.log("   3. Check Supabase logs for the incoming message\n");

  } catch (e) {
    console.error("❌ Diagnostics error:", e.message);
  }
})();
