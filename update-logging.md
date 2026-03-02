# WhatsApp Bot - Debug Checklist

## Step 1: Check if webhook received message
✅ Webhook returns 200 OK = message received

## Step 2: Check if message was saved to database
```bash
node check-messages.js
```
Should show recent inbound messages

## Step 3: Check webhook logs for errors
https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/functions
- Click "whatsapp-webhook"
- Go to "Logs" tab
- Look for RED errors in last 5 minutes

## Current Status:
- ✅ Webhook receives messages (200 OK)
- ❓ Message saved to DB? (need to check)
- ❓ ChatGPT processing error? (need logs)
- ❓ WhatsApp API error? (need logs)

## Next Action:
Check the webhook Logs tab for actual error messages!
