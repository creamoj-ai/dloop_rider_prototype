# WhatsApp Bot MVP - Deployment Checklist

**Status**: Code ready ✅ | Deploy pending ⏳

---

## 📋 Pre-Deployment Checklist

### 1. ✅ Code Infrastructure
- [x] Webhook handler (`whatsapp-webhook/index.ts`)
- [x] Customer processor with ChatGPT + function calling
- [x] Dealer processor with keyword-first + NLU fallback
- [x] Simulate endpoint for testing (`whatsapp-simulate/index.ts`)
- [x] Customer & dealer tools defined
- [x] OpenAI integration with function calling
- [x] WhatsApp Cloud API client
- [x] SQL tables created (whatsapp_conversations, whatsapp_messages, order_relays)

### 2. 🔧 Environment Secrets (Need to set in Supabase)

Set these in Supabase dashboard → Project Settings → Secrets:

```bash
# 1. OpenAI
OPENAI_API_KEY=sk-...

# 2. WhatsApp Business
WHATSAPP_PHONE_NUMBER_ID=<your-phone-id>
WHATSAPP_ACCESS_TOKEN=<your-access-token>
WHATSAPP_VERIFY_TOKEN=dloop_wa_verify_2026

# 3. Optional: Rate limiting cache (Redis, if needed)
# REDIS_URL=redis://...
```

**Where to find:**
- OpenAI: https://platform.openai.com/account/api-keys
- WhatsApp: Meta Business Manager → WhatsApp Business → API setup

---

## 🚀 Deployment Steps

### Option A: Deploy via Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf
2. Functions → Deploy → Upload `supabase/functions/`
3. Set secrets before deploying

### Option B: Deploy via Supabase CLI

```bash
# Install CLI (if not already)
npm install -g supabase

# Login
supabase login

# Set secrets
supabase secrets set OPENAI_API_KEY="sk-..."
supabase secrets set WHATSAPP_PHONE_NUMBER_ID="..."
supabase secrets set WHATSAPP_ACCESS_TOKEN="..."
supabase secrets set WHATSAPP_VERIFY_TOKEN="dloop_wa_verify_2026"

# Deploy all functions
supabase functions deploy

# Verify deployment
supabase functions list
```

---

## 🧪 Post-Deployment Testing

### Test 1: Simulate Endpoint (No WhatsApp credentials needed)

```bash
curl -X POST "https://imhjdsjtaommutdmkouf.supabase.co/functions/v1/whatsapp-simulate" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331111111",
    "text": "Ciao, mi servono prodotti per il gatto",
    "name": "Test Customer"
  }'
```

Expected response:
```json
{
  "success": true,
  "reply": "Perfetto! Sto cercando prodotti per gatti...",
  "conversation_id": "conv_...",
  "routed_to": "customer"
}
```

### Test 2: Dealer Message

```bash
# Using a dealer phone number (from rider_contacts)
curl -X POST "https://imhjdsjtaommutdmkouf.supabase.co/functions/v1/whatsapp-simulate" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331111111",
    "text": "OK",
    "name": "Toelettatura Pet",
    "role": "dealer"
  }'
```

### Test 3: Check DB Messages

```sql
SELECT * FROM whatsapp_conversations LIMIT 5;
SELECT * FROM whatsapp_messages ORDER BY created_at DESC LIMIT 10;
```

---

## 🔗 Meta WhatsApp Webhook Setup

### 1. Create Meta App (if not existing)
- Go to: https://developers.facebook.com/apps
- Create new app → Business → WhatsApp

### 2. Configure Webhook

In Meta Developer Console:

```
Webhook URL: https://imhjdsjtaommutdmkouf.supabase.co/functions/v1/whatsapp-webhook
Verify Token: dloop_wa_verify_2026
```

### 3. Subscribe to Webhooks

Subscribe to:
- `messages` (receive customer messages)
- `message_status` (delivery status)

### 4. Test Meta Webhook Verification

Meta will send:
```
GET https://imhjdsjtaommutdmkouf.supabase.co/functions/v1/whatsapp-webhook?hub.mode=subscribe&hub.verify_token=dloop_wa_verify_2026&hub.challenge=<random>
```

The webhook handler responds with the challenge automatically ✅

---

## 📊 Dealer Pilots (MVP Phase 1)

### Primary: Toelettatura Pet
- **Phone**: +39 xxx xxx xxxx (from rider_contacts)
- **Category**: Pets (bevande + integratori)
- **Products**: Sheba, Royal Canin, etc.

### Secondary: Piccolo Supermarket PAM
- **Category**: Grocery
- **Products**: Pasta, Rice, etc.

### Tertiary: Yamamay/Carpisa Cimino Group
- **Category**: Fashion/Luxury

---

## 🎯 Next Steps

1. **Set Environment Secrets** (Critical)
   - OpenAI API key
   - WhatsApp credentials

2. **Deploy Functions**
   - Via CLI or Dashboard

3. **Test Simulate Endpoint**
   - Verify customer pipeline
   - Verify dealer pipeline

4. **Setup Meta Webhook**
   - Register webhook URL
   - Test verification

5. **Demo to Dealers**
   - Test WhatsApp messages
   - Verify order creation flow
   - Collect feedback

6. **Deploy to Production**
   - Enable webhook subscriptions
   - Monitor logs
   - Optimize prompts based on feedback

---

## 🔍 Monitoring & Logs

### Supabase Functions Logs
```
https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/functions
```

### Key Metrics to Monitor
- Message processing latency
- GPT token usage & cost
- Error rates
- WhatsApp delivery success rate

### Debug SQL Queries
```sql
-- Last 10 conversations
SELECT id, phone, role, state, last_message_at
FROM whatsapp_conversations
ORDER BY last_message_at DESC
LIMIT 10;

-- Messages for a conversation
SELECT direction, content, message_type, tokens_used, created_at
FROM whatsapp_messages
WHERE conversation_id = 'conv_...'
ORDER BY created_at DESC;

-- Pending orders for a dealer
SELECT relay_id, status, dettagli, importo
FROM order_relays
WHERE dealer_contact_id = '...'
AND status IN ('pending', 'sent', 'confirmed', 'preparing')
ORDER BY created_at DESC;
```

---

## 🚨 Troubleshooting

### Issue: "OpenAI API key invalid"
- Verify `OPENAI_API_KEY` is set correctly in Supabase secrets
- Check key has "write" permissions

### Issue: "WhatsApp send failed"
- Verify `WHATSAPP_ACCESS_TOKEN` is current (tokens expire)
- Check `WHATSAPP_PHONE_NUMBER_ID` matches your business number

### Issue: "Webhook verification failed"
- Ensure `WHATSAPP_VERIFY_TOKEN` matches Meta console setting
- Check webhook URL is accessible (no firewall blocks)

### Issue: "Dealer not found"
- Ensure dealer phone is in `rider_contacts` with `contact_type='dealer'`
- Check phone normalization (spaces, prefixes)

---

## 📞 Support

Contact the development team or check function logs in Supabase dashboard.
