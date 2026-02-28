# 🧪 WhatsApp Webhook - Test Cases

## 📋 TESTING STRATEGY

Questi test verificano che il webhook gestisca correttamente:
1. ✅ Messaggi Twilio form-encoded (inbound)
2. ✅ Status callbacks Twilio (da ignorare)
3. ✅ Messaggi Meta JSON (fallback)
4. ✅ Content-Type detection
5. ✅ ChatGPT integration
6. ✅ Database logging

---

## 🔧 TEST 1: Twilio Inbound Message (SUCCESS)

**Scenario**: Cliente invia messaggio WhatsApp

**Payload** (form-encoded):
```
MessageSid=SM<test-message-sid>
AccountSid=AC<test-account-sid>
From=whatsapp:+393281234567
To=whatsapp:+393281854639
Body=Ciao! Cerco prodotti per cani
MessageStatus=received
ProfileName=Mario Rossi
```

**Headers**:
```
Content-Type: application/x-www-form-urlencoded
```

**Expected Behavior**:
1. ✅ Webhook parsa form-encoded correttamente
2. ✅ Estrae `From`, `Body`, `ProfileName`
3. ✅ Chiama ChatGPT con messaggio cliente
4. ✅ ChatGPT risponde con suggerimento dealer (🐾 Toelettatura Pet)
5. ✅ Risposta inviata via Twilio API
6. ✅ Messaggio salvato in DB (inbound + outbound)

**Logs Attesi**:
```
📨 Webhook received: application/x-www-form-urlencoded
📦 Form data received (Twilio format)
📦 Parsed fields: MessageSid, AccountSid, From, To, Body, MessageStatus, ProfileName
📨 Twilio webhook - MessageSid: SM..., Status: received
✅ Processing Twilio inbound message from +393281234567
📝 Content: "Ciao! Cerco prodotti per cani"
🤖 Starting ChatGPT processing for +393281234567...
✅ Reply sent to +393281234567: "Ciao Mario! 👋 Perfetto, per prodotti per cani ti consiglio 🐾 **TOELETTATURA PET**..."
```

---

## 🔧 TEST 2: Twilio Status Callback (IGNORE)

**Scenario**: Twilio notifica che messaggio è stato consegnato

**Payload** (form-encoded):
```
MessageSid=SM<test-sid>
MessageStatus=delivered
AccountSid=AC<test-sid>
From=whatsapp:+393281854639
To=whatsapp:+393281234567
```

**Headers**:
```
Content-Type: application/x-www-form-urlencoded
```

**Expected Behavior**:
1. ✅ Webhook parsa form-encoded
2. ✅ Rileva `MessageStatus=delivered`
3. ✅ IGNORA (non è un nuovo messaggio)
4. ✅ Ritorna 200 OK immediatamente
5. ✅ NON chiama ChatGPT
6. ✅ NON salva in DB

**Logs Attesi**:
```
📨 Webhook received: application/x-www-form-urlencoded
📦 Form data received (Twilio format)
📦 Parsed fields: MessageSid, MessageStatus, AccountSid, From, To
📨 Twilio webhook - MessageSid: SM..., Status: delivered
⏭️ Skipping status callback: delivered (not a new message)
```

**Altri Status da IGNORARE**:
- `sent` - Messaggio inviato da Twilio
- `delivered` - Messaggio consegnato al cliente
- `read` - Messaggio letto dal cliente
- `failed` - Messaggio non consegnato
- `undelivered` - Messaggio non consegnabile

---

## 🔧 TEST 3: Twilio Empty Message (IGNORE)

**Scenario**: Cliente invia media senza caption

**Payload** (form-encoded):
```
MessageSid=SM<test-message-sid>
AccountSid=AC<test-account-sid>
From=whatsapp:+393281234567
To=whatsapp:+393281854639
Body=
MessageStatus=received
MediaUrl0=https://api.twilio.com/...
```

**Expected Behavior**:
1. ✅ Webhook parsa form-encoded
2. ✅ Rileva `Body` vuoto
3. ✅ IGNORA (no text content)
4. ✅ Ritorna 200 OK
5. ✅ NON chiama ChatGPT

**Logs Attesi**:
```
📨 Webhook received: application/x-www-form-urlencoded
📦 Form data received (Twilio format)
📨 Twilio webhook - MessageSid: SM..., Status: received
⏭️ Skipping empty message (no text content)
```

---

## 🔧 TEST 4: Meta WhatsApp JSON (FALLBACK)

**Scenario**: Messaggio da Meta Business API (JSON)

**Payload** (JSON):
```json
{
  "entry": [
    {
      "changes": [
        {
          "value": {
            "messages": [
              {
                "from": "393281234567",
                "id": "wamid.ABC123",
                "timestamp": "1234567890",
                "text": {
                  "body": "Ciao! Voglio ordinare"
                },
                "type": "text"
              }
            ],
            "contacts": [
              {
                "profile": {
                  "name": "Giulia Bianchi"
                }
              }
            ]
          }
        }
      ]
    }
  ]
}
```

**Headers**:
```
Content-Type: application/json
```

**Expected Behavior**:
1. ✅ Webhook parsa JSON
2. ✅ Estrae `from`, `text.body`, `profile.name`
3. ✅ Chiama ChatGPT
4. ✅ Risponde via Meta API (fallback)
5. ✅ Salva in DB

**Logs Attesi**:
```
📨 Webhook received: application/json
📦 JSON body (Meta format): entry
📨 Meta webhook - From: 393281234567
📝 Content: "Ciao! Voglio ordinare"
🤖 Starting ChatGPT processing for 393281234567...
✅ Reply sent to 393281234567: "Ciao Giulia! 👋..."
```

---

