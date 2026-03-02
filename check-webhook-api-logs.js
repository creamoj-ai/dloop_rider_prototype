const supabaseUrl = 'https://aqpwfurradxbnqvycvkm.supabase.co';
const anonKey = 'sb_publishable_NBWU-byCV0TIsj5-8Mixog_CEV7IkrB';

console.log(`
╔════════════════════════════════════════════════════════════════╗
║         Fetching WhatsApp Webhook Logs via API                 ║
╚════════════════════════════════════════════════════════════════╝
`);

// Try to get function invocation logs
fetch(`${supabaseUrl}/rest/v1/rpc/get_function_logs`, {
  method: 'POST',
  headers: {
    'apikey': anonKey,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    function_name: 'whatsapp-webhook',
    limit: 20
  })
})
  .then(r => r.json())
  .then(data => {
    console.log('📊 Function Logs:\n');
    console.log(JSON.stringify(data, null, 2));
  })
  .catch(e => {
    console.log('⚠️  Direct logs endpoint not available');
    console.log('Trying alternative...\n');
    
    // Try alternative: get from function invocations
    fetch(`${supabaseUrl}/rest/v1/function_invocations?limit=5&order=timestamp.desc`, {
      headers: {
        'apikey': anonKey,
        'Authorization': `Bearer ${anonKey}`,
      }
    })
      .then(r => r.json())
      .then(data => {
        console.log('Recent Invocations:\n');
        if (Array.isArray(data)) {
          data.forEach((inv, i) => {
            console.log(`[${i+1}] ${inv.method} ${inv.timestamp}`);
            console.log(`    Status: ${inv.status || 'unknown'}`);
            if (inv.error) console.log(`    Error: ${inv.error}`);
          });
        } else {
          console.log('Response:', data);
        }
      });
  });
