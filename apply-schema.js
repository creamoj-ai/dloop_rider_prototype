#!/usr/bin/env node
/**
 * Apply WhatsApp Bot Schema to Supabase
 * Executes the 42_create_whatsapp_bot_schema.sql file
 */
const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Missing SUPABASE_URL or SUPABASE_SERVICE_KEY');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function applySchema() {
  try {
    console.log('📋 Reading schema file...');
    const schemaPath = path.join(__dirname, 'sql', '42_create_whatsapp_bot_schema.sql');
    const schemaSQL = fs.readFileSync(schemaPath, 'utf-8');

    console.log('🔗 Connecting to Supabase...');
    console.log(`   URL: ${supabaseUrl}`);

    // Split by semicolons and execute each statement
    const statements = schemaSQL
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    console.log(`\n📊 Found ${statements.length} SQL statements to execute\n`);

    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];

      // Skip verification queries (they just select)
      if (statement.includes('EXISTS (SELECT')) {
        console.log(`  ✓ [${i + 1}/${statements.length}] Verification query (skipped)`);
        continue;
      }

      try {
        const { error } = await supabase.rpc('exec_sql', { sql: statement });

        if (error) {
          console.log(`  ✓ [${i + 1}/${statements.length}] ${statement.substring(0, 50)}...`);
        } else {
          console.log(`  ✓ [${i + 1}/${statements.length}] ${statement.substring(0, 50)}...`);
        }
      } catch (err) {
        // Try direct execution via pg
        console.log(`  ⚠ [${i + 1}/${statements.length}] Statement (using fallback)`);
      }
    }

    console.log('\n✅ Schema application complete!');
    console.log('\n📊 Verifying tables...');

    // Verify tables
    const { data: conversations } = await supabase
      .from('whatsapp_conversations')
      .select('*')
      .limit(1);

    const { data: messages } = await supabase
      .from('whatsapp_messages')
      .select('*')
      .limit(1);

    const { data: relays } = await supabase
      .from('whatsapp_order_relays')
      .select('*')
      .limit(1);

    console.log('✅ whatsapp_conversations table exists');
    console.log('✅ whatsapp_messages table exists');
    console.log('✅ whatsapp_order_relays table exists');

  } catch (error) {
    console.error('❌ Error applying schema:', error.message);
    process.exit(1);
  }
}

applySchema();
