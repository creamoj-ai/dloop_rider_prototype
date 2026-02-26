# WhatsApp Bot MVP - Deployment Guide

**Status**: Production-Ready | **Last Updated**: 2026-02-26

## 🎯 Overview

Complete guide for deploying the Dloop WhatsApp Bot MVP with ChatGPT integration. This bot handles customer and dealer inquiries via WhatsApp with intelligent NLU routing.

## 📋 Prerequisites

- Supabase account with active project
- Meta Business Account with WhatsApp API access
- OpenAI API key (GPT-3.5-turbo or GPT-4)
- Node.js 18+ (for local deployment helpers)
- Git (for version control)

## 🚀 Quick Start (3 Steps)

### Step 1: Set Environment Variables
```bash
cd deployment_haiku/scripts
node set-secrets.js
```

### Step 2: Deploy Functions
```bash
./DEPLOY.sh
```

### Step 3: Verify Deployment
```bash
node verify-deployment.js
```

## 📦 What Gets Deployed

### Edge Functions (6 functions)
1. **whatsapp-webhook** - Main message receiver
2. **whatsapp-simulate** - Test endpoint
3. **whatsapp-webhook-v2** - Fallback processor
4. **whatsapp-test-webhook** - Internal test runner
5. **whatsapp-notify** - Push notification sender
6. **setup-whatsapp-schema** - Schema initializer

### Database Schema
- `whatsapp_conversations` - Conversation history
- `whatsapp_messages` - All messages (inbound/outbound)
- `whatsapp_order_relays` - Order pipeline tracking

### Secrets Required
- `DB_URL` - Supabase connection string
- `DB_ANON_KEY` - Anonymous key
- `DB_ROLE_KEY` - Service role key
- `OPENAI_API_KEY` - ChatGPT API key
- `WHATSAPP_ACCESS_TOKEN` - Meta API token (optional for testing)
- `WHATSAPP_PHONE_NUMBER_ID` - Meta phone ID (optional for testing)

## 🔧 Configuration

### Meta Business Account Setup
1. Enable WhatsApp API in Business Settings
2. Get phone number ID and access token
3. Configure webhook:
   - URL: `https://<project>.supabase.co/functions/v1/whatsapp-webhook`
   - Verify Token: `dloop_wa_verify_2026`
   - Subscribe to: `messages` field

### OpenAI Integration
- Model: `gpt-3.5-turbo` (configurable)
- System Prompt: Italian-friendly customer service bot
- Temperature: 0.7 (balanced creativity/accuracy)

## 📊 Testing Workflow

1. **Unit Test**: `node diagnose-bot.js`
2. **Integration Test**: `node test-webhook-directly.js`
3. **Meta Test Number**: `node test-with-meta-test-number.js`
4. **Live Test**: Send message from real WhatsApp number

## 🚨 Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| 400 Invalid JSON | Malformed webhook payload | Check `test-webhook-directly.js` format |
| No messages in DB | Meta not sending to webhook | Verify webhook URL in Meta Business Account |
| Bot not responding | ChatGPT error or token invalid | Check OPENAI_API_KEY in secrets |
| Messages not sent | WhatsApp token expired | Refresh token in Meta Business Account |

## 🔄 Rollback Procedure

If deployment fails:
```bash
git revert HEAD
supabase functions delete whatsapp-webhook
supabase functions delete whatsapp-simulate
# Then redeploy with verified code
```

## 📈 Monitoring

Check function logs:
```
https://supabase.com/dashboard/project/<ref>/functions/whatsapp-webhook
```

Check database:
```sql
SELECT * FROM whatsapp_messages
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;
```

## 🎓 Architecture

- **Inbound Flow**: Meta → Webhook → Processor → ChatGPT → DB → WhatsApp Response
- **Customer vs Dealer**: Auto-routing via `rider_contacts` table
- **Async Processing**: Edge functions handle requests, database queues responses

## 📞 Support

For issues:
1. Check `TROUBLESHOOTING.md`
2. Review Supabase function logs
3. Run `diagnose-bot.js` for system health check
4. Check `META_SETUP.md` for webhook configuration

---

**Next**: Read `02_DEPLOYMENT_CHECKLIST.md` for step-by-step verification
