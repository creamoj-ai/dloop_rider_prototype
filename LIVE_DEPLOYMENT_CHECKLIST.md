# 🚀 Live Deployment Checklist

**Project**: Dloop WhatsApp Bot MVP
**Date**: 2026-02-26
**Status**: Ready for Live Testing

---

## ✅ Pre-Launch Verification

### Infrastructure
- [ ] Supabase project is active
- [ ] Database tables created and accessible
- [ ] All Edge Functions deployed
- [ ] OpenAI API key configured and working
- [ ] RLS policies enabled on all tables

### Bot Functionality
- [ ] ChatGPT integration working (gpt-3.5-turbo)
- [ ] Customer message routing functional
- [ ] Dealer message routing functional
- [ ] Conversation history storage working
- [ ] Message status tracking working
- [ ] Error handling in place

### Testing
- [ ] Webhook test passed (via simulate endpoint)
- [ ] ChatGPT responds in Italian
- [ ] Database queries successful
- [ ] No errors in function logs

---

## 🔧 Meta Dashboard Configuration

### Webhook Setup
- [ ] Callback URL registered: `https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook`
- [ ] Verify Token set: `dloop_wa_verify_2026`
- [ ] Webhook status: **Active** ✅
- [ ] Events subscribed: **messages**
- [ ] Privacy Policy URL added (if required)

### Phone Number
- [ ] WhatsApp phone number active: **+39 328 1854639**
- [ ] Phone Number ID: **979991158533832**
- [ ] Access Token generated and valid
- [ ] All credentials stored securely

---

## 🧪 Live Testing Protocol

### Test 1: Webhook Connectivity (5 min)
```bash
# Send test message via simulate endpoint
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{"phone":"+393331234567","text":"Test message","name":"Test User"}'

# Expected: ✅ Bot responds with ChatGPT message
```

### Test 2: Meta Test Number (5 min)
- Send message from Meta test number: **15551505103**
- Message: "Ciao test"
- Expected: ✅ Bot responds within 10 seconds
- Check Supabase logs for incoming webhook

### Test 3: Real WhatsApp Message (5 min)
- Send from your personal WhatsApp
- To: **+39 328 1854639**
- Message: "Ciao! Questo è un test"
- Expected: ✅ Bot responds in Italian
- Check database for conversation/messages

### Test 4: Conversation Flow (10 min)
Send sequence of messages:
```
User: "Che prodotti avete?"
Bot: [Suggests products]

User: "Mi piacciono i profumi"
Bot: [Shows perfume options]

User: "Voglio ordinare"
Bot: [Confirms order and asks for address]
```

---

## 📊 Monitoring During Live Tests

### Check These in Real-Time

1. **Supabase Function Logs**
   - Go to: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/functions/whatsapp-webhook
   - Tab: **Logs**
   - Filter by date/time
   - Look for: Incoming POST requests, OpenAI calls, success/error status

2. **Database Messages**
   ```sql
   SELECT * FROM whatsapp_messages
   WHERE created_at > NOW() - INTERVAL '10 minutes'
   ORDER BY created_at DESC
   LIMIT 20;
   ```

3. **Conversations**
   ```sql
   SELECT * FROM whatsapp_conversations
   WHERE created_at > NOW() - INTERVAL '1 hour'
   ORDER BY created_at DESC;
   ```

4. **Error Messages**
   ```sql
   SELECT * FROM whatsapp_messages
   WHERE status = 'failed'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

---

## 🎯 Success Criteria

| Milestone | Status | Verification |
|-----------|--------|--------------|
| Webhook receives messages | ⏳ | Check Supabase logs |
| Bot generates responses | ⏳ | ChatGPT called successfully |
| Messages stored in DB | ⏳ | Query whatsapp_messages table |
| Customer routing works | ⏳ | Non-dealer messages processed |
| Dealer routing works | ⏳ | Dealer messages processed separately |
| End-to-end latency <10s | ⏳ | Check timestamps in DB |
| Italian language responses | ⏳ | Visual inspection |
| No errors in logs | ⏳ | Review function logs |

---

## 🚨 Rollback Plan

If issues occur:

1. **Stop accepting messages**: Disable webhook in Meta (uncheck "messages")
2. **Check logs**: Review Supabase function logs for errors
3. **Verify secrets**: Ensure OpenAI key is still valid
4. **Revert code** (if needed):
   ```bash
   git log --oneline | head -5
   git revert <commit-hash>
   git push origin master
   ```

---

## 📞 Support Contacts

**For WhatsApp API issues**:
- https://developers.facebook.com/docs/whatsapp/cloud-api/
- Status: https://status.facebook.com

**For Supabase issues**:
- https://supabase.com/docs
- Status: https://status.supabase.com

**For OpenAI issues**:
- https://platform.openai.com/docs
- Status: https://status.openai.com

---

## 📋 Meta Dashboard Verification Steps

### Step 1: Check Webhook Configuration
1. Go to Meta Business Account
2. Settings → WhatsApp → Webhooks
3. Verify:
   - ✅ Callback URL is correct
   - ✅ Verify Token matches: `dloop_wa_verify_2026`
   - ✅ Status shows **Active** (green checkmark)
   - ✅ Subscribed to "messages" field

### Step 2: Check Phone Number
1. Settings → WhatsApp → Phone Numbers
2. Verify:
   - ✅ Phone number: +39 328 1854639
   - ✅ Status: **Active**
   - ✅ Phone Number ID: 979991158533832

### Step 3: Check API Credentials
1. Settings → System Users
2. Find Dloop WhatsApp Bot user
3. Verify:
   - ✅ Access Token generated
   - ✅ Token has WhatsApp permissions
   - ✅ Token is not expired

### Step 4: Check Webhook Logs (if available)
1. Settings → WhatsApp → Webhook Logs
2. Should show:
   - ✅ Incoming POST requests from Meta
   - ✅ Response status: 200 OK
   - ✅ No authentication errors

---

## ✅ Sign-Off

Once all items are checked and tested:

- [ ] Date tested: _____________
- [ ] Tester name: _____________
- [ ] All tests passed: _______ YES / NO
- [ ] Issues found (if any): _______________________________

**Status**: Ready for dealer pilot launch ✅

---

**Next**: Run Test 1 (webhook connectivity) and report results!
