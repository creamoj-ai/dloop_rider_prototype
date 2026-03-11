const TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxcHdmdXJyYWR4Ym5xdnljdmttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTk3NzAsImV4cCI6MjA4NTY5NTc3MH0.Ekhco06o8_88e8tQJHm4EjEa0HOQv8Z-gAHa1busvog";
const URL = "https://aqpwfurradxbnqvycvkm.supabase.co";

console.log("🔍 SUPABASE STATUS CHECK\n");
console.log("═══════════════════════════════════════════════════════════════");

// Test 1: Check tables existence
console.log("\n📋 TEST 1: Database Tables\n");

const tables = ["whatsapp_conversations", "whatsapp_messages", "whatsapp_order_relays"];

(async () => {
  for (const table of tables) {
    try {
      const res = await fetch(
        `${URL}/rest/v1/${table}?limit=1`,
        {
          headers: {
            "Authorization": `Bearer ${TOKEN}`,
            "Content-Type": "application/json",
            "Prefer": "count=exact"
          }
        }
      );
      
      console.log(`${table}: ${res.status === 200 ? "✅ EXISTS" : "❌ Error: " + res.status}`);
    } catch (e) {
      console.log(`${table}: ❌ ${e.message}`);
    }
  }
  
  // Test 2: Check recent messages
  console.log("\n\n📨 TEST 2: Recent WhatsApp Messages\n");
  
  try {
    const res = await fetch(
      `${URL}/rest/v1/whatsapp_messages?order=created_at.desc&limit=5`,
      {
        headers: {
          "Authorization": `Bearer ${TOKEN}`,
          "Content-Type": "application/json"
        }
      }
    );
    
    if (res.ok) {
      const messages = await res.json();
      if (messages.length > 0) {
        console.log(`Found ${messages.length} recent messages:\n`);
        messages.forEach((msg, i) => {
          console.log(`${i+1}. From: ${msg.phone}`);
          console.log(`   Direction: ${msg.direction}`);
          console.log(`   Content: "${msg.content?.substring(0, 60)}${msg.content?.length > 60 ? "..." : ""}"`);
          console.log(`   Status: ${msg.status}`);
          console.log(`   Time: ${new Date(msg.created_at).toLocaleString()}\n`);
        });
      } else {
        console.log("No messages found yet.");
      }
    } else {
      console.log(`Error: ${res.status}`);
    }
  } catch (e) {
    console.log(`Error: ${e.message}`);
  }
  
  // Test 3: Check conversations
  console.log("\n📞 TEST 3: Active Conversations\n");
  
  try {
    const res = await fetch(
      `${URL}/rest/v1/whatsapp_conversations?order=last_message_at.desc&limit=5`,
      {
        headers: {
          "Authorization": `Bearer ${TOKEN}`,
          "Content-Type": "application/json"
        }
      }
    );
    
    if (res.ok) {
      const convs = await res.json();
      if (convs.length > 0) {
        console.log(`Found ${convs.length} conversations:\n`);
        convs.forEach((conv, i) => {
          console.log(`${i+1}. Phone: ${conv.phone}`);
          console.log(`   Name: ${conv.customer_name || "Unknown"}`);
          console.log(`   Type: ${conv.conversation_type}`);
          console.log(`   Last message: ${new Date(conv.last_message_at).toLocaleString()}\n`);
        });
      } else {
        console.log("No conversations found yet.");
      }
    } else {
      console.log(`Error: ${res.status}`);
    }
  } catch (e) {
    console.log(`Error: ${e.message}`);
  }
  
  console.log("\n═══════════════════════════════════════════════════════════════");
  console.log("\n💡 To check Edge Function logs:");
  console.log("   1. Go to: https://app.supabase.com");
  console.log("   2. Project: aqpwfurradxbnqvycvkm");
  console.log("   3. Menu: Functions > whatsapp-webhook > Logs");
  console.log("   4. Look for errors about OPENAI_API_KEY or WHATSAPP_ACCESS_TOKEN\n");
})();
