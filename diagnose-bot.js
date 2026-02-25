/**
 * WhatsApp Bot MVP - Comprehensive Diagnostics
 * Checks webhook, database, and message flows programmatically
 */

const anonKey = 'sb_publishable_NBWU-byCV0TIsj5-8Mixog_CEV7IkrB';
const supabaseUrl = 'https://aqpwfurradxbnqvycvkm.supabase.co';
const projectRef = 'aqpwfurradxbnqvycvkm';

console.log(`
╔════════════════════════════════════════════════════════════════╗
║       WhatsApp Bot MVP - Diagnostic Report                     ║
║              Dloop Rider Prototype                              ║
╚════════════════════════════════════════════════════════════════╝
`);

// ============================================================================
// 1. CHECK DATABASE CONNECTIVITY
// ============================================================================
async function checkDatabaseConnectivity() {
  console.log('\n📊 [1] Testing Database Connectivity...\n');
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/whatsapp_conversations?limit=1`, {
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json'
      }
    });

    const text = await res.text();

    if (res.ok) {
      console.log('✅ Database connectivity: OK');
      return true;
    } else {
      console.log(`❌ Database connectivity failed: ${res.status} ${res.statusText}`);
      console.log(`   Response: ${text.substring(0, 100)}`);
      return false;
    }
  } catch (e) {
    console.log(`❌ Database connectivity error: ${e.message}`);
    return false;
  }
}

// ============================================================================
// 2. CHECK INBOUND MESSAGES (from last 20 minutes)
// ============================================================================
async function checkInboundMessages() {
  console.log('\n📬 [2] Recent Inbound Messages (last 20 minutes)...\n');
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/whatsapp_messages?direction=eq.inbound&order=created_at.desc&limit=20`,
      {
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json'
        }
      }
    );

    const data = await res.json();

    if (!Array.isArray(data)) {
      console.log(`❌ Error querying inbound messages:`, data);
      return null;
    }

    if (data.length === 0) {
      console.log('❌ No inbound messages found in database');
      console.log('   → This means Meta is NOT sending messages to the webhook');
      return { count: 0, messages: [] };
    }

    console.log(`✅ Found ${data.length} inbound messages`);

    // Filter messages from last 20 minutes
    const now = new Date();
    const twentyMinutesAgo = new Date(now.getTime() - 20 * 60000);
    const recentMessages = data.filter(m => new Date(m.created_at) > twentyMinutesAgo);

    if (recentMessages.length > 0) {
      console.log(`\n   Recent messages (last 20 min): ${recentMessages.length}`);
      recentMessages.forEach((msg, i) => {
        console.log(`   [${i+1}] "${msg.content.substring(0, 40)}${msg.content.length > 40 ? '...' : ''}" - ${msg.phone} (${msg.created_at})`);
      });
    }

    return { count: data.length, messages: data, recentCount: recentMessages.length };
  } catch (e) {
    console.log(`❌ Error: ${e.message}`);
    return null;
  }
}

