# Troubleshooting Guide

## Common Issues & Solutions

### ❌ "No inbound messages found" in diagnose-bot.js

**Symptom**:
- Webhook endpoint is reachable
- No messages in `whatsapp_messages` table
- Meta webhook not triggering

**Root Causes**:
1. Meta webhook URL not configured correctly
2. Verify token mismatch
3. Webhook not subscribed to "messages" field
4. Phone number not receiving messages

**Fixes**:

**Option 1**: Verify Meta Configuration
```
1. Go to Meta Business Account → Settings → Business integrations
2. Find "WhatsApp" app
3. Check webhook configuration:
   - URL: https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook
   - Verify token: dloop_wa_verify_2026
   - Subscribed fields: messages (not just webhooks)
4. Click "Test subscription"
5. Should receive "Webhook received"
```

**Option 2**: Resend Webhook Verification
```bash
# Meta should automatically verify, but if not:
# In Meta Business Account, go to Webhook → Verify and Save
# Meta will send: ?hub.mode=subscribe&hub.verify_token=dloop_wa_verify_2026&hub.challenge=<token>
# Should respond with <token> (our code does this automatically)
```

**Option 3**: Test with Simulate Endpoint
```bash
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{"phone":"+393331234567","text":"Test"}'
```

---

### ❌ "Bot NOT responding to messages" / No outbound messages

**Symptom**:
- Inbound messages saved to DB
- No outbound responses
- No ChatGPT responses in logs

**Root Causes**:
1. ChatGPT API key invalid or expired
2. ChatGPT rate limit exceeded
3. Webhook code not calling OpenAI
4. WhatsApp API token invalid

**Fixes**:

**Option 1**: Verify OpenAI Key
```bash
# Check key exists in Supabase secrets
# Go to Supabase Dashboard → Project Settings → API Keys
# Look for OPENAI_API_KEY

# Test key directly:
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer sk-proj-xxxxx"

# Should return list of models
```

**Option 2**: Check Function Logs
```
1. Supabase Dashboard → Functions
2. Click "whatsapp-webhook"
3. Go to "Logs" tab
4. Filter by date (last 1 hour)
5. Look for errors like:
   - "Invalid API key"
   - "Rate limit exceeded"
   - "OpenAI error"
```

**Option 3**: Test ChatGPT Directly
```bash
# Call simulate endpoint which has ChatGPT integration
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331234567",
    "text": "Ciao",
    "name": "Test User"
  }'

# Should return JSON with ChatGPT response
# If fails, check for error message
```

**Option 4**: Check ChatGPT Rate Limits
```
1. Go to https://platform.openai.com/account/billing/overview
2. Check "Usage this month"
3. Check rate limits: https://platform.openai.com/account/rate-limits
4. If near limit, either:
   - Wait for monthly reset
   - Upgrade account
   - Request rate limit increase
```

---

### ❌ "Webhook returned 400 Invalid JSON"

**Symptom**:
```
Status: 400
Body: {"error":"Invalid JSON"}
```

**Root Causes**:
1. Payload malformed
2. Supabase rejecting request format
3. Missing required fields

**Fixes**:

```bash
# Verify payload is valid JSON
node -e "
const payload = {
  object: 'whatsapp_business_account',
  entry: [{
    id: '979991158533832',
    changes: [{
      field: 'messages',
      value: {
        messaging_product: 'whatsapp',
        metadata: {
          display_phone_number: '39328185464',
          phone_number_id: '979991158533832'
        },
        contacts: [{
          wa_id: '393331234567',
          profile: { name: 'Test' }
        }],
        messages: [{
          from: '393331234567',
          id: 'wamid.test',
          timestamp: Date.now().toString(),
          type: 'text',
          text: { body: 'Test' }
        }]
      }
    }]
  }]
};
console.log(JSON.stringify(payload, null, 2));
"

# Compare with test-webhook-directly.js
```

---

### ❌ "Webhook endpoint returns 404 or 405"

**Symptom**:
```
Status: 404 | Method not allowed
```

**Root Causes**:
1. Function not deployed
2. Function name typo
3. Wrong HTTP method

**Fixes**:

```bash
# Check function deployed
supabase functions list

# Should show:
# whatsapp-webhook     <region>

# Test function
curl -I https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook

# Redeploy if missing
supabase functions deploy whatsapp-webhook
```

---

### ⚠️ "ChatGPT response is in English, not Italian"

**Symptom**:
- Bot responds with English text
- Or responds with wrong language

**Root Causes**:
1. System prompt not set correctly
2. User message language not detected
3. OpenAI language model issue

**Fixes**:

Check system prompt in `whatsapp-webhook/processor.ts`:
```typescript
const systemPrompt = `
Tu sei un assistente di servizio clienti amichevole per Dloop.
Rispondi SEMPRE in italiano.
...
`;
```

If using gpt-3.5-turbo, add explicit instruction:
```typescript
messages: [
  {
    role: "system",
    content: "Rispondi SEMPRE in italiano. Non usare altre lingue."
  },
  { role: "user", content: userMessage }
]
```

