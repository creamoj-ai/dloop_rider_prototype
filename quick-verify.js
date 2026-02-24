const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGpkc2p0YW9tbXV0ZG1rb3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzIzOTcsImV4cCI6MjA3ODU0ODM5N30.WgOimZMgGBC58LkvIocdeJ3hHz7y0eLrfLY57VvAYKw';

// Try to insert test record - if table exists, insert will work
fetch('https://imhjdsjtaommutdmkouf.supabase.co/rest/v1/whatsapp_conversations', {
  method: 'POST',
  headers: {
    'apikey': anonKey,
    'Authorization': `Bearer ${anonKey}`,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  },
  body: JSON.stringify({
    phone: '+39 TEST 0000000',
    customer_name: 'Test',
    conversation_type: 'customer'
  })
})
  .then(r => r.json())
  .then(data => {
    if (data[0]?.id) {
      console.log('✅ whatsapp_conversations table EXISTS and is accessible!');
      console.log(`   Created test record: ${data[0].id}`);
      
      // Delete test record
      fetch(`https://imhjdsjtaommutdmkouf.supabase.co/rest/v1/whatsapp_conversations?id=eq.${data[0].id}`, {
        method: 'DELETE',
        headers: {
          'apikey': anonKey,
          'Authorization': `Bearer ${anonKey}`,
        }
      }).then(() => console.log('   Cleaned up test record'));
    } else if (data.message?.includes('does not exist')) {
      console.log('❌ Table does not exist');
      console.log('   Response:', data.message);
    } else {
      console.log('Response:', data);
    }
  })
  .catch(e => console.error('Error:', e.message));
