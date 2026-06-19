-- ============================================================================
-- 42. UNIFICA website_signups IN riders
-- ============================================================================
-- Il sito web scriverà direttamente in riders.
-- Il trigger gestisce il caso in cui l'email esiste già (pre-registrazione web).
-- ============================================================================

-- Step 1: Aggiungi colonna source a riders per tracciare provenienza
ALTER TABLE public.riders ADD COLUMN IF NOT EXISTS source TEXT;

-- Step 2: Migra dati esistenti da website_signups a riders
INSERT INTO public.riders (name, email, phone, zone_id, source, status, active, vehicle_type, total_deliveries, reputation_score, created_at, updated_at)
SELECT
    ws.name,
    ws.email,
    ws.phone,
    ws.city_zone,
    COALESCE(ws.source, 'landing_page'),
    'pending',
    false,
    'scooter',
    0,
    50,
    ws.created_at,
    NOW()
FROM public.website_signups ws
WHERE NOT EXISTS (
    SELECT 1 FROM public.riders r WHERE r.email = ws.email
);

-- Step 3: Aggiorna trigger - se email già esiste in riders (da sito web), collega l'auth ID
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_existing_id UUID;
BEGIN
    -- Cerca se esiste già un rider con questa email (pre-registrato dal sito web)
    SELECT id INTO v_existing_id
    FROM public.riders
    WHERE email = NEW.email
    LIMIT 1;

    IF v_existing_id IS NOT NULL THEN
        -- Rider pre-registrato dal sito: aggiorna con auth ID e attiva
        UPDATE public.riders SET
            id = NEW.id,
            name = CASE WHEN name = '' OR name IS NULL
                        THEN COALESCE(NEW.raw_user_meta_data->>'full_name', name)
                        ELSE name END,
            active = true,
            status = 'offline',
            source = COALESCE(source, '') || ',app',
            updated_at = NOW()
        WHERE id = v_existing_id;
    ELSE
        -- Nuovo rider: inserisci
        INSERT INTO public.riders (
            id, email, name, phone, vehicle_type, status, active,
            source, total_deliveries, reputation_score, created_at, updated_at
        ) VALUES (
            NEW.id, NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
            COALESCE(NEW.raw_user_meta_data->>'phone', ''),
            'scooter', 'offline', true,
            'app', 0, 50, NOW(), NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email, updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$;

-- Step 4: Ricrea trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Verifica
SELECT id, name, email, phone, source, status, active, created_at
FROM public.riders
ORDER BY created_at DESC
LIMIT 10;
