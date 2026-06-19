-- ============================================================================
-- VERIFICA SETUP AUTENTICAZIONE
-- ============================================================================
-- Esegui questo SQL in Supabase SQL Editor per verificare il setup auth
-- ============================================================================

-- 1. Verifica che il trigger esista
SELECT
    tgname as trigger_name,
    tgenabled as is_enabled,
    proname as function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgname = 'on_auth_user_created';

-- 2. Verifica che la funzione handle_new_user esista
SELECT
    proname as function_name,
    pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname = 'handle_new_user';

-- 3. Verifica struttura tabella users
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'users'
ORDER BY ordinal_position;

-- 4. Verifica struttura tabella riders
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'riders'
ORDER BY ordinal_position;

-- 5. Conta utenti in auth.users vs public.users vs public.riders
SELECT
    (SELECT COUNT(*) FROM auth.users) as auth_users,
    (SELECT COUNT(*) FROM public.users) as public_users,
    (SELECT COUNT(*) FROM public.riders) as public_riders;

-- 6. Verifica utenti in auth.users senza corrispondenza in public.users
SELECT
    au.id,
    au.email,
    au.created_at,
    au.raw_user_meta_data->>'full_name' as full_name
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
)
ORDER BY au.created_at DESC
LIMIT 10;

-- ============================================================================
-- RISULTATI ATTESI:
-- ============================================================================
-- 1. Trigger: dovrebbe esistere e essere enabled
-- 2. Funzione: dovrebbe esistere con il codice completo
-- 3. Tabella users: dovrebbe avere colonne id, email, first_name, last_name, etc.
-- 4. Tabella riders: dovrebbe avere struttura completa rider
-- 5. Count: auth_users dovrebbe essere >= public_users
-- 6. Missing users: se ci sono utenti qui, il trigger non ha funzionato!
-- ============================================================================
