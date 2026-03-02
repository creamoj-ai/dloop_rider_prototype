const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGpkc2p0YW9tbXV0ZG1rb3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzIzOTcsImV4cCI6MjA3ODU0ODM5N30.WgOimZMgGBC58LkvIocdeJ3hHz7y0eLrfLY57VvAYKw';

console.log(`
╔════════════════════════════════════════════════════════════════╗
║            Send Test Message to WhatsApp Bot                  ║
║                  +39 328 1854639                               ║
╚════════════════════════════════════════════════════════════════╝

📱 Invia un messaggio WhatsApp a: +39 328 1854639
Esempi:
  - "Ciao, mi servono prodotti per il gatto"
  - "Vorrei ordinare"
  - "OK" (se sei un dealer)

Aspetta 10 secondi, poi premi Enter per verificare...
`);

setTimeout(() => {
  console.log('\n🔍 Verificando i messaggi nel database...\n');
  
  fetch('https://imhjdsjtaommutdmkouf.supabase.co/rest/v1/whatsapp_messages?order=created_at.desc&limit=5', {
    headers: {
      'apikey': anonKey,
      'Content-Type': 'application/json'
    }
  })
    .then(r => r.json())
    .then(data => {
      if (Array.isArray(data) && data.length > 0) {
        console.log('✅ Messaggi trovati!\n');
        data.forEach((msg, i) => {
          console.log(`[${i+1}] ${msg.direction.toUpperCase()}: "${msg.content.substring(0, 50)}"`);
          console.log(`    Status: ${msg.status} | Time: ${msg.created_at}\n`);
        });
      } else if (data.code === 'PGRST205') {
        console.log('⚠️  REST API cache non aggiornato ancora');
        console.log('   Vai a: Settings → API → Introspection');
        console.log('   Clicca il bottone di refresh 🔄');
      } else {
        console.log('❌ Nessun messaggio trovato');
        console.log('   Response:', data);
      }
    })
    .catch(e => console.error('Error:', e.message));
}, 10000);
