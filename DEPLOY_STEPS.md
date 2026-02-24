# 🚀 WhatsApp Bot MVP - Quick Deployment

Your credentials are saved. Follow these **3 simple steps**:

---

## Step 1️⃣ Set Secrets (2 minutes)

### Go to Supabase Dashboard:
👉 https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/settings/secrets

### Click "New Secret" and add these 4 secrets:

**Secret 1:**
```
Name: OPENAI_API_KEY
Value: sk-proj-pPdW5MvMqHNPlQ5xuJUgOS-e7r1pqo1YOWfzjYwHPBBvje5cV259qkmZKb2KKyHhbt71AqvcqPT3BlbkFJIKzNcckvVZZIp3ek+hR2PVXuVIofypAoTeioLR4MpSVMoNe38utc4x2Nm_cT1u8cRbvg-6F-KIA
```

**Secret 2:**
```
Name: WHATSAPP_PHONE_NUMBER_ID
Value: 328185463900391
```

**Secret 3:**
```
Name: WHATSAPP_ACCESS_TOKEN
Value: EAAVfoVVjNTUBQ9ZAJ36GRcv4PFT1pZCuqKrlwnqBAvTbMiR2SikDZB4ofZAsuZA8HCXASwJv6QQJGx7y4bkNSxdX9cg8o6gOZBAncqVmbWDABapDQ5ic7ZBzE70YN3AGvK1QtrIviaHY7Q6cakHhazTPo9B1sddFKgPr6pXxTeythClUMYkKYZCvC84deBS5imy1KLWq73AYlmPLSS1b1s1ZBR30PdVECfLcBIJo2xZCTZAfL1WdEZBrllDQkVNl7meo4z8KC9NhZAy0hw3gE2YhlHwZDZD
```

**Secret 4:**
```
Name: WHATSAPP_VERIFY_TOKEN
Value: dloop_wa_verify_2026
```

✅ Click "Save" for each secret.

---

## Step 2️⃣ Deploy Functions (5 minutes)

### Option A: Via Dashboard (Easiest)

1. Go to: **Functions** → **Deployments**
2. Click **"Deploy from GitHub"** or **"Deploy"**
3. Upload the `supabase/functions/` directory
4. Wait for deployment to complete

### Option B: Via CLI

```bash
# Install Supabase CLI
brew install supabase/tap/supabase  # macOS
# Or download from: https://github.com/supabase/cli/releases

# Login
supabase login

# Deploy
supabase deploy --project-ref imhjdsjtaommutdmkouf
```

✅ Functions deployed successfully!

---

## Step 3️⃣ Test the Bot (2 minutes)

### Test Customer Pipeline:

```bash
curl -X POST "https://imhjdsjtaommutdmkouf.supabase.co/functions/v1/whatsapp-simulate" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331111111",
    "text": "Ciao, mi servono prodotti per il gatto",
    "name": "Test Customer"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "reply": "Perfetto! Cerco prodotti per gatti nel catalogo...",
  "conversation_id": "conv_xxx",
  "routed_to": "customer"
}
```

### Test Dealer Pipeline:

```bash
curl -X POST "https://imhjdsjtaommutdmkouf.supabase.co/functions/v1/whatsapp-simulate" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+39331111111",
    "text": "OK",
    "name": "Toelettatura Pet",
    "role": "dealer"
  }'
```

✅ Bot is working!

---

## Step 4️⃣ Setup Meta Webhook (5 minutes)

### Go to Meta Developer Console:
👉 https://developers.facebook.com/apps

### Register Webhook:

**Webhook URL:**
```
https://imhjdsjtaommutdmkouf.supabase.co/functions/v1/whatsapp-webhook
```

**Verify Token:**
```
dloop_wa_verify_2026
```

**Subscribe to:**
- ✓ `messages`
- ✓ `message_status`

✅ Webhook registered!

---

## 🎉 You're Done!

The bot is now live!

### Next: Test with Real Dealers

1. Send a message to the bot number **+39 328 1854639**
2. Try: `"Ciao, mi servono prodotti"`
3. The bot will respond with products from the catalog

### Monitor & Troubleshoot

**Check Logs:**
https://supabase.com/dashboard/project/imhjdsjtaommutdmkouf/functions

**View Messages:**
```sql
SELECT * FROM whatsapp_messages ORDER BY created_at DESC LIMIT 10;
```

**View Conversations:**
```sql
SELECT * FROM whatsapp_conversations ORDER BY last_message_at DESC LIMIT 10;
```

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Webhook verification failed" | Make sure `WHATSAPP_VERIFY_TOKEN` matches Meta setting |
| "OpenAI API error" | Verify key is correct and has credits available |
| "Dealer not found" | Check dealer phone is in `rider_contacts` table |
| "WhatsApp send failed" | Check `WHATSAPP_ACCESS_TOKEN` hasn't expired (refresh in Meta) |

---

## 📞 Need Help?

Check the full guide: `WHATSAPP_BOT_DEPLOYMENT.md`

Happy deploying! 🚀
