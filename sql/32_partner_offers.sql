-- ============================================================
-- SQL 32: Partner Offers + Clicks (DLOOP Pro Vantaggi)
-- Date: 2026-02-13
-- Milestone: M2.7 Partner Benefits
-- ============================================================

-- 1. Partner offers (master catalog)
CREATE TABLE IF NOT EXISTS partner_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    description TEXT NOT NULL,
    short_description TEXT NOT NULL,
    referral_base_url TEXT NOT NULL,
    commission_type TEXT CHECK (commission_type IN ('percentage', 'flat_per_lead', 'recurring')),
    commission_value DECIMAL(10,2),
    target_audience TEXT[] DEFAULT '{}',
    category TEXT NOT NULL,
    phase INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Partner clicks (tracking)
CREATE TABLE IF NOT EXISTS partner_clicks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    offer_id UUID REFERENCES partner_offers(id) NOT NULL,
    clicked_at TIMESTAMPTZ DEFAULT now()
);

-- 3. RLS
ALTER TABLE partner_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_clicks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone authenticated can view active offers"
    ON partner_offers FOR SELECT TO authenticated
    USING (is_active = true);

CREATE POLICY "Users can insert own clicks"
    ON partner_clicks FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view own clicks"
    ON partner_clicks FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- 4. Indexes
CREATE INDEX idx_partner_offers_active ON partner_offers (is_active, sort_order);
CREATE INDEX idx_partner_clicks_user ON partner_clicks (user_id, clicked_at DESC);
CREATE INDEX idx_partner_clicks_offer ON partner_clicks (offer_id);

-- 5. Seed data (FASE 1 partners)
INSERT INTO partner_offers (name, slug, description, short_description, referral_base_url, commission_type, commission_value, target_audience, category, phase, sort_order) VALUES
(
    'Qover',
    'qover-insurance',
    'Assicurazione completa per rider: infortuni, RC, malattia. Usata da Deliveroo, Glovo e Wolt. Nessun deposito cauzionale richiesto.',
    'Assicurazione rider professionale',
    'https://www.qover.com',
    'recurring',
    4.00,
    ARRAY['rider'],
    'insurance',
    1,
    0
),
(
    'Fiscozen',
    'fiscozen-tax',
    'Gestione completa della tua Partita IVA: dichiarazioni, fatture, consulenza fiscale dedicata ai lavoratori gig economy. Sconto esclusivo DLOOP Pro.',
    'Gestione P.IVA semplificata',
    'https://www.fiscozen.it',
    'flat_per_lead',
    50.00,
    ARRAY['rider', 'dealer'],
    'finance',
    1,
    1
),
(
    'Finom',
    'finom-business',
    'Conto business gratuito con IBAN italiano, carte virtuali illimitate, fatturazione integrata. Perfetto per ricevere i pagamenti DLOOP.',
    'Conto business per freelancer',
    'https://www.finom.co',
    'flat_per_lead',
    20.00,
    ARRAY['rider', 'dealer'],
    'finance',
    1,
    2
),
(
    'ho. Mobile',
    'ho-mobile-data',
    'Piano dati illimitato a prezzo speciale per rider DLOOP. Rete Vodafone, nessun vincolo, attivazione immediata.',
    'Piano dati per rider',
    'https://www.ho-mobile.it',
    'flat_per_lead',
    10.00,
    ARRAY['rider'],
    'telecom',
    2,
    3
),
(
    'SumUp',
    'sumup-pos',
    'Lettore POS portatile senza canone mensile. Accetta pagamenti con carta direttamente nel tuo negozio. Commissione solo 1.95% per transazione.',
    'POS senza canone per il tuo negozio',
    'https://www.sumup.it',
    'flat_per_lead',
    15.00,
    ARRAY['dealer'],
    'tools',
    2,
    4
);
