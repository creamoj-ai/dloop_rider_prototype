# 🚀 DLOOP MVP - Deployment & Test Guide

## 📦 COSA ABBIAMO COSTRUITO

Sistema completo per MVP Yamamay:

```
Yamamay E-commerce
        ↓ webhook
Cloud Function (receive-yamamay-order)
        ↓ insert DB
Supabase (orders table)
        ↓ real-time
Admin Panel Web (SHOSHY)
        ↓ assign rider
Cloud Function (assign-rider)
        ↓ FCM push
App Rider Flutter
        ↓ status updates
Cloud Function (notify-merchant)
        ↓ email + whatsapp
Merchant (Yamamay)
```

---

## 🗂️ FILE CREATI

### 1. Database
- ✅ `sql/40_create_dealers_table.sql` - Tabella merchant

### 2. Cloud Functions
- ✅ `supabase/functions/receive-yamamay-order/index.ts` - Webhook receiver
- ✅ `supabase/functions/assign-rider/index.ts` - Assegnazione manuale rider
- ✅ `supabase/functions/notify-merchant/index.ts` - Notifiche email/WhatsApp

### 3. Admin Panel
- ✅ `admin-panel/index.html` - Dashboard per SHOSHY

### 4. Guide
- ✅ `SETUP_NOTIFICATIONS.md` - Setup Email + WhatsApp

---

## 🛠️ DEPLOYMENT STEP-BY-STEP

### STEP 1: Setup Database (10 min)

1. Apri Supabase SQL Editor
2. Esegui `sql/40_create_dealers_table.sql`
3. Verifica che siano stati creati 3 dealer:
   ```sql
   SELECT * FROM dealers WHERE status = 'active';
   ```

**Expected output:** 3 righe (Yamamay, Pizzeria Sorbillo, Farmacia)

---

### STEP 2: Deploy Cloud Functions (15 min)

#### 2.1 Install Supabase CLI

```bash
# Se non hai già Supabase CLI
npm install -g supabase

# Login
supabase login
```

#### 2.2 Link Project

```bash
cd dloop_rider_prototype
supabase link --project-ref YOUR_PROJECT_ID
```

#### 2.3 Set Secrets

```bash
# Admin secret per assign-rider function
supabase secrets set ADMIN_SECRET=your_secure_admin_key_change_me

# Webhook secret per Yamamay
supabase secrets set YAMAMAY_WEBHOOK_SECRET=yamamay_secret_key_123

# Email (Resend)
supabase secrets set RESEND_API_KEY=re_your_resend_api_key
supabase secrets set FROM_EMAIL=onboarding@resend.dev

# FCM (Firebase)
supabase secrets set FCM_SERVER_KEY=your_firebase_server_key

# WhatsApp (opzionale - skippa per MVP)
# supabase secrets set WHATSAPP_TOKEN=EAAxxxxx
# supabase secrets set WHATSAPP_PHONE_NUMBER_ID=xxxxx
```

#### 2.4 Deploy Functions

```bash
supabase functions deploy receive-yamamay-order
supabase functions deploy assign-rider
supabase functions deploy notify-merchant
```

**Expected output:**
```
✓ Deployed function receive-yamamay-order
✓ Deployed function assign-rider
✓ Deployed function notify-merchant
```

---

### STEP 3: Setup Admin Panel (5 min)

#### 3.1 Modifica `admin-panel/index.html`

Apri file e sostituisci:

```javascript
const SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
const ADMIN_SECRET = 'your_secure_admin_key_change_me'; // Stesso di STEP 2.3
```

#### 3.2 Host Admin Panel

**Opzione A: Netlify (più semplice)**

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
cd admin-panel
netlify deploy --prod

# Segui prompt, seleziona "Create & configure a new site"
```

**Opzione B: Vercel**

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
cd admin-panel
vercel --prod
```

**Opzione C: GitHub Pages (manuale)**

1. Crea repo `dloop-admin-panel`
2. Push `index.html`
3. Settings → Pages → Enable
4. Access: `https://YOUR_USERNAME.github.io/dloop-admin-panel`

**Output:** URL pubblico tipo `https://dloop-admin-abc123.netlify.app`

---

