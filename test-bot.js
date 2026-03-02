fetch('https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    phone: '+393331111111',
    text: 'Ciao, mi servono prodotti per il gatto',
    name: 'Test Customer'
  })
}).then(r => r.json()).then(d => console.log(JSON.stringify(d, null, 2)))
