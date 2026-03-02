const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGpkc2p0YW9tbXV0ZG1rb3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzIzOTcsImV4cCI6MjA3ODU0ODM5N30.WgOimZMgGBC58LkvIocdeJ3hHz7y0eLrfLY57VvAYKw';
const supabaseUrl = 'https://imhjdsjtaommutdmkouf.supabase.co';

console.log('🔍 Verifying WhatsApp tables exist in database...\n');

const query = `
SELECT tablename
FROM pg_catalog.pg_tables
WHERE schemaname = 'public'
AND tablename LIKE 'whatsapp%'
ORDER BY tablename;
`;

fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql?sql=${encodeURIComponent(query)}`, {
  method: 'GET',
  headers: {
    'apikey': anonKey,
    'Authorization': `Bearer ${anonKey}`,
  }
})
  .then(r => r.json())
  .then(data => {
    console.log('Response:', data);
    if (Array.isArray(data) && data.length > 0) {
      console.log('✅ Tables found:');
      data.forEach(row => console.log(`   - ${row.tablename}`));
    } else {
      console.log('❌ No tables found');
    }
  })
  .catch(e => console.error('Error:', e.message));