---

### ⚠️ "Slow response time" (>10 seconds)

**Symptom**:
- User sends message
- Waits 15+ seconds for response

**Root Causes**:
1. ChatGPT API slow
2. Database query timeout
3. Webhook processing delays

**Fixes**:

**Option 1**: Check ChatGPT Performance
```
1. Monitor OpenAI API status: https://status.openai.com/
2. Check response times in logs
3. Consider using gpt-3.5-turbo (faster) vs gpt-4
```

**Option 2**: Optimize Database Queries
```sql
-- Check slow queries
EXPLAIN ANALYZE
SELECT * FROM whatsapp_conversations
WHERE phone = '393331234567';

-- Add indexes if needed
CREATE INDEX idx_phone ON whatsapp_conversations(phone);
```

**Option 3**: Enable Caching
```typescript
// Cache common responses
const cache = new Map();
const cacheKey = `${phone}:${textHash}`;
if (cache.has(cacheKey)) {
  return cache.get(cacheKey);
}
```

---

### ❌ "Database permission denied" error

**Symptom**:
```
Error: permission denied for schema public
```

**Root Causes**:
1. RLS policies blocking access
2. Wrong API key used
3. Database role not configured

**Fixes**:

```sql
-- Check RLS policies
SELECT * FROM pg_policies
WHERE schemaname = 'public';

-- If no policies, check if RLS is enabled
SELECT * FROM information_schema.tables
WHERE table_name = 'whatsapp_messages';

-- Should see row_security = ON

-- Verify anon key has permissions
-- Go to Supabase Dashboard → Authentication → Policies
-- Check 'anon' role has INSERT/SELECT on required tables
```

---

### ❌ "WhatsApp message not sent" (status = 'failed')

**Symptom**:
```sql
SELECT * FROM whatsapp_messages WHERE status = 'failed';
-- Returns messages with meta_response containing errors
```

**Root Causes**:
1. WhatsApp access token invalid/expired
2. Phone number ID incorrect
3. Rate limit exceeded

**Fixes**:

```bash
# Option 1: Update token
# Go to Meta Business Account → Settings → System Users
# Generate new access token
# Update in Supabase secrets: WHATSAPP_ACCESS_TOKEN

# Option 2: Verify phone number ID
# Meta Business Account → WhatsApp → API Setup
# Copy correct Phone Number ID
# Update in Supabase secrets: WHATSAPP_PHONE_NUMBER_ID

# Option 3: Check Meta documentation
# https://developers.facebook.com/docs/whatsapp/cloud-api/
```

---

## Diagnostic Tools

### 1. Run Full System Diagnostic
```bash
node diagnose-bot.js
```

Checks:
- Database connectivity ✅
- Inbound message count ✅
- Outbound message count ✅
- Conversations ✅
- Webhook endpoint ✅
- Dealer contacts ✅

### 2. Check Webhook Logs
```
https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/functions/whatsapp-webhook
```

Click "Logs" tab to see:
- Incoming requests
- Error messages
- Performance metrics

### 3. Query Database Directly
```sql
-- Recent messages
SELECT * FROM whatsapp_messages ORDER BY created_at DESC LIMIT 20;

-- Conversations with counts
SELECT phone, conversation_type, message_count, last_message_at
FROM whatsapp_conversations ORDER BY last_message_at DESC;

-- Failed messages
SELECT * FROM whatsapp_messages WHERE status = 'failed' LIMIT 10;

-- Order relays pending
SELECT * FROM whatsapp_order_relays WHERE status = 'pending';
```

### 4. Test Specific Components
```bash
# Test webhook parsing
node test-webhook-directly.js

# Test with Meta test number
node test-with-meta-test-number.js

# Test ChatGPT integration
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{"phone":"+393331234567","text":"test"}'
```

---

## Emergency Procedures

### 🚨 Bot Down / All Messages Failing

1. **Check Status**:
   ```bash
   node diagnose-bot.js
   ```

2. **Check Logs**:
   - Supabase Functions → whatsapp-webhook → Logs
   - Look for errors in last 10 minutes

3. **Common Fixes** (in order):
   ```bash
   # 1. Redeploy function
   supabase functions deploy whatsapp-webhook

   # 2. Check secrets
   supabase secrets list

   # 3. Verify Meta webhook still configured
   # Check Meta Business Account → Webhook

   # 4. Restart database connection
   # Go to Supabase Dashboard → Database → Network
   # May need to restart connection pool
   ```

4. **If Still Down**:
   - Contact Supabase support
   - Check Meta status page
   - Check OpenAI status page
   - Rollback to last known good commit

### 🚨 Data Loss / Conversation Corruption

```bash
# Backup current data
supabase db dump > backup_$(date +%s).sql

# Don't delete, just stop accepting new messages
# Review corrupted records
SELECT * FROM whatsapp_messages WHERE status = 'corrupt';

# Fix or delete specific records
DELETE FROM whatsapp_messages WHERE id = 'xxx';

# Contact team for recovery
```

---

**Last Updated**: 2026-02-26
**Status**: Production troubleshooting guide
