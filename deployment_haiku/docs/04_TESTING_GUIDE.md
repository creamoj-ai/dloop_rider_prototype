# Testing Guide

## Unit Tests

### 1. Diagnostic Test
```bash
node diagnose-bot.js
```

**Checks**:
- Database connectivity
- Inbound messages received
- Outbound messages sent
- Conversations created
- Webhook endpoint reachable
- Dealer contacts configured

**Expected Output**:
```
✅ Database connectivity: OK
✅ Webhook verification endpoint: WORKING
❌ No inbound messages found (expected on first run)
❌ No conversations found (expected on first run)
```

### 2. Webhook Endpoint Test
```bash
node test-webhook-directly.js
```

**What it does**:
- Sends simulated Meta webhook payload
- Expects 200 status response
- Waits 5 seconds for processing
- Instructs to run `diagnose-bot.js`

**Expected Output**:
```
✅ WEBHOOK RESPONSE:
Status: 200
```

### 3. Meta Test Number
```bash
node test-with-meta-test-number.js
```

**What it does**:
- Sends message from Meta's official test number (15551505103)
- Tests webhook with official Meta format
- Verifies payload parsing

## Integration Tests

### 1. Simulate Endpoint (Direct ChatGPT Test)
```bash
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331234567",
    "text": "Vorrei ordinare un profumo",
    "name": "Mario Rossi"
  }'
```

**Expected Response**:
```json
{
  "success": true,
  "reply": "Perfetto! Ho trovato il profumo che stai cercando...",
  "conversation_id": "uuid-12345",
  "routed_to": "customer"
}
```

### 2. Test Dealer Routing
```bash
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393281234567",
    "text": "Stock update",
    "name": "Marco Dealer",
    "role": "dealer"
  }'
```

### 3. Database Verification
```sql
-- Check recent messages
SELECT * FROM whatsapp_messages
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- Check conversations
SELECT phone, conversation_type, message_count, last_message_at
FROM whatsapp_conversations
ORDER BY last_message_at DESC
LIMIT 5;

-- Check order relays
SELECT * FROM whatsapp_order_relays
WHERE status IN ('pending', 'confirmed')
ORDER BY created_at DESC;
```

## Live Testing

### Step 1: Send Test Message
1. Open WhatsApp on phone
2. Send message to bot number: **+39 328 1854639**
3. Message: "Ciao! Questo è un test."
4. Wait 5-10 seconds for response

### Step 2: Check Logs
```
Supabase Dashboard → Functions → whatsapp-webhook → Logs
```

Look for:
```
Routing to CUSTOMER pipeline
Calling OpenAI...
Generated response: "Ciao! Sono un assistente Dloop..."
Message sent successfully
```

### Step 3: Verify Database
```sql
SELECT * FROM whatsapp_messages
WHERE phone = '393331234567'
ORDER BY created_at DESC
LIMIT 5;
```

### Step 4: Test Intent Variations

**Order Intent**:
```
"Vorrei ordinare 2 profumi Chanel"
```
Expected: Bot suggests products, confirms order

**Product Inquiry**:
```
"Che prodotti avete disponibili?"
```
Expected: Bot lists categories and popular items

**Support Request**:
```
"Ho un problema con il mio ordine"
```
Expected: Bot escalates to human support

**General Chat**:
```
"Ciao, come stai?"
```
Expected: Bot responds conversationally

## Test Scenarios

### Scenario 1: Happy Path (Customer Order)
```
User: "Voglio ordinare un profumo"
Bot: "Perfetto! Quali profumi preferisci?"
User: "Un Chanel No. 5"
Bot: "Ho trovato questo. Confermi l'ordine?"
Expected: Order created in DB, customer notified
```

### Scenario 2: Product Not Found
```
User: "Avete il profumo XYZ?"
Bot: "Non abbiamo quel prodotto, ma ti suggerisco..."
Expected: Graceful fallback, similar products suggested
```

### Scenario 3: Dealer Inquiry
```
From dealer +39328XXXXXX: "Come procede?"
Bot: "Ciao! Gli ultimi ordini sono..."
Expected: Routed to dealer pipeline, custom response
```

### Scenario 4: Conversation History
```
Message 1: "Ciao"
Bot: "Ciao! Come posso aiutarti?"

Message 2: "Prodotti per il viso"
Bot: [Remembers context, shows face products]

Expected: Conversation context maintained
```

### Scenario 5: Error Handling
```
User: [Send message during ChatGPT outage]
Bot: "Mi scusi, il servizio è momentaneamente indisponibile. Riprova tra poco."
Expected: Graceful degradation, no crash
```

## Performance Testing

### Load Test (50 concurrent messages)
```bash
# This would be implemented with a load test script
# Check how many messages/sec the system can handle
```

**Target**: >10 messages/sec sustained

### Latency Test
```sql
-- Check average response time
SELECT
  AVG(EXTRACT(EPOCH FROM (m2.created_at - m1.created_at))) as avg_response_time_sec,
  COUNT(*) as total_conversations
FROM whatsapp_messages m1
JOIN whatsapp_messages m2 ON m1.conversation_id = m2.conversation_id
WHERE m1.direction = 'inbound' AND m2.direction = 'outbound'
AND m2.created_at > m1.created_at
AND m2.created_at - m1.created_at < INTERVAL '1 minute';
```

**Target**: <8 seconds average

## Troubleshooting Tests

### Test: Webhook Not Receiving Messages
```bash
# 1. Verify endpoint reachable
curl -I https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook

# 2. Check Meta configuration
# Go to Meta Business Account → Webhook
# Verify URL and verify token

# 3. Send test message
node test-webhook-directly.js

# 4. Check logs
# Supabase Dashboard → Functions → whatsapp-webhook
```

### Test: ChatGPT Not Responding
```bash
# 1. Verify OpenAI key
node -e "console.log(process.env.OPENAI_API_KEY ? 'Key exists' : 'Key missing')"

# 2. Test OpenAI API directly
curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer sk-..." \
  -d '{"model":"gpt-3.5-turbo","messages":[{"role":"user","content":"test"}]}'

# 3. Check Supabase function logs for OpenAI errors
```

### Test: Messages Not in Database
```bash
# 1. Check table exists
SELECT * FROM information_schema.tables
WHERE table_name = 'whatsapp_messages';

# 2. Check RLS policies
SELECT * FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'whatsapp_messages';

# 3. Verify anon key has permissions
# In Supabase Auth → Policies, check 'anon' role has INSERT/SELECT
```

## Test Results Template

| Test | Date | Status | Notes |
|------|------|--------|-------|
| Database connectivity | 2026-02-26 | ✅ | 1.2ms latency |
| Webhook endpoint | 2026-02-26 | ✅ | Reachable |
| ChatGPT integration | 2026-02-26 | ⏳ | Testing in progress |
| Customer routing | 2026-02-26 | ⏳ | Pending meta config |
| Dealer routing | 2026-02-26 | ❌ | No dealer contacts |
| Message storage | 2026-02-26 | ⏳ | Pending inbound msgs |
| End-to-end latency | 2026-02-26 | N/A | Pending live test |

---

**Last Updated**: 2026-02-26
**Next**: Run `diagnose-bot.js` to verify current test status
