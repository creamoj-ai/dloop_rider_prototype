const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGpkc2p0YW9tbXV0ZG1rb3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzIzOTcsImV4cCI6MjA3ODU0ODM5N30.WgOimZMgGBC58LkvIocdeJ3hHz7y0eLrfLY57VvAYKw';

fetch('https://imhjdsjtaommutdmkouf.supabase.co/rest/v1/whatsapp_messages?order=created_at.desc&limit=20', {
  headers: {
    'apikey': anonKey,
    'Content-Type': 'application/json'
  }
})
  .then(r => r.json())
  .then(data => {
    if (!Array.isArray(data)) {
      console.error('❌ Error:', data);
      return;
    }

    console.log('\n📊 Last 20 WhatsApp Messages:\n');
    console.log('─'.repeat(80));

    data.forEach((msg, i) => {
      console.log(`\n[${i+1}] Direction: ${msg.direction.toUpperCase()}`);
      console.log(`    Status: ${msg.status}`);
      console.log(`    Content: ${msg.content.substring(0, 60)}${msg.content.length > 60 ? '...' : ''}`);
      console.log(`    Time: ${msg.created_at}`);
    });

    console.log('\n' + '─'.repeat(80));
    console.log('\n📈 Summary:');
    const inbound = data.filter(m => m.direction === 'inbound').length;
    const outbound = data.filter(m => m.direction === 'outbound').length;
    const failed = data.filter(m => m.status === 'failed').length;

    console.log(`  Inbound: ${inbound}`);
    console.log(`  Outbound: ${outbound}`);
    console.log(`  Failed: ${failed}`);
  })
  .catch(e => console.error('Error:', e.message));
