# 🔧 Fix Autenticazione Flutter App - Diagnosi e Soluzione

## 🔍 Problema
- Sign-up dall'app mostra "Registrazione completata, controlla email"
- Ma NON scrive in database
- NON arriva email di conferma

## 📋 Diagnosi Step-by-Step

### Step 1: Verifica Trigger e Tabelle

Vai su **Supabase SQL Editor**:
https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/sql/new

Esegui il file: `verify-auth-setup.sql`

**Cosa verificare:**

1. **Trigger exists?** → Deve mostrare `on_auth_user_created` con `is_enabled = O` (enabled)
2. **Funzione exists?** → Deve mostrare `handle_new_user` con definizione completa
3. **Missing users?** → Se query #6 mostra utenti, il trigger NON ha funzionato!

---

### Step 2: Verifica Email Configuration

Vai su **Supabase Dashboard → Authentication → Email Templates**:
https://supabase.com/dashboard/project/aqpwfurradxbnqvycvkm/auth/templates

**Controlla:**

1. **Email Confirmation** è abilitata? ✅
2. **SMTP configurato?**
   - Vai su: Settings → Auth → SMTP Settings
   - Se NON configurato, Supabase usa il suo server (limite 4 email/ora in dev)

3. **Confirm Email** è richiesta?
   - Settings → Auth → Email Auth
   - Verifica se "Enable email confirmations" è ON

---

### Step 3: Verifica Policy RLS

Se il trigger funziona ma non vedi dati:

```sql
-- Verifica policy su tabella users
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'users';

-- Verifica policy su tabella riders
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'riders';
```

**Problema comune:** RLS blocca INSERT se non c'è policy per INSERT

---

## 🚀 Soluzioni Possibili

### Soluzione A: Trigger Mancante (più probabile)

Se il trigger non esiste, **eseguilo ora**:

```sql
-- Copia e incolla TUTTO il contenuto di:
-- sql/12_users_trigger_and_rls.sql

-- Nel Supabase SQL Editor ed esegui
```

Poi prova di nuovo il signup dall'app.

---

### Soluzione B: Email Confirmation Disabilitata

Se vuoi **disabilitare email confirmation** per testing:

1. Dashboard → Authentication → Settings
2. **Disable email confirmation** → Save
3. Gli utenti possono loggarsi subito senza email

**PRO:** Testing veloce
**CONTRO:** Meno sicuro (solo per development!)

---

### Soluzione C: Relazione users ↔ riders

Probabilmente hai:
- `auth.users` → utenti auth Supabase
- `public.users` → profilo base (creato da trigger)
- `public.riders` → profilo rider completo

**Devi decidere:**

**Opzione 1:** `users` e `riders` sono la STESSA tabella
- Rinomina `users` → `riders`
- Aggiorna trigger per scrivere direttamente in `riders`

**Opzione 2:** `users` è base, `riders` è estensione
- Trigger crea `users`
- L'app poi crea/aggiorna `riders` con dati extra (veicolo, zona, etc.)

---

## 🧪 Test Manuale Signup

Per testare se il problema è l'app o Supabase:

```sql
-- Simula signup manuale
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'test@example.com',
    crypt('Password123', gen_salt('bf')),
    NOW(), -- Email già confermata per test
    '{"provider": "email", "providers": ["email"]}',
    '{"full_name": "Test Rider"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
)
RETURNING id, email;

-- Verifica che il trigger abbia creato il record in public.users
SELECT * FROM public.users WHERE email = 'test@example.com';
```

**Se funziona:** Problema nella Flutter app
**Se non funziona:** Problema trigger/config Supabase

---

## 📊 Quick Check Dashboard

**Verifica utenti creati:**

Dashboard → Authentication → Users

Se vedi utenti **in grigio/pending** → Email non confermata

---

## 🎯 Soluzione Rapida per Sviluppo

Per sbloccarti ORA:

1. **Disabilita email confirmation**:
   - Settings → Auth → Email → **Disable "Enable email confirmations"**

2. **Esegui trigger se mancante**:
   ```sql
   -- Esegui sql/12_users_trigger_and_rls.sql
   ```

3. **Testa signup app**:
   - Dovrebbe funzionare senza email
   - Check: `SELECT * FROM auth.users ORDER BY created_at DESC LIMIT 5;`

4. **Riabilita email confirmation** dopo aver configurato SMTP in produzione

---

## 📞 Diagnostica Completa

Esegui questi comandi in ordine e mandami i risultati:

```sql
-- 1. Trigger installato?
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- 2. Utenti auth
SELECT id, email, created_at, email_confirmed_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;

-- 3. Utenti public
SELECT id, email, first_name, last_name, created_at
FROM public.users
ORDER BY created_at DESC
LIMIT 5;

-- 4. Riders
SELECT id, name, email, active, created_at
FROM public.riders
ORDER BY created_at DESC
LIMIT 5;
```

Mandami l'output e ti dico esattamente cosa manca! 🚀
