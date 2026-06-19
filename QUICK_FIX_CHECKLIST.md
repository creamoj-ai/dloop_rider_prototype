# 🚀 DLOOP Admin Panel - Quick Fix Checklist

## ✅ COMPLETATO
- [x] Fix URL Supabase in admin-panel/index.html (`.db.co` → `.supabase.co`)
- [x] Commit e push su GitHub (commit: a0beb1f)

---

## 📋 DA COMPLETARE ADESSO (20 min)

### 1. ⚙️ Configura Secrets Supabase (5 min)

```bash
# Login a Supabase
supabase login

# Link al progetto
cd dloop_rider_prototype
supabase link --project-ref aqpwfurradxbnqvycvkm

# Configura i 3 secrets necessari
supabase secrets set ADMIN_SECRET=password_sicura_123

supabase secrets set YAMAMAY_WEBHOOK_SECRET=yamamay_secret_2024

# IMPORTANTE: Nuovo formato FCM v1 API (non più FCM_SERVER_KEY!)
# Devi inserire il JSON del Firebase Service Account
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"...","private_key":"...","client_email":"..."}'
```

**Dove trovare FIREBASE_SERVICE_ACCOUNT:**
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download JSON file
4. Copia tutto il contenuto del file e incollalo nel comando sopra

---

### 2. 🖥️ Redeploy Admin Panel su Netlify (10 min)

**Opzione A: Auto-deploy da GitHub (consigliato)**

Se Netlify è configurato con CD, il deploy parte automaticamente dal push GitHub.

1. Vai su https://app.netlify.com/sites/steady-baklava-2ec7fa/deploys
2. Verifica che sia partito un nuovo deploy dopo il commit `a0beb1f`
3. Aspetta che diventi verde ✅

**Opzione B: Deploy manuale**

Se auto-deploy non funziona:

```bash
cd dloop_rider_prototype/admin-panel

# Reinstalla Netlify CLI se corrotto
npm install -g netlify-cli

# Deploy
netlify deploy --prod
```

---

### 3. 🧪 Test E2E (5 min)

#### 3.1 Test Creazione Ordine (curl)

```bash
# Sostituisci con dealer_id reale da dealers table
curl -X POST https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/receive-yamamay-order \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: yamamay_secret_2024" \
  -d '{
    "order_id": "YAM-TEST-001",
    "dealer_id": "PASTE_DEALER_UUID_HERE",
    "customer_name": "Test Customer",
    "customer_phone": "+39 320 1234567",
    "customer_address": "Via Toledo 100, Napoli"
  }'
```

**Expected output:**
```json
{
  "success": true,
  "order_id": "xxx-xxx-xxx",
  "distance_km": 1.2,
  "base_earning": 3.0
}
```

#### 3.2 Test Admin Panel

1. Apri https://steady-baklava-2ec7fa.netlify.app
2. Verifica che l'ordine creato appaia nella lista
3. Seleziona un rider dal dropdown
4. Click "Assegna Rider"

**Expected:**
- ✅ Messaggio "Ordine assegnato! Push inviato"
- ✅ Ordine scompare dalla lista pending

#### 3.3 Verifica DB

```sql
-- Controlla ordine creato
SELECT * FROM orders WHERE status IN ('pending', 'assigned') ORDER BY created_at DESC LIMIT 5;

-- Controlla dealer_id esiste
SELECT id, name FROM dealers WHERE status = 'active';
```

---

## 🐛 TROUBLESHOOTING

### Problema: Admin Panel carica ma non mostra ordini

**Fix:**
1. Apri DevTools (F12) → Console
2. Verifica errori di connessione
3. Controlla che SUPABASE_URL sia corretto (`.supabase.co` non `.db.co`)

### Problema: Assign Rider fallisce con "Unauthorized"

**Fix:**
```bash
# Verifica che ADMIN_SECRET sia configurato
supabase secrets list | grep ADMIN_SECRET

# Se mancante, riconfigura
supabase secrets set ADMIN_SECRET=password_sicura_123
```

### Problema: FCM Push non arriva all'app

**Causa:** FIREBASE_SERVICE_ACCOUNT non configurato o errato

**Fix:**
1. Controlla format JSON sia valido
2. Verifica che project_id corrisponda al tuo Firebase project
3. Verifica che la private_key sia completa (include `\n` nei newline)

---

## 📊 CHECKLIST FINALE

Prima di dichiarare il sistema funzionante:

- [ ] Secrets Supabase configurati (3/3)
- [ ] Admin Panel deployato su Netlify (fix URL applicato)
- [ ] Test curl webhook crea ordine ✅
- [ ] Admin Panel visualizza ordine ✅
- [ ] Assign Rider funziona ✅
- [ ] DB aggiornato con status 'assigned' ✅
- [ ] (Opzionale) FCM push arriva su app rider

---

## 🎯 PROSSIMO: Test con Ordine Reale Yamamay

Quando tutto funziona in test:

1. Configura webhook Yamamay reale nel loro e-commerce
2. Endpoint: `https://aqpwfurradxbnqvycvkm.supabase.co/functions/v1/receive-yamamay-order`
3. Header: `X-Webhook-Secret: yamamay_secret_2024`
4. Test con ordine di staging

---

**Last Updated:** 2026-06-19 13:17 UTC
**Status:** Admin Panel fixato, pronto per deploy e test
