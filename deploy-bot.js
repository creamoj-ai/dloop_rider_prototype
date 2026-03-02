#!/usr/bin/env node

/**
 * WhatsApp Bot MVP Deployment Script
 * Sets secrets and prepares for Supabase Edge Functions deployment
 */

const fs = require('fs');
const path = require('path');

const SUPABASE_URL = 'https://imhjdsjtaommutdmkouf.supabase.co';
const PROJECT_ID = 'imhjdsjtaommutdmkouf';

// Credentials (you need to set these)
const secrets = {
  OPENAI_API_KEY: process.env.OPENAI_API_KEY || '',
  WHATSAPP_PHONE_NUMBER_ID: process.env.WHATSAPP_PHONE_NUMBER_ID || '',
  WHATSAPP_ACCESS_TOKEN: process.env.WHATSAPP_ACCESS_TOKEN || '',
  WHATSAPP_VERIFY_TOKEN: 'dloop_wa_verify_2026',
};

console.log('🚀 WhatsApp Bot MVP Deployment\n');
console.log('Project:', PROJECT_ID);
console.log('URL:', SUPABASE_URL);

// Validate secrets
const missing = Object.entries(secrets)
  .filter(([key, value]) => !value && key !== 'WHATSAPP_VERIFY_TOKEN')
  .map(([key]) => key);

if (missing.length > 0) {
  console.error('\n❌ Missing secrets:');
  missing.forEach(key => {
    console.error(`  - ${key}`);
  });
  console.error('\n📋 Set them via environment variables or Supabase dashboard:');
  console.error('\nOption 1: Environment Variables');
  console.error('  export OPENAI_API_KEY="sk-..."');
  console.error('  export WHATSAPP_PHONE_NUMBER_ID="..."');
  console.error('  export WHATSAPP_ACCESS_TOKEN="..."');
  console.error('  node deploy-bot.js');
  console.error('\nOption 2: Supabase Dashboard');
  console.error('  1. Go to Project Settings → Secrets');
  console.error('  2. Add the 3 secrets above');
  console.error('  3. Deploy via CLI: supabase deploy --project-ref ' + PROJECT_ID);
  process.exit(1);
}

console.log('\n✅ All secrets ready!');

// Functions to deploy
const functions = [
  'whatsapp-webhook',
  'whatsapp-simulate',
  'whatsapp-notify',
  'chat-bot',
];

console.log('\n📦 Functions ready to deploy:');
functions.forEach(fn => {
  const fnPath = path.join(__dirname, 'supabase/functions', fn, 'index.ts');
  if (fs.existsSync(fnPath)) {
    console.log(`  ✓ ${fn}`);
  } else {
    console.log(`  ✗ ${fn} (NOT FOUND)`);
  }
});

console.log('\n🔧 Next steps:');
console.log('1. Set secrets in Supabase dashboard:');
console.log('   https://supabase.com/dashboard/project/' + PROJECT_ID + '/settings/secrets');
console.log('   ');
console.log('   - OPENAI_API_KEY');
console.log('   - WHATSAPP_PHONE_NUMBER_ID');
console.log('   - WHATSAPP_ACCESS_TOKEN');
console.log('   - WHATSAPP_VERIFY_TOKEN = dloop_wa_verify_2026');
console.log('');
console.log('2. Deploy functions:');
console.log('   supabase deploy --project-ref ' + PROJECT_ID);
console.log('');
console.log('3. Test simulate endpoint:');
console.log('   curl -X POST ' + SUPABASE_URL + '/functions/v1/whatsapp-simulate \\');
console.log('     -H "Content-Type: application/json" \\');
console.log('     -d \'{"phone":"+393331111111","text":"Ciao","name":"Test"}\'');
console.log('');
console.log('4. Setup Meta webhook:');
console.log('   URL: ' + SUPABASE_URL + '/functions/v1/whatsapp-webhook');
console.log('   Token: dloop_wa_verify_2026');
console.log('');
