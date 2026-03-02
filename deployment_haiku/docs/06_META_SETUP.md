# Meta Business Account Setup

## Prerequisites

- Meta Business Account created
- WhatsApp number obtained (+39 328 1854639)
- Business Manager access

## Step 1: Enable WhatsApp API

1. Go to [Meta Business Platform](https://business.facebook.com)
2. Select your business
3. Go to **Settings** → **Apps and Websites**
4. Find or add "WhatsApp" app
5. Click **Settings** under WhatsApp
6. Enable **WhatsApp API** (if not already enabled)

## Step 2: Get Phone Number ID

1. In WhatsApp settings, find **Phone Numbers** section
2. Select your WhatsApp number: `+39 328 1854639`
3. Copy **Phone Number ID**: `979991158533832`
4. Save this value

## Step 3: Generate Access Token

1. Go to **Settings** → **System Users**
2. Create new system user (if needed):
   - Name: `Dloop WhatsApp Bot`
   - Role: `Admin`
3. Select system user
4. Click **Generate new token**
5. Choose app: **WhatsApp**
6. Choose permissions:
   - `whatsapp_business_messaging` ✅
   - `whatsapp_business_account_management` ✅
7. Token expires in: **60 days** (choose longest available)
8. **Copy token** (starts with `EAAxxxxxx`)

**⚠️ Important**: Store this token securely. You'll need it in the next step.

## Step 4: Configure Webhook

### 4.1: Register Webhook URL

1. In WhatsApp settings, find **Webhooks**
2. Click **Select Subscriptions** (or **Manage subscriptions**)
3. Fill in:
   - **Callback URL**: `https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook`
   - **Verify Token**: `dloop_wa_verify_2026`
4. Click **Verify and Save**

**How verification works**:
- Meta sends: `GET .../webhook?hub.mode=subscribe&hub.verify_token=dloop_wa_verify_2026&hub.challenge=TOKEN`
- Our webhook responds with the `challenge` value
- If matches, webhook is verified ✅

### 4.2: Subscribe to Events

After webhook is verified, subscribe to message events:

1. Go to **Webhooks** → **Manage Subscriptions**
2. Check these fields:
   - ✅ `messages` (REQUIRED - to receive incoming messages)
   - ✅ `message_template_status_update` (optional)
   - ✅ `message_status` (optional - for delivery status)
3. Click **Save Changes**

## Step 5: Upload Privacy Policy & Terms

Meta requires:

1. Go to **Settings** → **Webhook Configuration**
2. Add **Privacy Policy URL** (if not present):
   - URL: `https://dloop.app/privacy` (or your URL)
   - Must be HTTPS
   - Must be publicly accessible
3. Add **Terms of Service** (if not present):
   - URL: `https://dloop.app/terms`

## Step 6: Verification & Testing

### 6.1: Verify Webhook Status

1. Go to **Webhooks** section
2. You should see:
   - Status: **Active** (green checkmark)
   - Last activity: Recent timestamp
   - Events: `messages` ✅

### 6.2: Test Webhook

Option A: Using Meta's Test Number
```
Use Meta's official test number: 15551505103
This number can test the webhook without needing a real customer
```

Option B: Using Your Test Number
```
If you have a test WhatsApp account, send a message to your bot number
Check logs to see if webhook receives it
```

### 6.3: Check Webhook Logs

Meta provides webhook logs:

1. Go to **Webhooks** → **Webhook Logs** (if available)
2. Should see `POST` requests to your webhook URL
3. Status should be `200 OK`

If not visible, check Supabase logs:
```
Supabase Dashboard → Functions → whatsapp-webhook → Logs
```

## Step 7: Configure in Supabase

Add these secrets to your Supabase project:

### Via CLI:
```bash
supabase secrets set WHATSAPP_PHONE_NUMBER_ID="979991158533832"
supabase secrets set WHATSAPP_ACCESS_TOKEN="EAXXXXXX..."
```

### Via Dashboard:
1. Go to **Settings** → **Database** (scroll down to Secrets)
2. Add new secret:
   - Key: `WHATSAPP_PHONE_NUMBER_ID`
   - Value: `979991158533832`
3. Add new secret:
   - Key: `WHATSAPP_ACCESS_TOKEN`
   - Value: `EAAxxxxx...`

## Complete Webhook Configuration Checklist

- [ ] Callback URL registered: `https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook`
- [ ] Verify Token set: `dloop_wa_verify_2026`
- [ ] Webhook verified (status = Active)
- [ ] Subscribed to `messages` field
- [ ] Privacy Policy URL added
- [ ] Phone Number ID saved: `979991158533832`
- [ ] Access Token generated and saved
- [ ] Secrets added to Supabase
- [ ] Webhook logs showing incoming requests

## Testing After Setup

### Test 1: Send Message from Test Number
```
Contact: 15551505103 (Meta test number)
Message: "Ciao, è un test"
Expected: Bot responds in Italian
```

### Test 2: Check Webhook Logs
```
Supabase Dashboard → Functions → whatsapp-webhook → Logs
Should see successful POST requests
```

### Test 3: Run Diagnostics
```bash
node diagnose-bot.js
Expected: Inbound messages count > 0
```

## Troubleshooting

### Issue: Webhook returns 403 Forbidden

**Cause**: Verify token mismatch

**Fix**:
1. Check Meta has token: `dloop_wa_verify_2026`
2. Check Webhook code has same token
3. Re-verify webhook in Meta

### Issue: Webhook returns 404 Not Found

**Cause**: Webhook URL doesn't exist or function not deployed

**Fix**:
```bash
# Verify function deployed
supabase functions list | grep whatsapp-webhook

# Redeploy if missing
supabase functions deploy whatsapp-webhook

# Test function
curl https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook
```

### Issue: No messages received from Meta

**Cause**:
1. Webhook not subscribed to `messages` field
2. Phone number inactive
3. Message doesn't meet Meta requirements

**Fix**:
1. Check subscription: Meta → Webhooks → Manage Subscriptions
2. Verify `messages` field is checked ✅
3. Check phone number is active in Meta Business Account
4. Message must be plain text (no special chars initially)

### Issue: Messages sent but getting delivery errors

**Cause**: Access token expired or invalid

**Fix**:
```
1. Generate new access token
2. Update in Supabase secrets
3. Redeploy webhook function
supabase secrets set WHATSAPP_ACCESS_TOKEN="NEW_TOKEN"
supabase functions deploy whatsapp-webhook
```

## Important Notes

⚠️ **Token Security**:
- Never commit tokens to git
- Use Supabase secrets, not environment variables
- Rotate tokens every 30 days
- Revoke old tokens immediately

⚠️ **Rate Limits**:
- Meta has rate limits on API calls
- Test number: lower limits
- Production: upgrade for higher limits

⚠️ **Message Format**:
- Use text messages for testing
- Media (images, audio) requires additional setup
- Template messages have specific format

## Reference

- [Meta WhatsApp API Docs](https://developers.facebook.com/docs/whatsapp/cloud-api/)
- [Webhook Documentation](https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks/setup)
- [Test Number Guide](https://developers.facebook.com/docs/whatsapp/cloud-api/get-started#test-number)

---

**Last Updated**: 2026-02-26
**Status**: Setup complete for +39 328 1854639
