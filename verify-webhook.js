fetch('https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook?hub.mode=subscribe&hub.verify_token=dloop_wa_verify_2026&hub.challenge=test123')
  .then(r => r.text())
  .then(t => console.log('Response:', t))
  .catch(e => console.error('Error:', e.message))
