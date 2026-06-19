# 📬 SETUP NOTIFICHE - Guida Rapida

## 📧 TASK #6: Setup Email (Resend)

### Step 1: Crea Account Resend (5 min)

1. Vai su https://resend.com/signup
2. Crea account gratuito
3. Verifica email

**FREE TIER:** 100 email/giorno, 3,000/mese - **Sufficiente per MVP**

---

### Step 2: Ottieni API Key

1. Dashboard → API Keys → Create API Key
2. Nome: `dloop-mvp`
3. Permission: `Full Access`
4. **Copia la key** (inizia con `re_...`)

---

### Step 3: Configura Domain (Opzionale per MVP)

**Per MVP puoi usare dominio Resend:**
- FROM email: `onboarding@resend.dev`
- **Funziona subito**, ma finisce in spam

**Per produzione (consigliato dopo MVP):**
1. Dashboard → Domains → Add Domain
2. Aggiungi DNS records (SPF, DKIM)
3. Verifica dominio
4. FROM email: `noreply@tuodominio.com`

---

### Step 4: Aggiungi Secrets a Supabase

1. Vai su Supabase Dashboard → Project Settings → Edge Functions
2. Aggiungi secrets:

```bash
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxx
FROM_EMAIL=onboarding@resend.dev
```

Oppure via CLI:

```bash
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxxxxxx
supabase secrets set FROM_EMAIL=onboarding@resend.dev
```

---

### Step 5: Test Email

Testa la function `notify-merchant`:

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/notify-merchant \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": "xxx-xxx-xxx",
    "new_status": "assigned"
  }'
```

Controlla inbox merchant per ricevere email ✅

---

## 💬 TASK #7: Setup WhatsApp (Opzionale MVP)

### ⚠️ ATTENZIONE
**WhatsApp Business API richiede:**
- Meta Business Account
- Numero telefono dedicato
- Template pre-approvati (24-48h approval)
- Setup tecnico complesso

**Per MVP: SKIPPA WhatsApp, usa solo Email**

Se vuoi comunque procedere:

---

### Step 1: Meta Business Account

1. Vai su https://business.facebook.com
2. Crea Business Account
3. Verifica identità aziendale

---

### Step 2: WhatsApp Business API Setup

1. Meta Business Suite → WhatsApp Manager
2. Create New WhatsApp Account
3. Aggiungi numero telefono (deve essere nuovo, non usato su WhatsApp normale)
4. Verifica numero con SMS

---

### Step 3: Template Messages (Richiede Approval)

Crea template per ogni status ordine:

**Template 1: `order_assigned`**
```
✅ Ordine #{{1}} assegnato a rider!
Il rider arriverà presto per il ritiro.
```

**Template 2: `order_picked_up`**
```
📦 Ordine #{{1}} ritirato
In consegna verso {{2}}. ETA: ~{{3}} min.
```

**Template 3: `order_delivered`**
```
🎉 Ordine #{{1}} consegnato!
Grazie per aver usato DLOOP.
```

**Template 4: `order_cancelled`**
```
❌ Ordine #{{1}} annullato
Per assistenza contattaci.
```

**Approval time:** 24-48 ore

---

### Step 4: Get Access Token

1. WhatsApp Manager → Settings → API Access
2. Generate Access Token (permanente)
3. **Copia token** (inizia con `EAA...`)

---

### Step 5: Aggiungi Secrets Supabase

```bash
supabase secrets set WHATSAPP_TOKEN=EAAxxxxxxxxx
supabase secrets set WHATSAPP_PHONE_NUMBER_ID=xxxxxxxxxxxxx
```

---

### Step 6: Implementa in `notify-merchant`

Decommentare sezione WhatsApp nella function (già predisposta):

```typescript
// In notify-merchant/index.ts linea ~190
async function sendWhatsApp(phoneNumber, templateName, params) {
  const WHATSAPP_API_URL = `https://graph.facebook.com/v18.0/${PHONE_NUMBER_ID}/messages`;
  const WHATSAPP_TOKEN = Deno.env.get("WHATSAPP_TOKEN");

  const response = await fetch(WHATSAPP_API_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${WHATSAPP_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to: phoneNumber,
      type: "template",
      template: {
        name: templateName,
        language: { code: "it" },
        components: [{
          type: "body",
          parameters: params.map(p => ({ type: "text", text: p }))
        }]
      }
    })
  });

  return response.ok;
}
```

---

## ✅ RACCOMANDAZIONE MVP

**FASE 1 (Settimana 1-2):**
- ✅ Email con Resend (funziona subito, gratis)
- ❌ WhatsApp (skippa, troppo complesso per MVP)

**FASE 2 (Dopo validazione pilota):**
- ✅ WhatsApp (se merchant lo richiedono esplicitamente)

---

## 🧪 Come Testare

### Test Email:

1. Crea ordine test (via webhook Yamamay simulato)
2. Assegna rider da Admin Panel
3. Controlla email merchant → dovrebbe ricevere "Ordine Assegnato"
4. Cambia status ordine in app rider: `picked_up` → email "Ritirato"
5. Consegna → email "Consegnato"

### Test WhatsApp (se configurato):

1. Stesso flusso
2. Verifica che merchant riceva WhatsApp message oltre a email
3. Controlla WhatsApp Manager → Analytics per delivery rate

---

## 📊 Monitoring

**Email (Resend Dashboard):**
- Email inviate/giorno
- Delivery rate
- Bounce rate
- Spam complaints

**WhatsApp (Meta Business):**
- Messages sent
- Delivery rate
- Read rate
- Template performance

---

## ⚠️ COSTI

| Servizio | Free Tier | Costo Oltre Free |
|----------|-----------|------------------|
| Resend Email | 3,000/mese | $20/mese (50k email) |
| WhatsApp | 1,000 conversazioni/mese | $0.005-0.02 per messaggio |

**Per MVP Yamamay (15 ordini/giorno):**
- Email: ~60/giorno × 4 notifiche = 240/giorno → **GRATIS** (< 3k/mese)
- WhatsApp: ~60/giorno = 1,800/mese → **$0** (< 1k free)

**TOTALE MVP: $0** ✅

---

## 🔧 Troubleshooting

### Email non arrivano:

1. Controlla Resend Dashboard → Logs
2. Verifica `FROM_EMAIL` secret in Supabase
3. Controlla spam folder
4. Testa con email personale prima di usare email merchant

### WhatsApp non arriva:

1. Verifica template approval status
2. Controlla formato numero: `+393201234567` (no spazi)
3. Verifica Access Token non scaduto
4. Check rate limits (250 messaggi/24h per numero non verificato)

---

**Next:** Task #8 - Test flusso completo end-to-end 🚀
