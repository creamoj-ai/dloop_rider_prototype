-- ============================================
-- 25. Create rider contacts table (dealers & clients)
-- ============================================

CREATE TABLE IF NOT EXISTS public.rider_contacts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name             TEXT NOT NULL,
    contact_type     TEXT NOT NULL CHECK (contact_type IN ('dealer', 'client')),
    status           TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'potential', 'vip')),
    phone            TEXT,
    total_orders     INT NOT NULL DEFAULT 0,
    monthly_earnings NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_rider_contacts_rider ON public.rider_contacts(rider_id);
CREATE INDEX idx_rider_contacts_rider_type ON public.rider_contacts(rider_id, contact_type);

-- RLS
ALTER TABLE public.rider_contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own contacts"
    ON public.rider_contacts FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own contacts"
    ON public.rider_contacts FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own contacts"
    ON public.rider_contacts FOR UPDATE
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can delete own contacts"
    ON public.rider_contacts FOR DELETE
    USING (rider_id = auth.uid());

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.rider_contacts;

-- Seed data
DO $$
DECLARE
    _rider_id UUID;
BEGIN
    SELECT id INTO _rider_id FROM auth.users WHERE email = 'creamoj@gmail.com' LIMIT 1;
    IF _rider_id IS NOT NULL THEN
        INSERT INTO public.rider_contacts (rider_id, name, contact_type, status, phone, total_orders, monthly_earnings) VALUES
            (_rider_id, 'Marco Bianchi',  'dealer', 'active',    '+39 333 1111111', 142, 120.00),
            (_rider_id, 'Luca Russo',     'dealer', 'active',    '+39 333 2222222',  98,  95.00),
            (_rider_id, 'Sara Moretti',   'dealer', 'active',    '+39 333 3333333',  76,  80.00),
            (_rider_id, 'Andrea Palmieri','dealer', 'potential',  '+39 333 4444444',  12,  45.00),
            (_rider_id, 'Anna Verdi',     'client', 'vip',       '+39 333 5555555',  24,   0.00),
            (_rider_id, 'Paolo Greco',    'client', 'vip',       '+39 333 6666666',  18,   0.00),
            (_rider_id, 'Maria Lombardi', 'client', 'active',    '+39 333 7777777',  12,   0.00),
            (_rider_id, 'Franco Di Nardo','client', 'active',    '+39 333 8888888',   8,   0.00),
            (_rider_id, 'Elena Santoro',  'client', 'active',    NULL,                5,   0.00);
    END IF;
END $$;
