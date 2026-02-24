console.log(`
╔════════════════════════════════════════════════════════════════╗
║         Diagnostica URL Database nei Secrets                   ║
╚════════════════════════════════════════════════════════════════╝

⚠️ PROBLEMA POTENZIALE:

Il webhook è nel progetto: aqpwfurradxbnqvycvkm
Ma deve connettere al progetto: imhjdsjtaommutdmkouf

✅ CORRETTO:
   SUPABASE_URL = https://imhjdsjtaommutdmkouf.supabase.co
   SUPABASE_SERVICE_ROLE_KEY = key dal progetto imhjdsjtaommutdmkouf

❌ SBAGLIATO:
   SUPABASE_URL = https://aqpwfurradxbnqvycvkm.supabase.co
   SUPABASE_SERVICE_ROLE_KEY = key dal progetto aqpwfurradxbnqvycvkm

───────────────────────────────────────────────────────────────────

Per verificare:

1. Clicca su "SUPABASE_URL" 
2. Vedi il valore (dovrebbe iniziare con https://imhjdsjtaommutdmkouf)

Se è sbagliato, modificalo!

Guarda il valore di SUPABASE_URL e dimmi se contiene:
   ✅ imhjdsjtaommutdmkouf (CORRETTO)
   ❌ aqpwfurradxbnqvycvkm (SBAGLIATO)
`);
