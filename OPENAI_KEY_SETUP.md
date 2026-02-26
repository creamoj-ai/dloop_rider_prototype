# 🔑 OpenAI API Key Setup

**Status**: CRITICAL - Required for bot to respond

## Step 1: Get Your OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com/account/api-keys)
2. Click **"Create new secret key"**
3. Copy the key (format: `sk-proj-xxxxx...`)
4. ⚠️ **Save it somewhere safe** - you won't see it again!

**Note**: If you have an existing key, use that. The key must:
- Be valid and not expired
- Have access to `gpt-3.5-turbo` model (available on all paid accounts)

---

## Step 2: Add to Supabase Secrets

### Option A: Via Supabase Dashboard

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to **Settings** → (scroll down) → **Secrets** / **Environment Variables**
4. Click **New Secret**
5. Key: `OPENAI_API_KEY`
6. Value: `sk-proj-xxxxx...` (paste your key)
7. Click **Add Secret**

### Option B: Via Supabase CLI

```bash
supabase secrets set OPENAI_API_KEY="sk-proj-xxxxx..."
```

---

## Step 3: Verify

### Test Locally

```bash
node -e "
const https = require('https');
const apiKey = 'sk-proj-xxxxx'; // Replace with your key

const req = https.request({
  hostname: 'api.openai.com',
  path: '/v1/models',
  method: 'GET',
  headers: { 'Authorization': 'Bearer ' + apiKey }
}, (res) => {
  console.log(res.statusCode === 200 ? '✅ KEY VALID' : '❌ KEY INVALID');
});

req.end();
"
```

### Test in Supabase

```bash
# Run this after adding secret to Supabase
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-simulate \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+393331234567",
    "text": "Ciao, test!",
    "name": "Test"
  }'

# Should return ChatGPT response (not an error)
```

---

## ✅ Checklist

- [ ] OpenAI account created
- [ ] API key generated
- [ ] Secret added to Supabase
- [ ] Test passed (returns ✅ response, not error)
- [ ] Ready to deploy!

---

## 🆘 Troubleshooting

### "401 Unauthorized"
→ API key is invalid or expired
→ Generate a new key from platform.openai.com

### "Project does not have access to model gpt-4o-mini"
→ Account doesn't have that model
→ Use `gpt-3.5-turbo` (which we've configured)
→ Check that the key is from a PAID account

### "Rate limit exceeded"
→ Account hit API limit
→ Wait for monthly reset or upgrade plan

---

**Next**: Run test after adding key to Supabase
