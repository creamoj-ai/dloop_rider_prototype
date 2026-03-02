const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGpkc2p0YW9tbXV0ZG1rb3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzIzOTcsImV4cCI6MjA3ODU0ODM5N30.WgOimZMgGBC58LkvIocdeJ3hHz7y0eLrfLY57VvAYKw';

console.log('Testing webhook with authorization header...\n');

fetch('https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook?hub.mode=subscribe&hub.verify_token=dloop_wa_verify_2026&hub.challenge=test123', {
  headers: {
    'Authorization': `Bearer ${anonKey}`
  }
})
  .then(r => r.text())
  .then(t => {
    console.log('✅ Response:', t);
    if (t === 'test123') {
      console.log('\n🎉 WEBHOOK IS WORKING! Meta can verify it!');
    }
  })
  .catch(e => console.error('❌ Error:', e.message));
