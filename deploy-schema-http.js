/**
 * Deploy WhatsApp Bot Schema via Supabase REST API
 * Uses HTTP requests to execute SQL
 */

const fs = require('fs');
const path = require('path');

const supabaseUrl = 'https://imhjdsjtaommutdmkouf.supabase.co';
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!serviceRoleKey) {
  console.error(`
╔════════════════════════════════════════════════════════════════╗
║          SUPABASE_SERVICE_ROLE_KEY required                    ║
╚════════════════════════════════════════════════════════════════╝

To get your service role key:

1. Go to Dashboard:
   https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/settings/api

2. Find "Service role secret" (scroll down in API section)

3. Click "Reveal" and copy the full key

4. Run this command (Windows PowerShell):
   $env:SUPABASE_SERVICE_ROLE_KEY="your_key_here"
   node deploy-schema-http.js

   OR (Windows Command Prompt):
   set SUPABASE_SERVICE_ROLE_KEY=your_key_here
   node deploy-schema-http.js

   OR (Mac/Linux):
   export SUPABASE_SERVICE_ROLE_KEY="your_key_here"
   node deploy-schema-http.js

Your key will look like: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSI...
  `);
  process.exit(1);
}

console.log(`
╔════════════════════════════════════════════════════════════════╗
║       Deploying WhatsApp Bot Schema to Supabase                ║
║                  Using REST API                                ║
╚════════════════════════════════════════════════════════════════╝
`);

async function executeSql(sql) {
  const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${serviceRoleKey}`,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    },
    body: JSON.stringify({ sql_command: sql }),
  });

  return response.json();
}

async function deploySchema() {
  try {
    console.log('📊 Reading SQL schema file...\n');
    const sqlPath = path.join(process.cwd(), 'sql', '42_create_whatsapp_bot_schema.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf-8');

    // Read the entire schema as one block
    const fullSql = sqlContent
      .split('\n')
      .filter(line => !line.trim().startsWith('--') && line.trim().length > 0)
      .join('\n');

    console.log('Executing complete schema...\n');

    const result = await executeSql(fullSql);

    if (result.error) {
      console.error('❌ Error:', result.error);
      console.error('Details:', result.message || result.details);
    } else {
      console.log('✅ Schema deployed successfully!\n');
      console.log('Tables created:');
      console.log('   ✅ whatsapp_conversations');
      console.log('   ✅ whatsapp_messages');
      console.log('   ✅ whatsapp_order_relays\n');
    }

    console.log(`
Next steps:
1. Run: node diagnose-bot.js
2. Send test message to: +39 328 1854639
3. Run: node check-messages.js
    `);

  } catch (error) {
    console.error('❌ Deployment failed:', error.message);
    process.exit(1);
  }
}

deploySchema();