### STEP 4: Setup Email (Resend) (10 min)

Segui guida in `SETUP_NOTIFICATIONS.md` → Task #6

**Quick steps:**
1. Signup su https://resend.com
2. Get API key
3. Add secret: `supabase secrets set RESEND_API_KEY=re_...`
4. Test invio email

---

### STEP 5: Test FCM Push (10 min)

#### 5.1 Installa App Rider su Device Test

```bash
cd dloop_rider_prototype
flutter build apk
# Oppure
flutter run
```

#### 5.2 Verifica FCM Token Salvato

1. Login nell'app con account rider
2. Verifica che FCM token sia salvato in DB:

```sql
SELECT rider_id, token, is_active
FROM fcm_tokens
WHERE rider_id = 'YOUR_RIDER_UUID';
```

**Expected:** 1 riga con token attivo

---

## 🧪 TEST END-TO-END COMPLETO

### TEST 1: Webhook Yamamay → Crea Ordine

Simula webhook Yamamay:

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/receive-yamamay-order \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Secret: yamamay_secret_key_123" \
  -d '{
    "order_id": "YAM-12345",
    "dealer_id": "UUID_YAMAMAY_FROM_DEALERS_TABLE",
    "customer_name": "Mario Rossi",
    "customer_phone": "+39 320 1234567",
    "customer_address": "Via Toledo 100, Napoli"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "order_id": "xxx-xxx-xxx",
  "distance_km": 1.2,
  "base_earning": 3.0,
  "restaurant_name": "Yamamay Napoli Centro"
}
```

**Verifica DB:**
```sql
SELECT * FROM orders WHERE restaurant_name = 'Yamamay Napoli Centro' ORDER BY created_at DESC LIMIT 1;
```

✅ **PASS:** Ordine creato con distance_km e base_earning calcolati

---

### TEST 2: Admin Panel → Assegna Rider

1. Apri Admin Panel: `https://dloop-admin-abc123.netlify.app`
2. Vedi ordine pending creato al TEST 1
3. Seleziona rider dal dropdown
4. Click "Assegna Rider"

**Expected:**
- ✅ Notifica success: "Ordine assegnato! Push inviato"
- ✅ Ordine scompare dalla lista pending

**Verifica DB:**
```sql
SELECT status, assigned_rider_id FROM orders WHERE id = 'ORDER_ID_TEST1';
```

**Expected:** `status = 'assigned'`, `assigned_rider_id = RIDER_UUID`

---

### TEST 3: FCM Push → App Rider Riceve Notifica

**Su device con app rider:**

1. Check notification tray → dovrebbe comparire:
   ```
   Nuovo Ordine Assegnato! 🎉
   Yamamay Napoli Centro → 1.2km | €3.00
   ```

2. Tap notification → app si apre su schermata ordine

3. Verifica dati ordine nell'app:
   - ✅ Restaurant: Yamamay Napoli Centro
   - ✅ Cliente: Mario Rossi
   - ✅ Indirizzo: Via Toledo 100, Napoli
   - ✅ Distanza: 1.2 km
   - ✅ Compenso: €3.00

**Expected:** Tutti i dati corretti ✅

---

### TEST 4: Rider Status Update → Email Merchant

#### 4.1 Rider Accetta Ordine

Nell'app rider:
1. Tap su ordine
2. Tap "Accetta"

**Expected:** Status → `accepted`

#### 4.2 Rider Ritira Ordine

1. Tap "Ritirato"

**Expected:**
- Status → `picked_up`
- 📧 Email inviata a merchant (Yamamay)

**Controlla inbox Yamamay:**
```
Oggetto: 📦 Ordine #XXX ritirato - In consegna
Corpo: Il rider ha ritirato l'ordine ed è in viaggio verso il cliente.
       Destinazione: Mario Rossi, Via Toledo 100
       ETA: ~5 minuti
```

✅ **PASS:** Email ricevuta

#### 4.3 Rider Consegna

1. Tap "Consegnato"

**Expected:**
- Status → `delivered`
- 📧 Email "Ordine consegnato" a merchant

**Controlla inbox:**
```
Oggetto: 🎉 Ordine #XXX consegnato con successo
```

✅ **PASS:** Email ricevuta

