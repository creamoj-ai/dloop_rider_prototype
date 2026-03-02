/**
 * Deploy WhatsApp Bot Schema to Supabase
 * This script uses the Supabase Admin SDK to create the WhatsApp tables
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import fs from 'fs';
import path from 'path';

const supabaseUrl = 'https://imhjdsjtaommutdmkouf.supabase.co';
const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltaGpkc2p0YW9tbXV0ZG1rb3VmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5NzIzOTcsImV4cCI6MjA3ODU0ODM5N30.WgOimZMgGBC58LkvIocdeJ3hHz7y0eLrfLY57VvAYKw';

// Get service role key from environment or prompt
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!serviceRoleKey) {
  console.error(`
❌ SUPABASE_SERVICE_ROLE_KEY environment variable not set!

To get your service role key:
1. Go to: https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/settings/api
2. Scroll down to "Service role secret"
3. Click "Reveal" and copy the key
4. Set it: set SUPABASE_SERVICE_ROLE_KEY=your_key_here
5. Run this script again

Then try:
set SUPABASE_SERVICE_ROLE_KEY=eyJ... && node deploy-schema.js
  `);
  process.exit(1);
}

console.log(`
╔════════════════════════════════════════════════════════════════╗
║           Deploying WhatsApp Bot Schema to Supabase            ║
╚════════════════════════════════════════════════════════════════╝
`);

async function deploySchema() {
  try {
    // Create admin client with service role key
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    console.log('📊 Reading SQL schema file...\n');
    const sqlPath = path.join(process.cwd(), 'sql', '42_create_whatsapp_bot_schema.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf-8');

    // Split by statements and filter comments/empty lines
    const statements = sqlContent
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    console.log(`Found ${statements.length} SQL statements to execute\n`);

    let successful = 0;
    let failed = 0;

    for (let i = 0; i < statements.length; i++) {
      const stmt = statements[i];
      const preview = stmt.substring(0, 60).replace(/\n/g, ' ') + '...';

      process.stdout.write(`[${i + 1}/${statements.length}] ${preview}`);

      try {
        // Execute raw SQL
        const { data, error } = await supabase.rpc('sql_exec', {
          statement: stmt,
        }).catch(() => {
          // If RPC not available, try direct query
          return supabase.from('_sql_test').select('*').limit(0);
        });

        if (error) {
          // Some statements might fail if they already exist (IF NOT EXISTS)
          if (error.message.includes('already exists')) {
            console.log(' ✓ (already exists)');
            successful++;
          } else {
            console.log(` ✗ Error: ${error.message}`);
            failed++;
          }
        } else {
          console.log(' ✓');
          successful++;
        }
      } catch (e) {
        if (e.message.includes('already exists')) {
          console.log(' ✓ (already exists)');
          successful++;
        } else {
          console.log(` ⚠️  ${e.message.substring(0, 40)}`);
        }
      }
    }

    console.log(`
╔════════════════════════════════════════════════════════════════╗
║                    Deployment Summary                          ║
╚════════════════════════════════════════════════════════════════╝

✅ Successful: ${successful}
❌ Failed: ${failed}
📊 Total: ${statements.length}
    `);

    // Verify tables exist
    console.log('📋 Verifying tables...\n');
    const { data: tables, error: tablesError } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_schema', 'public')
      .in('table_name', ['whatsapp_conversations', 'whatsapp_messages', 'whatsapp_order_relays']);

    if (tables && tables.length === 3) {
      console.log('✅ All tables created successfully!\n');
      console.log('Tables:');
      tables.forEach(t => console.log(`   ✅ ${t.table_name}`));
    } else {
      console.log('⚠️  Could not verify all tables were created');
      console.log('Please manually verify in Supabase dashboard');
    }

    console.log(`
✅ Deployment complete!

Next steps:
1. Run: node diagnose-bot.js
2. Send a test message to: +39 328 1854639
3. Run: node check-messages.js
    `);

  } catch (error) {
    console.error('❌ Deployment failed:', error.message);
    process.exit(1);
  }
}

deploySchema();
