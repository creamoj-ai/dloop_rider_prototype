console.log(`
╔════════════════════════════════════════════════════════════════╗
║       Check if WhatsApp Secrets are Configured                 ║
╚════════════════════════════════════════════════════════════════╝

🔑 Required Secrets in Supabase (project: aqpwfurradxbnqvycvkm):

1. OPENAI_API_KEY
   - Used for ChatGPT processing
   - Status: ❓ UNKNOWN

2. WHATSAPP_PHONE_NUMBER_ID
   - Value should be: 979991158533832
   - Status: ❓ UNKNOWN

3. WHATSAPP_ACCESS_TOKEN
   - Meta WhatsApp Cloud API token
   - Status: ❓ UNKNOWN

4. WHATSAPP_VERIFY_TOKEN
   - Value: dloop_wa_verify_2026
   - Status: ❓ UNKNOWN

5. SUPABASE_SERVICE_ROLE_KEY
   - For database access from webhook
   - Status: ❓ UNKNOWN

═══════════════════════════════════════════════════════════════════

⚠️ THE PROBLEM:
   If secrets are NOT set, the webhook receives messages (200 OK)
   but CANNOT process them (no ChatGPT key, no WhatsApp token, etc.)

✅ SOLUTION:
   1. Go to: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/settings/edge-functions
   2. Look for "Secrets"
   3. Add all 5 secrets above
   4. Then test again

Vuoi che faccia screenshot? Avete i secrets configurati?
`);
