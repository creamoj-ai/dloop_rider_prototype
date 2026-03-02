-- Verifica test bot WhatsApp
SELECT 
  id,
  phone,
  customer_name,
  state,
  role,
  created_at,
  last_message_at
FROM whatsapp_conversations
WHERE phone = '+393331111111'
ORDER BY created_at DESC
LIMIT 1;

-- Messaggi della conversazione
SELECT 
  direction,
  content,
  message_type,
  created_at
FROM whatsapp_messages
WHERE conversation_id IN (
  SELECT id FROM whatsapp_conversations 
  WHERE phone = '+393331111111'
)
ORDER BY created_at;
