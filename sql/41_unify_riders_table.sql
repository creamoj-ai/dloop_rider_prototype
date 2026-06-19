-- ============================================================================
-- 41. UNIFICA TABELLA RIDERS (elimina duplicazione con users)
-- ============================================================================
-- Aggiunge colonne mancanti a riders per sostituire tabella users
-- ============================================================================

-- Step 1: Aggiungi colonne mancanti a riders
ALTER TABLE public.riders ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.riders ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.riders ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE public.riders ADD COLUMN IF NOT EXISTS referral_code TEXT;
ALTER TABLE public.riders ADD COLUMN IF NOT EXISTS referred_by UUID;

-- Step 2: Indice su email (unique per evitare duplicati)
CREATE UNIQUE INDEX IF NOT EXISTS idx_riders_email ON public.riders(email) WHERE email IS NOT NULL;

-- Step 3: Aggiorna trigger per scrivere in riders invece di users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.riders (
        id,
        email,
        name,
        phone,
        vehicle_type,
        status,
        active,
        total_deliveries,
        reputation_score,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        'scooter',
        'offline',
        true,
        0,
        50,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();

    RETURN NEW;
END;
$$;

-- Step 4: Ricrea trigger su auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 5: RLS policies per riders (aggiorna per supportare auth)
DROP POLICY IF EXISTS "Riders can view own profile" ON public.riders;
DROP POLICY IF EXISTS "Riders can update own profile" ON public.riders;
DROP POLICY IF EXISTS "Anyone can view active riders" ON public.riders;
DROP POLICY IF EXISTS "Service role full access riders" ON public.riders;

-- Tutti possono vedere rider attivi (serve per admin panel)
CREATE POLICY "Anyone can view active riders"
    ON public.riders FOR SELECT
    USING (true);

-- Rider può aggiornare il proprio profilo
CREATE POLICY "Riders can update own profile"
    ON public.riders FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Service role può fare tutto (per trigger e cloud functions)
CREATE POLICY "Service role full access riders"
    ON public.riders FOR ALL
    USING (auth.role() = 'service_role');

-- INSERT policy per il trigger (security definer)
CREATE POLICY "Allow insert for authenticated"
    ON public.riders FOR INSERT
    WITH CHECK (true);

-- Step 6: Backfill - copia utenti da auth.users che mancano in riders
INSERT INTO public.riders (id, email, name, phone, vehicle_type, status, active, total_deliveries, reputation_score, created_at, updated_at)
SELECT
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', ''),
    COALESCE(au.raw_user_meta_data->>'phone', ''),
    'scooter',
    'offline',
    true,
    0,
    50,
    NOW(),
    NOW()
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.riders r WHERE r.id = au.id
);

-- Step 7: Verifica
SELECT id, name, email, phone, status, active, created_at
FROM public.riders
ORDER BY created_at DESC
LIMIT 10;
