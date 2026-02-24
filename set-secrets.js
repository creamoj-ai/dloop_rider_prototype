#!/usr/bin/env node

/**
 * Set Supabase Secrets for WhatsApp Bot
 *
 * Usage:
 *   node set-secrets.js <openai-key> <phone-id> <access-token>
 *
 * Or via environment variables:
 *   export OPENAI_API_KEY="sk-..."
 *   export WHATSAPP_PHONE_NUMBER_ID="..."
 *   export WHATSAPP_ACCESS_TOKEN="..."
 *   node set-secrets.js
 */

const fs = require('fs');
const path = require('path');

// Get credentials from args or env
const openaiKey = process.argv[2] || process.env.OPENAI_API_KEY;
const phoneId = process.argv[3] || process.env.WHATSAPP_PHONE_NUMBER_ID;
const accessToken = process.argv[4] || process.env.WHATSAPP_ACCESS_TOKEN;

const SUPABASE_URL = 'https://imhjdsjtaommutdmkouf.supabase.co';
const PROJECT_ID = 'imhjdsjtaommutdmkouf';

if (!openaiKey || !phoneId || !accessToken) {
  console.error('❌ Missing credentials!\n');
  console.error('Usage:');
  console.error('  node set-secrets.js <openai-key> <phone-id> <access-token>\n');
  console.error('Or set environment variables:');
  console.error('  export OPENAI_API_KEY="sk-..."');
  console.error('  export WHATSAPP_PHONE_NUMBER_ID="..."');
  console.error('  export WHATSAPP_ACCESS_TOKEN="..."');
  console.error('  node set-secrets.js');
  process.exit(1);
}

console.log('📋 Supabase Secrets Configuration\n');
console.log('Project:', PROJECT_ID);
console.log('URL:', SUPABASE_URL);

console.log('\n🔐 Secrets to be set:');
console.log('✓ OPENAI_API_KEY:', openaiKey.substring(0, 20) + '...');
console.log('✓ WHATSAPP_PHONE_NUMBER_ID:', phoneId);
console.log('✓ WHATSAPP_ACCESS_TOKEN:', accessToken.substring(0, 20) + '...');
console.log('✓ WHATSAPP_VERIFY_TOKEN: dloop_wa_verify_2026');

console.log('\n⚠️  MANUAL SETUP REQUIRED\n');
console.log('Unfortunately, the Supabase Management API requires authentication that');
console.log('is not available in this context. Please set secrets manually:\n');

console.log('1️⃣  Go to Supabase Dashboard:');
console.log(`   https://supabase.com/dashboard/project/${PROJECT_ID}/settings/secrets\n`);

console.log('2️⃣  Click "New Secret" and add each:');
console.log(`   Name: OPENAI_API_KEY`);
console.log(`   Value: ${openaiKey}\n`);

console.log(`   Name: WHATSAPP_PHONE_NUMBER_ID`);
console.log(`   Value: ${phoneId}\n`);

console.log(`   Name: WHATSAPP_ACCESS_TOKEN`);
console.log(`   Value: ${accessToken}\n`);

console.log(`   Name: WHATSAPP_VERIFY_TOKEN`);
console.log(`   Value: dloop_wa_verify_2026\n`);

console.log('3️⃣  After setting all secrets, deploy via CLI:');
console.log(`   supabase deploy --project-ref ${PROJECT_ID}\n`);

console.log('Or deploy via Dashboard → Functions → Deploy\n');

// Create a config file for reference
const configPath = path.join(__dirname, '.secrets-config.json');
const config = {
  OPENAI_API_KEY: openaiKey,
  WHATSAPP_PHONE_NUMBER_ID: phoneId,
  WHATSAPP_ACCESS_TOKEN: accessToken,
  WHATSAPP_VERIFY_TOKEN: 'dloop_wa_verify_2026',
  timestamp: new Date().toISOString(),
};

fs.writeFileSync(configPath, JSON.stringify(config, null, 2), { mode: 0o600 });
console.log('💾 Credentials saved to .secrets-config.json (⚠️  Keep this secure!)');
console.log('⚠️  Add .secrets-config.json to .gitignore\n');
