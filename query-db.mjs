const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2');

const supabaseUrl = 'https://imhjdsjtaommutdmkouf.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGpkc2p0YW9tbXV0ZG1rb3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzIzOTcsImV4cCI6MjA3ODU0ODM5N30.WgOimZMgGBC58LkvIocdeJ3hHz7y0eLrfLY57VvAYKw';

const supabase = createClient(supabaseUrl, supabaseKey);

console.log('\n🔍 Checking WhatsApp Messages...\n');

const { data, error } = await supabase
  .from('whatsapp_messages')
  .select('*')
  .order('created_at', { ascending: false })
  .limit(20);

if (error) {
  console.error('❌ Error:', error.message);
} else if (!data || data.length === 0) {
  console.log('⚠️  No messages found in database!');
} else {
  console.log(`✅ Found ${data.length} messages:\n`);

  data.forEach((msg, i) => {
    console.log(`[${i+1}] ${msg.direction.toUpperCase()}`);
    console.log(`    Status: ${msg.status}`);
    console.log(`    Content: ${msg.content.substring(0, 80)}${msg.content.length > 80 ? '...' : ''}`);
    console.log(`    Time: ${msg.created_at}\n`);
  });

  const inbound = data.filter(m => m.direction === 'inbound').length;
  const outbound = data.filter(m => m.direction === 'outbound').length;
  const failed = data.filter(m => m.status === 'failed').length;

  console.log('─'.repeat(80));
  console.log(`📊 Summary: Inbound=${inbound}, Outbound=${outbound}, Failed=${failed}`);
}
