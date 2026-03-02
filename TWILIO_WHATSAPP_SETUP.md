# Twilio WhatsApp Business Account Setup Guide

## Current Status
- ✅ Twilio account upgraded to paid plan
- ✅ Italian phone number registered: +39 328 1854639
- ✅ Supabase secrets configured (TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER)
- ✅ Webhook code deployed and receiving messages
- ✅ Backend processing 100% (ChatGPT responding, DB logging)
- ❌ **Messages NOT delivering to end user** ← MUST FIX

## Root Cause
Account upgrade alone is insufficient. Twilio requires:
1. WhatsApp Business Account (WABA) creation/linking
2. Phone number association with WABA
3. Sender verification
4. Webhook verification in Twilio

## Complete Twilio WhatsApp Setup (Step-by-Step)

### **STEP 1: Access Twilio WhatsApp Configuration**

1. Go to: https://www.twilio.com/console
2. Navigate: **Messaging → WhatsApp Senders** (left sidebar)
3. You should see your phone number: +39 328 1854639

### **STEP 2: Register WhatsApp Business Account in Twilio**

If you see a **"Request WhatsApp Business Account"** button:

1. Click the phone number (+39 328 1854639)
2. You'll see a form asking for:
   - **Business Name**: "DLOOP"
   - **Category**: Select "General" or closest match
   - **Business Description**: "Delivery service for local restaurants and shops in Campania"
   - **Website**: (optional) Leave blank if no website
   - **Business Address**: "Napoli, Campania, Italy"

3. Click **Request WhatsApp Business Account**
4. Status will change to **PENDING** (usually 1-24 hours)
5. Twilio will approve and link your WABA automatically

### **STEP 3: Verify Webhook Configuration in Twilio**

While waiting for WABA approval, verify webhook is correctly configured:

1. **Messaging → Try it Out** (left sidebar)
2. Look for **Webhook URL** field
3. Confirm it shows your Supabase function URL:
   ```
   https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook
   ```

4. If URL is missing or wrong:
   - Get your correct function URL from Supabase Functions dashboard
   - Click **Edit** and paste correct URL
   - Save

### **STEP 4: Test Webhook (Before WABA Approval)**

Once WABA status is PENDING, test with Twilio's sandbox:

1. In **Try it Out** section, send test message:
   ```
   Message: "Ciao, sono il test"
   ```

2. Check Supabase logs:
   - Go to: https://aqpwfurradxbnqvycvkm.supabase.co
   - **Functions → whatsapp-webhook → Invocations**
   - You should see log entry with your message

3. If webhook receives message → Configuration is correct ✅

### **STEP 5: Monitor WABA Approval Status**

1. Go back to **Messaging → WhatsApp Senders**
2. Check status of +39 328 1854639
3. Status progression:
   - **PENDING** → Wait (1-24 hours)
   - **ACTIVE** → Ready for production! ✅
   - **REJECTED** → Check rejection reason and resubmit

4. Once ACTIVE:
   - Your number is linked to WhatsApp Business Account
   - Message delivery will work automatically
   - No additional configuration needed

### **STEP 6: Test End-to-End Delivery**

Once WABA status is **ACTIVE**:

1. Send test message to Dloop WhatsApp number: **+39 328 1854639**
2. You should receive ChatGPT response within 2-5 seconds
3. Check database:
   - Supabase → SQL Editor
   - Query:
     ```sql
     SELECT direction, content, status, created_at
     FROM whatsapp_messages
     ORDER BY created_at DESC
     LIMIT 10;
     ```
   - You should see:
     - inbound: Your message
     - outbound: ChatGPT response (status="sent") ← should now reach your phone
     - Created timestamps show processing time

## If Messages Still Don't Deliver

### Check 1: Verify Secrets in Supabase

1. Go to: https://aqpwfurradxbnqvycvkm.supabase.co
2. **Settings → Secrets** (left sidebar)
3. Verify these are set:
   ```
   TWILIO_ACCOUNT_SID = <your account SID>
   TWILIO_AUTH_TOKEN = <your auth token>
   TWILIO_PHONE_NUMBER = +39 328 1854639
   ```

### Check 2: View Function Logs

1. **Functions → whatsapp-webhook → Invocations**
2. Look for error messages in logs
3. Common errors:
   - "Missing Twilio credentials" → Secrets not set
   - "HTTP 403 Forbidden" → Auth token wrong
   - "HTTP 404 Not Found" → Phone number not found in Twilio account
   - "Object with ID does not exist" → WABA not linked yet

### Check 3: Verify Twilio API Credentials

Get fresh credentials from Twilio:

1. Go to: https://www.twilio.com/console
2. **Account → API Keys & Tokens**
3. Copy **Account SID** and **Auth Token**
4. Compare with Supabase secrets
5. If different, update in Supabase **Settings → Secrets**
6. Redeploy whatsapp-webhook function (or wait for auto-reload)

## Timeline Expectations

| Step | Duration |
|------|----------|
| Account upgrade | Immediate ✅ |
| WABA registration | 1-24 hours ⏱️ |
| Message delivery test | Once WABA active ✅ |
| Production ready | After WABA active ✅ |

## Current Credentials

```
Project: aqpwfurradxbnqvycvkm
Function: whatsapp-webhook
Phone: +39 328 1854639
Provider: Twilio (upgraded account)
Webhook: https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook
```

## Dealer Pilots Standing By

Once message delivery is confirmed:
1. ✅ Toelettatura Pet 🐾
2. ✅ Piccolo Supermarket PAM 🛒
3. ✅ NaturaSì Vomero 🥬
4. ✅ Yamamay/Carpisa Cimino Group 👔

All test data in database, ChatGPT responses ready, just waiting for delivery confirmation.

---

**Status**: 🔄 AWAITING TWILIO WABA APPROVAL (Step 2)

Next action: Complete Step 2 form in Twilio Dashboard
