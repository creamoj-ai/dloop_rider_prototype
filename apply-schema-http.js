#!/usr/bin/env node
/**
 * Apply WhatsApp Bot Schema to Supabase via HTTP
 * This reads the SQL file and executes it through the REST API
 */
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
  console.error('❌ Error: Missing credentials');
  console.error('   - SUPABASE_URL: ' + (SUPABASE_URL ? '✓' : '✗'));
  console.error('   - SUPABASE_SERVICE_KEY: ' + (SUPABASE_SERVICE_KEY ? '✓' : '✗'));
  console.error('\nTo fix:');
  console.error('1. Log in to: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm');
  console.error('2. Go to Settings → API → Service Role Key');
  console.error('3. Add to .env: SUPABASE_SERVICE_KEY=<key>');
  process.exit(1);
}

async function executeSQL() {
  try {
    console.log('📋 Reading schema file...');
    const schemaPath = path.join(__dirname, 'sql', '42_create_whatsapp_bot_schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf-8');

    console.log('🚀 Connecting to Supabase...');
    console.log(`   Project: ${SUPABASE_URL}`);

    // Get URL without the https:// prefix to construct the SQL endpoint
    const projectId = SUPABASE_URL.split('https://')[1].split('.')[0];
    const sqlEndpoint = `${SUPABASE_URL}/rest/v1/`;

    // Execute via rpc (execute_sql function if it exists)
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'apikey': SUPABASE_SERVICE_KEY,
      },
      body: JSON.stringify({ sql: schema }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${JSON.stringify(data)}`);
    }

    console.log('\n✅ Schema applied successfully!');
    console.log('\n📊 Result:', data);

  } catch (error) {
    console.error('\n❌ Error applying schema:');
    console.error(error.message);
    console.error('\n💡 Alternative: Apply schema manually:');
    console.error('1. Go to: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/sql/new');
    console.error('2. Open file: sql/42_create_whatsapp_bot_schema.sql');
    console.error('3. Copy & paste entire content');
    console.error('4. Click "RUN"');
    process.exit(1);
  }
}

executeSQL();