// ============================================================================
// 3. CHECK OUTBOUND MESSAGES (responses sent)
// ============================================================================
async function checkOutboundMessages() {
  console.log('\n📤 [3] Recent Outbound Messages (responses)...\n');
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/whatsapp_messages?direction=eq.outbound&order=created_at.desc&limit=20`,
      {
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json'
        }
      }
    );

    const data = await res.json();

    if (!Array.isArray(data)) {
      console.log(`❌ Error querying outbound messages:`, data);
      return null;
    }

    if (data.length === 0) {
      console.log('❌ No outbound messages found - bot is NOT sending responses');
      return { count: 0, messages: [], failedCount: 0 };
    }

    console.log(`✅ Found ${data.length} outbound messages`);

    const failed = data.filter(m => m.status === 'failed');
    const sent = data.filter(m => m.status === 'sent');
    const delivered = data.filter(m => m.status === 'delivered');
    const read = data.filter(m => m.status === 'read');

    console.log(`   Status breakdown:`);
    console.log(`   - ✅ Sent: ${sent.length}`);
    console.log(`   - 📦 Delivered: ${delivered.length}`);
    console.log(`   - 👁️  Read: ${read.length}`);
    console.log(`   - ❌ Failed: ${failed.length}`);

    if (failed.length > 0) {
      console.log(`\n   Failed messages:`);
      failed.slice(0, 5).forEach((msg, i) => {
        console.log(`   [${i+1}] "${msg.content.substring(0, 40)}..." to ${msg.phone}`);
        if (msg.meta_response) {
          console.log(`        Error: ${msg.meta_response.substring(0, 80)}`);
        }
      });
    }

    return { count: data.length, messages: data, failedCount: failed.length };
  } catch (e) {
    console.log(`❌ Error: ${e.message}`);
    return null;
  }
}

// ============================================================================
// 4. CHECK CONVERSATIONS
// ============================================================================
async function checkConversations() {
  console.log('\n💬 [4] Active Conversations...\n');
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/whatsapp_conversations?order=updated_at.desc&limit=10`,
      {
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json'
        }
      }
    );

    const data = await res.json();

    if (!Array.isArray(data)) {
      console.log(`❌ Error querying conversations:`, data);
      return null;
    }

    if (data.length === 0) {
      console.log('❌ No conversations found - webhook is NOT creating conversations');
      return { count: 0 };
    }

    console.log(`✅ Found ${data.length} conversations`);
    data.slice(0, 5).forEach((conv, i) => {
      console.log(`   [${i+1}] ${conv.phone} - Type: ${conv.conversation_type} (${conv.message_count} messages)`);
    });

    return { count: data.length, conversations: data };
  } catch (e) {
    console.log(`❌ Error: ${e.message}`);
    return null;
  }
}

// ============================================================================
// 5. CHECK WEBHOOK ENDPOINT
// ============================================================================
async function checkWebhookEndpoint() {
  console.log('\n🪝 [5] Testing Webhook Endpoint...\n');

  const webhookUrl = 'https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook';
  const verifyToken = 'dloop_wa_verify_2026';

  try {
    // Test GET verification request
    const verifyUrl = `${webhookUrl}?hub.mode=subscribe&hub.verify_token=${verifyToken}&hub.challenge=test123`;
    const getRes = await fetch(verifyUrl);
    const getText = await getRes.text();

    if (getText === 'test123') {
      console.log('✅ Webhook verification endpoint: WORKING');
      console.log(`   Response: "${getText}"`);
    } else {
      console.log(`❌ Webhook verification endpoint: FAILED`);
      console.log(`   Expected: "test123", Got: "${getText}"`);
    }

    // Test endpoint availability
    console.log(`✅ Webhook URL is reachable: ${webhookUrl}`);

    return true;
  } catch (e) {
    console.log(`❌ Webhook endpoint error: ${e.message}`);
    return false;
  }
}