## 🔧 TEST 5: Unknown Content-Type (FALLBACK)

**Scenario**: Webhook riceve richiesta con Content-Type sconosciuto

**Payload** (text/plain):
```
Some random text
```

**Headers**:
```
Content-Type: text/plain
```

**Expected Behavior**:
1. ✅ Webhook tenta JSON fallback
2. ✅ Parsing fallisce
3. ✅ Ritorna 200 OK (no crash)
4. ✅ Log warning

**Logs Attesi**:
```
📨 Webhook received: text/plain
⚠️ Unknown content-type, attempting JSON fallback
⚠️ Could not parse request body: SyntaxError...
```

---

## 🔧 TEST 6: ChatGPT Product Recommendation

**Scenario**: Cliente chiede prodotti per una categoria specifica

**Input Messages**:
```
1. "Ciao! Cerco shampoo per cani" → 🐾 TOELETTATURA PET
2. "Mi serve latte fresco" → 🛒 PICCOLO SUPERMARKET
3. "Voglio prodotti bio" → 🥬 NATURASÌ VOMERO
4. "Cerco una maglietta" → 👔 YAMAMAY/CARPISA
```

**Expected ChatGPT Response Format**:
```
Ciao! 👋 Perfetto, per [categoria] ti consiglio [emoji] **[DEALER NAME]**!

Abbiamo:
- [Prodotto 1] - €[prezzo]
- [Prodotto 2] - €[prezzo]
- [Prodotto 3] - €[prezzo]

Ti interessa qualcosa? 😊
```

**Database Check**:
```sql
-- Verifica che ChatGPT abbia chiamato browse_dealer_menu
SELECT content, tokens_used
FROM whatsapp_messages
WHERE direction = 'outbound'
ORDER BY created_at DESC
LIMIT 1;
```

---

## 🔧 TEST 7: Conversation History (Context)

**Scenario**: Cliente invia più messaggi in sequenza

**Messages**:
```
1. Cliente: "Ciao!"
2. Bot: "Ciao! 👋 Cerchi..."
3. Cliente: "Sì, prodotti per cani"
4. Bot: "Perfetto! 🐾 TOELETTATURA PET..."
5. Cliente: "Quali prodotti avete?"
6. Bot: "Abbiamo: Shampoo delicato €8.50, Antiparassitario €15..."
```

**Database Check**:
```sql
-- Verifica conversazione completa
SELECT direction, content, created_at
FROM whatsapp_messages
WHERE phone = '+393281234567'
ORDER BY created_at ASC;
```

**Expected**: Almeno 6 righe (3 inbound + 3 outbound)

---

## 📊 MONITORING QUERIES

### Check Recent Conversations
```sql
SELECT
  phone,
  customer_name,
  conversation_type,
  state,
  last_message_at
FROM whatsapp_conversations
ORDER BY last_message_at DESC
LIMIT 10;
```

### Check Recent Messages
```sql
SELECT
  direction,
  phone,
  content,
  message_type,
  status,
  tokens_used,
  created_at
FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 20;
```

### Count Messages by Status
```sql
SELECT
  direction,
  status,
  COUNT(*) as count
FROM whatsapp_messages
GROUP BY direction, status;
```

**Expected Output**:
```
direction | status | count
----------|--------|------
inbound   | sent   | 25
outbound  | sent   | 25
outbound  | failed | 0
```

### Average Response Time (ChatGPT)
```sql
WITH pairs AS (
  SELECT
    conversation_id,
    phone,
    direction,
    created_at,
    LEAD(created_at) OVER (PARTITION BY conversation_id ORDER BY created_at) as next_msg_at
  FROM whatsapp_messages
)
SELECT
  AVG(EXTRACT(EPOCH FROM (next_msg_at - created_at))) as avg_response_seconds
FROM pairs
WHERE direction = 'inbound' AND next_msg_at IS NOT NULL;
```

**Expected**: 2-5 secondi (ChatGPT processing time)

---

## 🚨 ERROR SCENARIOS

### ❌ Scenario 1: OpenAI API Key Invalid

**Symptom**: Bot non risponde, logs mostrano:
```
❌ Processing error: Error: OpenAI API key invalid
```

**Fix**:
```bash
npx supabase secrets set OPENAI_API_KEY=<your-openai-api-key>
```

### ❌ Scenario 2: Twilio Credentials Missing

**Symptom**: Logs mostrano:
```
❌ Missing Twilio credentials
```

**Fix**:
```bash
npx supabase secrets set TWILIO_ACCOUNT_SID=<your-sid>
npx supabase secrets set TWILIO_AUTH_TOKEN=<your-token>
npx supabase secrets set TWILIO_PHONE_NUMBER=+393281854639
```

### ❌ Scenario 3: Database Connection Error

**Symptom**: Logs mostrano:
```
❌ Failed to create conversation: Connection timeout
```

**Fix**: Verifica che `SUPABASE_SERVICE_ROLE_KEY` sia corretto

---

## ✅ SUCCESS CRITERIA

Webhook è PRODUCTION READY quando:

- [x] ✅ Test 1 (Twilio inbound) passa
- [x] ✅ Test 2 (Status callbacks) vengono ignorati
- [x] ✅ Test 3 (Empty messages) vengono ignorati
- [x] ✅ Test 4 (Meta JSON) passa (fallback)
- [x] ✅ Test 5 (Unknown content-type) non crasha
- [x] ✅ Test 6 (ChatGPT recommendations) funziona
- [x] ✅ Test 7 (Conversation history) persiste
- [x] ✅ Database ha messaggi inbound + outbound
- [x] ✅ Logs non mostrano errori critici
- [x] ✅ Response time < 5 secondi

---

**Last Updated**: 2026-02-28
**Status**: PRODUCTION READY ✅
