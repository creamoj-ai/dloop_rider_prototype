# OpenAI Configuration

## Get API Key

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign up or log in
3. Go to **API keys** (left sidebar)
4. Click **Create new secret key**
5. Name: `Dloop WhatsApp Bot`
6. **Copy immediately** (won't show again)
7. Format: `sk-proj-xxxxx...`

## Configure in Supabase

Add to Supabase secrets:

```bash
supabase secrets set OPENAI_API_KEY="sk-proj-xxxxx..."
```

Or via Dashboard:
1. **Settings** → **Secrets** (scroll down)
2. Key: `OPENAI_API_KEY`
3. Value: `sk-proj-xxxxx...`

## Model Selection

### Recommended: gpt-3.5-turbo

**Why**:
- Fast (~1-2 seconds)
- Cost-effective (~0.0005 per 1000 tokens)
- Good quality for customer service
- Supports Italian language well

**Config**:
```typescript
const response = await openai.createChatCompletion({
  model: "gpt-3.5-turbo",
  messages: [...],
  temperature: 0.7,
  max_tokens: 150
});
```

### Alternative: gpt-4

**Pros**: Better quality, better Italian understanding
**Cons**: Slower (~5-10 seconds), more expensive (~0.03 per 1000 tokens)

**Use when**: Quality is critical, speed is not

## System Prompt

This is the personality/instructions for the bot:

```typescript
const systemPrompt = `
Tu sei un assistente di servizio clienti amichevole per Dloop.

REGOLE PRINCIPALI:
1. Rispondi SEMPRE in italiano
2. Sii cordiale e professionale
3. Usa massimo 150 caratteri per risposta

RESPONSABILITÀ:
- Classificare richieste (ordine, prodotto, supporto)
- Estrarre prodotti dalle richieste dell'utente
- Confermare ordini in modo naturale
- Escalare problemi complessi al supporto umano

STILE:
- Amichevole ma professionale
- Usa emoji sparatamente (😊 va bene, non esagerare)
- Rispondi nella lingua dell'utente (di solito italiano)

Se non sai la risposta, dimanda al supporto umano.
`;
```

## Temperature Setting

Controls creativity vs accuracy:

```
Temperature: 0.0 = Very precise, deterministic
Temperature: 0.7 = Balanced (recommended)
Temperature: 1.0 = Creative, varied
Temperature: 2.0 = Very creative, potentially nonsensical
```

**For customer service**: Use 0.7 (balanced)

## Max Tokens

Limits response length:

```
Max tokens: 150 = Short responses (~40 words)
Max tokens: 300 = Medium responses (~100 words)
Max tokens: 2000 = Long responses
```

**For WhatsApp**: Use 150-300 (WhatsApp messages should be concise)

## Message Format

Send to OpenAI like this:

```json
{
  "model": "gpt-3.5-turbo",
  "temperature": 0.7,
  "max_tokens": 150,
  "messages": [
    {
      "role": "system",
      "content": "Tu sei un assistente di servizio clienti..."
    },
    {
      "role": "user",
      "content": "Vorrei ordinare un profumo"
    }
  ]
}
```

## Cost Estimation

### Pricing (as of Feb 2026)

- **gpt-3.5-turbo**: $0.0005 per 1K input tokens, $0.0015 per 1K output tokens
- **gpt-4**: $0.03 per 1K input tokens, $0.06 per 1K output tokens

### Usage Calculation

Average message:
- Input: ~50 tokens (customer message + system prompt)
- Output: ~40 tokens (bot response)

Cost per message:
- gpt-3.5-turbo: $0.00008 (~0.008 cents)
- gpt-4: $0.0015 (~0.15 cents)

Monthly cost (1000 messages/day):
- gpt-3.5-turbo: $2.40
- gpt-4: $45.00

## Rate Limits

Free tier:
- 3 requests/min
- 40,000 tokens/min

Paid tier:
- 3,500 requests/min
- 90,000 tokens/min
- Can request increase

**For bot in production**: Upgrade to paid tier

## Usage Monitoring

### Check Usage

1. Go to [Usage](https://platform.openai.com/account/usage/overview)
2. View:
   - Tokens used this month
   - Cost
   - Requests

### Set Budget Alert

1. Go to **Billing** → **Usage limits**
2. Set monthly limit (e.g., $10)
3. Get email when approaching limit

## Testing OpenAI

### Test via cURL

```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-proj-xxxxx" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello"}
    ]
  }'
```

Expected response:
```json
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Hello! How can I help you today?"
      }
    }
  ]
}
```

### Test via Node.js

```typescript
import { Configuration, OpenAIApi } from "openai";

const openai = new OpenAIApi(
  new Configuration({
    apiKey: process.env.OPENAI_API_KEY
  })
);

const response = await openai.createChatCompletion({
  model: "gpt-3.5-turbo",
  messages: [
    { role: "system", content: "You are helpful." },
    { role: "user", content: "Hello" }
  ]
});

console.log(response.data.choices[0].message.content);
```

## Troubleshooting

### Issue: "Invalid API key"

**Fix**:
1. Verify key format: `sk-proj-...`
2. Check key not expired (rotate every 90 days)
3. Check billing is active (go to [Billing](https://platform.openai.com/account/billing))
4. Check key has appropriate permissions

### Issue: "Rate limit exceeded"

**Fix**:
1. Upgrade to paid tier
2. Request rate limit increase: [https://platform.openai.com/account/rate-limits](https://platform.openai.com/account/rate-limits)
3. Implement exponential backoff in code
4. Batch requests if possible

### Issue: "Quota exceeded"

**Fix**:
1. Go to [Billing](https://platform.openai.com/account/billing/overview)
2. Check current usage
3. Upgrade plan if needed
4. Or wait for monthly reset

### Issue: Response is in English, not Italian

**Fix**:
1. Update system prompt to emphasize Italian:
   ```
   "Rispondi SEMPRE in italiano. Non usare altre lingue."
   ```
2. Explicitly request Italian in message:
   ```
   "Rispondi in italiano: Vorrei ordinare..."
   ```

## Advanced: Prompt Engineering

### Example 1: Order Processing

```
USER: "Voglio 2 Chanel e 1 Dior"

SYSTEM PROMPT:
"Estrai i prodotti richiesti e conferma il totale.
Rispondi con: 'Ho capito: 2x Chanel, 1x Dior. Totale €X,XX. Confermo?'"

EXPECTED RESPONSE:
"Ho capito: 2x Chanel, 1x Dior. Totale €250,00. Confermo?"
```

### Example 2: Product Search

```
USER: "Quali profumi avete?"

SYSTEM PROMPT:
"Suggerisci i 3 profumi più popolari con breve descrizione."

EXPECTED RESPONSE:
"Consiglio questi profumi:
- Chanel No.5 (classico)
- Dior J'adore (floreale)
- Guerlain La Vie Est Belle (dolce)"
```

### Example 3: Support Escalation

```
USER: "Il mio ordine non è arrivato da una settimana"

SYSTEM PROMPT:
"Se è urgente o richiede supporto umano, offri di contattare il supporto"

EXPECTED RESPONSE:
"Mi scuso per l'inconveniente. Ti passo al nostro team di supporto
che verificherà lo stato dell'ordine al più presto. Sto collegando..."
```

## References

- [OpenAI API Docs](https://platform.openai.com/docs/api-reference/chat)
- [Chat Completions](https://platform.openai.com/docs/guides/gpt/chat-completions-api)
- [Prompt Engineering](https://platform.openai.com/docs/guides/prompt-engineering)
- [Token Counter](https://platform.openai.com/tokenizer)

---

**Last Updated**: 2026-02-26
**Current Model**: gpt-3.5-turbo
**Status**: Configured