// ============================================================================
// 6. CHECK RIDER CONTACTS (dealer routing)
// ============================================================================
async function checkRiderContacts() {
  console.log('\n👥 [6] Dealer Contacts (for routing)...\n');
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/rider_contacts?contact_type=eq.whatsapp&limit=30`,
      {
        headers: {
          'apikey': anonKey,
          'Content-Type': 'application/json'
        }
      }
    );

    const data = await res.json();

    if (!Array.isArray(data)) {
      console.log(`❌ Error querying contacts:`, data);
      return null;
    }

    console.log(`✅ Found ${data.length} WhatsApp dealer contacts`);
    console.log('\n   Dealers:');
    data.slice(0, 10).forEach((contact, i) => {
      console.log(`   [${i+1}] ${contact.contact_value} - ${contact.rider_id ? '✅ Rider' : '⚠️  No rider'}`);
    });

    return { count: data.length, contacts: data };
  } catch (e) {
    console.log(`❌ Error: ${e.message}`);
    return null;
  }
}

// ============================================================================
// 7. DIAGNOSTIC SUMMARY & RECOMMENDATIONS
// ============================================================================
async function generateReport() {
  console.log('\n📋 [7] Diagnostic Summary...\n');

  const dbOk = await checkDatabaseConnectivity();
  if (!dbOk) {
    console.log('\n❌ FATAL: Database not accessible. Cannot proceed.');
    return;
  }

  const inbound = await checkInboundMessages();
  const outbound = await checkOutboundMessages();
  const conversations = await checkConversations();
  const webhook = await checkWebhookEndpoint();
  const contacts = await checkRiderContacts();

  console.log('\n' + '═'.repeat(80));
  console.log('📊 ANALYSIS\n');

  if (inbound?.recentCount === 0) {
    console.log('❌ ISSUE: No recent inbound messages from Meta');
    console.log('\n   ROOT CAUSE OPTIONS:');
    console.log('   1. Meta webhook is not configured correctly in Business Account');
    console.log('   2. Bot phone number is not receiving messages');
    console.log('   3. Meta is not sending POST requests to webhook URL');
    console.log('\n   ACTION ITEMS:');
    console.log('   - Check Meta Business Account → WhatsApp API Setup');
    console.log('   - Verify webhook URL: https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook');
    console.log('   - Verify verify_token: dloop_wa_verify_2026');
    console.log('   - Check phone number is properly linked: +39 328 1854639');
  } else if (inbound?.count > 0 && outbound?.count === 0) {
    console.log('⚠️  ISSUE: Inbound messages received but NO outbound responses');
    console.log('\n   ROOT CAUSE OPTIONS:');
    console.log('   1. ChatGPT function calling is failing');
    console.log('   2. WhatsApp token is invalid or expired');
    console.log('   3. Phone ID is incorrect');
    console.log('\n   ACTION ITEMS:');
    console.log('   - Check Supabase function logs for errors');
    console.log('   - Verify WHATSAPP_ACCESS_TOKEN in secrets');
    console.log('   - Verify WHATSAPP_PHONE_NUMBER_ID in secrets');
  } else if (outbound?.failedCount > 0) {
    console.log('⚠️  ISSUE: Outbound messages failing');
    console.log('\n   ROOT CAUSE: WhatsApp API errors (likely auth or quota)');
    console.log('\n   ACTION ITEMS:');
    console.log('   - Check WhatsApp token expiry');
    console.log('   - Verify Meta payment method is valid');
    console.log('   - Check API quota/rate limits');
  } else if (conversations?.count === 0) {
    console.log('❌ ISSUE: No conversations in database');
    console.log('\n   ROOT CAUSE: Webhook is not processing messages');
    console.log('\n   ACTION ITEMS:');
    console.log('   - Check Supabase Edge Function logs');
    console.log('   - Verify function is deployed');
    console.log('   - Check environment variables are set');
  } else if (inbound?.count > 0 && outbound?.count > 0) {
    console.log('✅ SYSTEM APPEARS TO BE WORKING');
    console.log(`\n   Inbound messages: ${inbound.count}`);
    console.log(`   Outbound responses: ${outbound.count}`);
    console.log(`   Conversations: ${conversations?.count || 0}`);
  }

  console.log('\n' + '═'.repeat(80));
  console.log('\n🔍 NEXT DIAGNOSTIC STEPS:\n');
  console.log('1. Check Supabase function logs:');
  console.log('   https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/functions');
  console.log('\n2. Run database query for recent messages:');
  console.log(`   SELECT * FROM whatsapp_messages WHERE created_at > NOW() - INTERVAL '30 minutes' ORDER BY created_at DESC;`);
  console.log('\n3. Verify webhook is receiving POST requests from Meta');
  console.log('4. Test ChatGPT integration directly');
  console.log('5. Verify WhatsApp API token in Meta Business Account\n');
}

// ============================================================================
// RUN ALL DIAGNOSTICS
// ============================================================================
(async () => {
  try {
    await generateReport();
    console.log('\n✅ Diagnostic complete!\n');
  } catch (e) {
    console.error('❌ Diagnostic error:', e.message);
  }
})();
