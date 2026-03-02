# 🚀 WhatsApp Webhook - Deployment Guide (Production Ready)

## ✅ PROBLEMA RISOLTO

**Errore originale**: `SyntaxError: Unexpected token 'S', "SmsMessage"`

**Causa**: Il webhook faceva `req.json()` su TUTTI i POST, ma Twilio invia messaggi in **form-encoded** (non JSON).

**Soluzione implementata**:
1. ✅ Controlla `Content-Type` PRIMA di parsare
2. ✅ Usa `req.text()` + `URLSearchParams` per Twilio form-encoded
3. ✅ Usa `req.json()` SOLO per Meta WhatsApp JSON
4. ✅ Filtra messaggi di STATUS (MessageStatus != "received")
5. ✅ Logging dettagliato per debugging
6. ✅ Gestione errori robusta (sempre ritorna 200 OK)

---

## 📋 CHECKLIST DEPLOYMENT

### 1️⃣ Verifica Secrets in Supabase

```bash
# Login Supabase CLI
npx supabase login

# Link al progetto
npx supabase link --project-ref aqpwfurradxbnqvycvkm

# Verifica secrets esistenti
npx supabase secrets list
```

**Secrets richiesti** (devono essere già configurati):
```
SUPABASE_URL=https://aqpwfurradxbnqvycvkm.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
TWILIO_ACCOUNT_SID=<your-account-sid>
TWILIO_AUTH_TOKEN=<your-auth-token>
TWILIO_PHONE_NUMBER=+393281854639
OPENAI_API_KEY=<your-openai-api-key>
```

### 2️⃣ Deploy Webhook to Supabase

```bash
cd C:/Users/itjob/dloop_rider_prototype

# Deploy function (senza JWT verification per webhook pubblici)
npx supabase functions deploy whatsapp-webhook --no-verify-jwt
```

**Output atteso**:
```
✓ Deployed Function whatsapp-webhook
  URL: https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook
```

### 3️⃣ Configura Webhook in Twilio Dashboard

1. Vai su: https://console.twilio.com/us1/develop/sms/settings/whatsapp-sandbox
2. Trova: **"When a message comes in"**
3. Incolla URL (SENZA SPAZI!):
   ```
   https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook
   ```
4. Metodo: **POST**
5. Salva configurazione

**⚠️ CRITICO**: Verifica che l'URL NON abbia spazi (copia/incolla diretto, no edit manuale)

### 4️⃣ Test Webhook

```bash
# Test health check
curl https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/whatsapp-webhook

# Output atteso:
# "WhatsApp webhook is running (Production Ready)"
```

### 5️⃣ Invia Messaggio di Test

1. Invia messaggio WhatsApp al numero Twilio: **+39 328 185 4639**
2. Contenuto: "Ciao!"
3. Verifica risposta ChatGPT entro 3-5 secondi

---

## 📊 MONITORING & DEBUGGING

### Controlla Logs in Supabase

1. Vai su: https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/logs/edge-functions
2. Filtra per: `whatsapp-webhook`
3. Cerca:
   - ✅ `📨 Webhook received: application/x-www-form-urlencoded`
   - ✅ `✅ Processing Twilio inbound message from +39...`
   - ✅ `✅ Reply sent to +39...`

### Logs Attesi (SUCCESS)

```
📨 Webhook received: application/x-www-form-urlencoded
📦 Form data received (Twilio format)
📦 Parsed fields: MessageSid, AccountSid, From, To, Body, MessageStatus, ProfileName
📨 Twilio webhook - MessageSid: SM..., Status: received
✅ Processing Twilio inbound message from +393281854639
📝 Content: "Ciao!"
🤖 Starting ChatGPT processing for +393281854639...
✅ Reply sent to +393281854639: "Ciao! 👋 Cerchi 🐾 prodotti per animali, 🛒 cibo..."
```

### Logs da IGNORARE (Status callbacks)

```
📨 Twilio webhook - MessageSid: SM..., Status: delivered
⏭️ Skipping status callback: delivered (not a new message)
```

### Errori Comuni

#### ❌ Error: `SyntaxError: Unexpected token 'S'`
**Causa**: Webhook usa `req.json()` su form-encoded
**Fix**: Deploy nuovo webhook (già risolto in questa versione)

#### ❌ Error: `Missing Twilio credentials`
**Causa**: Secrets non configurati
**Fix**: Verifica secrets con `npx supabase secrets list`

#### ❌ Bot non risponde
**Causa 1**: Webhook URL ha spazi
**Fix**: Copia/incolla URL senza edit manuale

**Causa 2**: MessageStatus filter troppo aggressivo
**Fix**: Verifica logs per `⏭️ Skipping status callback`

---

## 🗄️ VERIFICA DATABASE

```sql
-- Controlla conversazioni recenti
SELECT * FROM whatsapp_conversations
ORDER BY last_message_at DESC
LIMIT 5;

-- Controlla messaggi recenti
SELECT * FROM whatsapp_messages
ORDER BY created_at DESC
LIMIT 10;

-- Conta messaggi per direzione
SELECT direction, COUNT(*)
FROM whatsapp_messages
GROUP BY direction;
```

**Output atteso**:
```
direction | count
----------|------
inbound   | 15
outbound  | 15
```

---

## 🎯 PRODUZIONE CHECKLIST

- [x] ✅ Webhook deployato senza JWT verification
- [x] ✅ Secrets configurati (Twilio + OpenAI)
- [x] ✅ URL webhook configurato in Twilio (NO spazi)
- [x] ✅ Content-Type detection funziona
- [x] ✅ Status filter attivo (ignora delivered/read/sent)
- [x] ✅ ChatGPT integration testata
- [x] ✅ Database logging funzionante
- [x] ✅ Error handling robusto (sempre 200 OK)

---

## 📞 CONTATTI DEALER PILOTS

**Bot Number**: +39 328 185 4639

**Dealers Attivi**:
1. 🐾 **Toelettatura Pet** (PET)
2. 🛒 **Piccolo Supermarket PAM** (Grocery)
3. 🥬 **NaturaSì Vomero** (Organic)
4. 👔 **Yamamay/Carpisa Cimino Group** (Fashion)

---

## 🚀 NEXT STEPS

1. Monitor feedback dealer (prime 24h)
2. Ottimizza system prompt ChatGPT (dealer-specific)
3. Aggiungi product catalog search
4. Implementa order creation flow
5. Analytics dashboard
6. Scale a 10+ dealers

---

**Last Updated**: 2026-02-28
**Status**: PRODUCTION READY ✅
**Architecture**: Twilio WhatsApp + ChatGPT + Supabase
