# Quick Fix Guide - WhatsApp Bot Not Responding

## Root Cause
OpenAI API key is **invalid/expired** in Supabase secrets

## Error Evidence
```
Testing with whatsapp-simulate returns:
"OpenAI API error 401: Incorrect API key provided"
```

## 3-Step Fix

### 1. Get New OpenAI API Key
- Go to: https://platform.openai.com/account/api-keys
- Click "Create new secret key"
- Copy the full key (starts with `sk-proj-`)

### 2. Update Supabase Secret
```bash
cd C:/Users/itjob/dloop_rider_prototype
supabase secrets set OPENAI_API_KEY="sk-proj-YOUR-NEW-KEY-HERE"
```

### 3. Test
```bash
# Test with simulate function
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{"phone":"+393281854639","text":"Ciao","name":"Test"}'

# Should return ChatGPT response, not 401 error
```

## What's Working
- ✅ Webhook receives messages from Meta
- ✅ Message parsing is correct
- ✅ Database schema exists and is accessible
- ✅ Async processing pattern is correct

## What's Broken
- ❌ OpenAI API key is invalid
- ❌ ChatGPT cannot generate responses
- ❌ Users don't receive bot responses (no feedback)

## Files Involved
- `/supabase/functions/whatsapp-webhook/index.ts` - Webhook entry point
- `/supabase/functions/whatsapp-webhook/processor.ts` - Message processing
- `/supabase/functions/_shared/openai.ts` - OpenAI client (uses OPENAI_API_KEY)
- `/supabase/functions/whatsapp-simulate/index.ts` - Test endpoint

## Complete Diagnostic
See: `WEBHOOK_DIAGNOSTIC_2026-03-10.md` in this directory
