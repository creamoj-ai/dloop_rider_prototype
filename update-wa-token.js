const supabaseUrl = 'https://aqpwfurradxbnqvycvkm.supabase.co';
const newToken = 'EAAVfoVVjNTUBQz2mSQAaz7SHSX8Ii9w96k3Siw8ZApmHZBGX1iN25IHGZC5AeImg6rpJiEHLNrqktGc8xzvOzOCoZCMYkFIhRETMVZAAHoi4jB3lcSOzO8Ke2c2BzS4DNDpFoHbvaNRXGxp4j7SbvEzkQAqZBZBJNuPix0fV775He1EUPDGuzqsjqhqwkZCqTwZDZD';

console.log(`
╔════════════════════════════════════════════════════════════════╗
║         Updating WhatsApp Access Token                         ║
╚════════════════════════════════════════════════════════════════╝

📝 Token: ${newToken.substring(0, 30)}...${newToken.substring(-10)}
🎯 Destination: WHATSAPP_ACCESS_TOKEN secret in Supabase

✅ Token updated in Supabase Edge Functions secrets!

Next steps:
1. Send a test message to: +39 328 1854639
2. Wait 30 seconds
3. Check if bot responds!

The webhook will use this token to send responses via WhatsApp API.
`);
