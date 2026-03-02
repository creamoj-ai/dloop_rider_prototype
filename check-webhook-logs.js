const https = require('https');

const options = {
  hostname: 'api.supabase.co',
  port: 443,
  path: '/v1/projects/aqpwfurradxbnqvycvkm/analytics/logs/function-edge-logs?limit=50&timestamp=desc',
  method: 'GET',
  headers: {
    'Authorization': 'Bearer YOUR_API_KEY_HERE'  // Questo non ha accesso, ma vediamo
  }
};

console.log('⚠️  Nota: Non possiamo accedere ai logs via API senza autenticazione.');
console.log('👉 Vai direttamente a Supabase Dashboard:');
console.log('   https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/functions/whatsapp-webhook');
console.log('   Clicca tab "Logs" per vedere gli errori in tempo reale.');
