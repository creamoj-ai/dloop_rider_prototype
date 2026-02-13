-- ============================================
-- 32. Create order_relays table (Order Relay lifecycle)
-- ============================================
-- Tracks the relay of an order from rider to dealer.
-- Each order can have one active relay at a time.
-- Status flow: pending → sent → confirmed → preparing → ready → picked_up
-- Payment flow: pending → sent → paid

CREATE TABLE IF NOT EXISTS public.order_relays (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    rider_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dealer_contact_id   UUID NOT NULL REFERENCES public.rider_contacts(id),
    status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','sent','confirmed','preparing','ready','picked_up','cancelled')),
    relay_channel       TEXT NOT NULL DEFAULT 'in_app'
                        CHECK (relay_channel IN ('in_app','whatsapp','phone')),
    dealer_message      TEXT,
    dealer_reply        TEXT,
    estimated_amount    NUMERIC(10,2),
    actual_amount       NUMERIC(10,2),
    stripe_payment_link TEXT,
    stripe_session_id   TEXT,
    payment_status      TEXT NOT NULL DEFAULT 'pending'
                        CHECK (payment_status IN ('pending','sent','paid','failed')),
    relayed_at          TIMESTAMPTZ,
    confirmed_at        TIMESTAMPTZ,
    ready_at            TIMESTAMPTZ,
    picked_up_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_order_relays_order ON public.order_relays(order_id);
CREATE INDEX IF NOT EXISTS idx_order_relays_rider ON public.order_relays(rider_id);
CREATE INDEX IF NOT EXISTS idx_order_relays_rider_status ON public.order_relays(rider_id, status);

-- Row Level Security
ALTER TABLE public.order_relays ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Riders can view own relays"
    ON public.order_relays FOR SELECT
    USING (rider_id = auth.uid());

CREATE POLICY "Riders can insert own relays"
    ON public.order_relays FOR INSERT
    WITH CHECK (rider_id = auth.uid());

CREATE POLICY "Riders can update own relays"
    ON public.order_relays FOR UPDATE
    USING (rider_id = auth.uid());

-- Enable real-time subscriptions
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_relays;

-- Auto-update updated_at on row change
CREATE OR REPLACE FUNCTION update_order_relays_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_relays_updated_at
    BEFORE UPDATE ON public.order_relays
    FOR EACH ROW EXECUTE FUNCTION update_order_relays_updated_at();
