-- ============================================================================
-- DLOOP - Test Completo Admin Panel
-- ============================================================================
-- Esegui questo file nel Supabase SQL Editor per testare tutto
-- ============================================================================

-- Step 1: Crea un rider di test
DO $$
DECLARE
    v_rider_id UUID;
BEGIN
    -- Genera nuovo rider ID
    v_rider_id := gen_random_uuid();

    -- Inserisci FCM token per il rider
    INSERT INTO fcm_tokens (rider_id, token, is_active)
    VALUES (
        v_rider_id,
        'fake-fcm-token-test-' || extract(epoch from now())::text,
        true
    );

    RAISE NOTICE '✅ Rider creato: %', v_rider_id;

    -- Mostra il rider creato
    RAISE NOTICE 'Rider ID da usare nell''Admin Panel:';
    RAISE NOTICE '%', v_rider_id;
END $$;

-- Step 2: Verifica dealer Yamamay esiste
DO $$
DECLARE
    v_dealer_id UUID;
    v_dealer_name TEXT;
BEGIN
    SELECT id, business_name INTO v_dealer_id, v_dealer_name
    FROM dealers
    WHERE business_name LIKE '%Yamamay%'
    AND status = 'active'
    LIMIT 1;

    IF v_dealer_id IS NULL THEN
        RAISE EXCEPTION '❌ Dealer Yamamay non trovato! Esegui prima sql/40_create_dealers_table.sql';
    ELSE
        RAISE NOTICE '✅ Dealer trovato: % (ID: %)', v_dealer_name, v_dealer_id;
    END IF;
END $$;

-- Step 3: Mostra rider disponibili
SELECT
    rider_id,
    token,
    is_active,
    created_at
FROM fcm_tokens
WHERE is_active = true
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- ISTRUZIONI:
-- ============================================================================
-- 1. Esegui questo SQL nel Supabase SQL Editor
-- 2. Copia il rider_id mostrato nei messaggi
-- 3. Usa curl per creare un ordine (vedi sotto)
-- 4. Apri Admin Panel: https://steady-baklava-2ec7fa.netlify.app
-- 5. Assegna l'ordine al rider creato
-- ============================================================================
