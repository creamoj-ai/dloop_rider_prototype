-- ============================================
-- 40. Create dealers/merchants table
-- ============================================
-- Tabella merchant per:
-- - Calcolo distanza (location POINT con lat/lng)
-- - Notifiche email + WhatsApp
-- - Integrazione webhook Yamamay
-- ============================================

CREATE TABLE IF NOT EXISTS public.dealers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Business info
    business_name TEXT NOT NULL,
    owner_name TEXT,
    category TEXT,  -- 'abbigliamento', 'ristorazione', 'farmacia', etc.

    -- Contact info
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    whatsapp_number TEXT,  -- Numero WhatsApp per notifiche (può essere diverso da phone)
    telegram_chat_id BIGINT,  -- Per bot Telegram (opzionale)

    -- Address
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    postal_code TEXT,
    location POINT NOT NULL,  -- PostGIS POINT(longitude, latitude) per calcolo distanza

    -- Status
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_dealers_business_name ON public.dealers(business_name);
CREATE INDEX IF NOT EXISTS idx_dealers_status ON public.dealers(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_dealers_location ON public.dealers USING GIST(location);  -- Spatial index

-- RLS (tutti possono leggere dealer attivi, solo admin possono modificare)
ALTER TABLE public.dealers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view active dealers"
    ON public.dealers FOR SELECT
    USING (status = 'active');

-- Service role può fare tutto (per Cloud Functions)
CREATE POLICY "Service role full access"
    ON public.dealers FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- SEED DATA - Merchant di test per MVP
-- ============================================

INSERT INTO public.dealers (
    business_name,
    owner_name,
    email,
    phone,
    whatsapp_number,
    category,
    address,
    city,
    postal_code,
    location,
    status
) VALUES
    -- Yamamay Napoli (cliente pilota MVP)
    (
        'Yamamay Napoli Centro',
        'Manager Yamamay',
        'napoli@yamamay.com',
        '+39 081 1234567',
        '+39 081 1234567',
        'abbigliamento',
        'Via Toledo 256',
        'Napoli',
        '80134',
        POINT(14.2489, 40.8359),  -- Coordinate Via Toledo 256, Napoli
        'active'
    ),

    -- Piccolo merchant test 1
    (
        'Pizzeria Sorbillo',
        'Gino Sorbillo',
        'info@sorbillo.it',
        '+39 081 446643',
        '+39 081 446643',
        'ristorazione',
        'Via dei Tribunali 32',
        'Napoli',
        '80138',
        POINT(14.2568, 40.8506),  -- Coordinate Via dei Tribunali
        'active'
    ),

    -- Piccolo merchant test 2
    (
        'Farmacia Salute',
        'Dr. Mario Rossi',
        'info@farmaciasalute.it',
        '+39 081 5547890',
        '+39 081 5547890',
        'farmacia',
        'Corso Umberto I 123',
        'Napoli',
        '80138',
        POINT(14.2611, 40.8489),  -- Coordinate Corso Umberto
        'active'
    )
ON CONFLICT DO NOTHING;  -- Evita duplicati se script eseguito più volte

-- ============================================
-- VERIFY
-- ============================================
SELECT
    id,
    business_name,
    email,
    whatsapp_number,
    ST_AsText(location) as coordinates,
    status
FROM public.dealers
WHERE status = 'active'
ORDER BY business_name;

-- ============================================
-- NEXT STEPS:
-- 1. Esegui questo SQL in Supabase SQL Editor
-- 2. Verifica che i 3 dealer siano stati creati
-- 3. Per aggiungere nuovi dealer: usa INSERT con coordinate da Google Maps
--    Formato POINT: POINT(longitude, latitude) ← attenzione ordine!
-- ============================================