---

### TEST 5: WhatsApp (Opzionale - Se Configurato)

Stesso flusso TEST 4, ma verifica che merchant riceva anche WhatsApp message oltre a email.

---

## ✅ CHECKLIST PRE-PRODUZIONE

- [ ] Database dealers table created
- [ ] 3 Cloud Functions deployed
- [ ] Secrets configurati (ADMIN_SECRET, RESEND_API_KEY, FCM_SERVER_KEY)
- [ ] Admin Panel hosted e accessibile
- [ ] Resend account creato + API key attiva
- [ ] App rider installata su device test
- [ ] FCM token salvato in DB per rider test
- [ ] TEST 1 passed: Webhook crea ordine
- [ ] TEST 2 passed: Admin panel assegna rider
- [ ] TEST 3 passed: FCM push arriva su app
- [ ] TEST 4 passed: Email merchant funzionano
- [ ] TEST 5 passed (opzionale): WhatsApp funziona

---

## 📊 MONITORING POST-DEPLOY

### Supabase Dashboard

1. **Logs** → Edge Functions
   - Verifica chiamate webhook Yamamay
   - Check errori assign-rider
   - Monitor notifiche inviate

2. **Database** → Tables
   - Count ordini creati: `SELECT COUNT(*) FROM orders WHERE created_at > NOW() - INTERVAL '24 hours'`
   - Ordini pending: `SELECT COUNT(*) FROM orders WHERE status = 'pending'`

3. **Realtime** → Inspector
   - Verifica che Admin Panel riceva updates real-time

### Resend Dashboard

- Email sent today
- Delivery rate (should be > 95%)
- Bounce rate (should be < 2%)

### Firebase Console

- FCM notifications sent
- Delivery success rate

---

## 🐛 TROUBLESHOOTING COMUNE

### Ordine non appare in Admin Panel

**Causa:** RLS policy o real-time non configurato

**Fix:**
```sql
-- Verifica ordine esiste
SELECT * FROM orders WHERE status = 'pending';

-- Disabilita RLS temporaneamente per debug
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- Check Realtime enabled
-- Supabase Dashboard → Database → Replication → orders table ✅
```

### FCM Push non arriva

**Causa:** Token non salvato o scaduto

**Fix:**
```sql
-- Verifica token
SELECT * FROM fcm_tokens WHERE rider_id = 'YOUR_RIDER_UUID';

-- Se NULL → app non ha salvato token
-- Riapri app e fai login di nuovo
```

### Email non arrivano

**Causa:** API key errata o rate limit

**Fix:**
```bash
# Re-deploy function con log
supabase functions deploy notify-merchant

# Check logs
supabase functions logs notify-merchant

# Verifica API key
echo $RESEND_API_KEY  # Deve iniziare con re_
```

### Haversine distance troppo imprecisa

**Causa:** Customer address geocoding usa zone approssimative

**Fix (FASE 2):**
- Implementa Google Maps Geocoding API
- Oppure fai inserire manualmente km in Admin Panel

---

## 🎯 NEXT STEPS FASE 2

Dopo MVP validato con Yamamay:

1. **Integrazione Yamamay E-commerce reale**
   - Ottenere credenziali webhook da loro IT
   - Test su ordini staging

2. **Google Maps API**
   - Geocoding preciso customer address
   - Routing API per ETA reale

3. **WhatsApp Business API**
   - Template approval
   - Integrazione notify-merchant

4. **Dashboard Analytics**
   - Ordini/giorno
   - Tempo medio consegna
   - Earnings rider

5. **Auto-dispatch**
   - Smart Dispatch già esistente in codebase
   - Attivare invece di manual assignment

---

## 📞 SUPPORT

**Issues?**
1. Check logs: `supabase functions logs FUNCTION_NAME`
2. Verifica secrets: `supabase secrets list`
3. Test manuale funzioni con curl

**Documentazione:**
- Supabase: https://supabase.com/docs
- Resend: https://resend.com/docs
- Flutter FCM: https://firebase.flutter.dev/docs/messaging

---

**Status:** MVP Ready for Yamamay Pilot! 🚀
**Deployment Time:** ~1 ora
**Cost:** $0 (tutto in free tier)
