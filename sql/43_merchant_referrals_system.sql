-- ============================================================
-- MERCHANT REFERRALS SYSTEM
-- ============================================================
-- Modello SaaS puro: rider segnala dealer, riceve bonus FISSO
-- una tantum dopo attivazione (NO legame con fatturato dealer).
--
-- Migration from: subscription/commission model
-- Migration to: referral bonus model
-- ============================================================

-- ============================================================
-- STEP 1: CREATE merchant_referrals TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.merchant_referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Chi segnala
  referrer_rider_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Quale dealer (FK a rider_contacts)
  dealer_contact_id UUID REFERENCES public.rider_contacts(id) ON DELETE SET NULL,
  dealer_name TEXT NOT NULL,
  dealer_phone TEXT,
  dealer_email TEXT,

  -- Stato referral
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'active', 'completed', 'expired', 'cancelled')),

  -- Condizione di attivazione
  activation_threshold_type TEXT NOT NULL DEFAULT 'first_orders'
    CHECK (activation_threshold_type IN ('first_orders', 'time_based', 'manual')),
  activation_threshold_value INTEGER NOT NULL DEFAULT 10, -- es. "primi 10 ordini"

  -- Bonus fisso (euro cents)
  bonus_amount_cents INTEGER NOT NULL DEFAULT 5000, -- €50 default

  -- Tracking progresso
  current_order_count INTEGER NOT NULL DEFAULT 0,

  -- Timestamp lifecycle
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  activated_at TIMESTAMPTZ, -- Dealer completa primo ordine
  completed_at TIMESTAMPTZ, -- Raggiunta soglia → bonus erogato
  expires_at TIMESTAMPTZ,   -- Scadenza (90gg da created_at)
  cancelled_at TIMESTAMPTZ,

  -- Audit
  bonus_paid_at TIMESTAMPTZ,
  bonus_transaction_id UUID REFERENCES public.transactions(id),

  -- Note interne
  notes TEXT
);

COMMENT ON TABLE public.merchant_referrals IS
  'Sistema referral dealer: rider segnala merchant, riceve bonus fisso una tantum';

COMMENT ON COLUMN public.merchant_referrals.status IS
  'pending=segnalato, active=dealer ha fatto primo ordine, completed=soglia raggiunta+bonus erogato';

COMMENT ON COLUMN public.merchant_referrals.activation_threshold_value IS
  'Numero ordini necessari per completare referral (default 10)';

-- ============================================================
-- STEP 2: INDEXES
-- ============================================================

CREATE INDEX idx_merchant_referrals_referrer
  ON public.merchant_referrals (referrer_rider_id);

CREATE INDEX idx_merchant_referrals_dealer
  ON public.merchant_referrals (dealer_contact_id)
  WHERE dealer_contact_id IS NOT NULL;

CREATE INDEX idx_merchant_referrals_status
  ON public.merchant_referrals (status, referrer_rider_id);

CREATE INDEX idx_merchant_referrals_active
  ON public.merchant_referrals (status, dealer_contact_id)
  WHERE status IN ('pending', 'active');

-- ============================================================
-- STEP 3: ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.merchant_referrals ENABLE ROW LEVEL SECURITY;

-- Riders can view their own merchant referrals
CREATE POLICY "Riders view own merchant referrals"
  ON public.merchant_referrals FOR SELECT
  USING (referrer_rider_id = auth.uid());

-- Riders can insert their own merchant referrals
CREATE POLICY "Riders insert own merchant referrals"
  ON public.merchant_referrals FOR INSERT
  WITH CHECK (referrer_rider_id = auth.uid());

-- Riders can update their own pending/active referrals (cancel only)
CREATE POLICY "Riders update own merchant referrals"
  ON public.merchant_referrals FOR UPDATE
  USING (referrer_rider_id = auth.uid() AND status IN ('pending', 'active'))
  WITH CHECK (status = 'cancelled'); -- Can only set to cancelled

-- Service role has full access
CREATE POLICY "Service role manages merchant referrals"
  ON public.merchant_referrals FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================
-- STEP 4: REAL-TIME SUBSCRIPTION
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.merchant_referrals;

-- ============================================================
-- STEP 5: AUTO-SET EXPIRES_AT TRIGGER
-- ============================================================

CREATE OR REPLACE FUNCTION set_merchant_referral_expiry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expires_at IS NULL THEN
    NEW.expires_at := NEW.created_at + INTERVAL '90 days';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_merchant_referral_expiry
  BEFORE INSERT ON public.merchant_referrals
  FOR EACH ROW
  EXECUTE FUNCTION set_merchant_referral_expiry();

-- ============================================================
-- STEP 6: AUTO-ACTIVATE REFERRAL ON FIRST ORDER
-- ============================================================

CREATE OR REPLACE FUNCTION activate_merchant_referral_on_first_order()
RETURNS TRIGGER AS $$
DECLARE
  _referral merchant_referrals;
BEGIN
  -- Trova referral pending per questo dealer
  SELECT * INTO _referral
  FROM public.merchant_referrals
  WHERE dealer_contact_id = NEW.dealer_contact_id
    AND status = 'pending'
  LIMIT 1;

  IF _referral IS NOT NULL THEN
    -- Attiva referral
    UPDATE public.merchant_referrals
    SET status = 'active',
        activated_at = now()
    WHERE id = _referral.id;

    RAISE NOTICE 'Merchant referral % activated for dealer %',
      _referral.id, NEW.dealer_contact_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_activate_merchant_referral
  AFTER INSERT ON public.order_relays
  FOR EACH ROW
  WHEN (NEW.status = 'picked_up')
  EXECUTE FUNCTION activate_merchant_referral_on_first_order();

-- ============================================================
-- STEP 7: AUTO-COMPLETE REFERRAL ON THRESHOLD REACHED
-- ============================================================

CREATE OR REPLACE FUNCTION check_merchant_referral_completion()
RETURNS TRIGGER AS $$
DECLARE
  _referral merchant_referrals;
  _new_count INTEGER;
  _bonus_transaction_id UUID;
BEGIN
  -- Trova referral attivo per questo dealer
  SELECT * INTO _referral
  FROM public.merchant_referrals
  WHERE dealer_contact_id = NEW.dealer_contact_id
    AND status = 'active'
  LIMIT 1;

  IF _referral IS NOT NULL THEN
    -- Incrementa contatore ordini
    UPDATE public.merchant_referrals
    SET current_order_count = current_order_count + 1
    WHERE id = _referral.id
    RETURNING current_order_count INTO _new_count;

    RAISE NOTICE 'Merchant referral % progress: %/%',
      _referral.id, _new_count, _referral.activation_threshold_value;

    -- Controlla soglia
    IF _new_count >= _referral.activation_threshold_value THEN
      -- Completa referral
      UPDATE public.merchant_referrals
      SET status = 'completed',
          completed_at = now()
      WHERE id = _referral.id;

      -- Crea transazione bonus (se transactions table esiste)
      BEGIN
        INSERT INTO public.transactions (
          rider_id,
          type,
          amount,
          status,
          description,
          processed_at
        )
        VALUES (
          _referral.referrer_rider_id,
          'bonus',
          _referral.bonus_amount_cents / 100.0,
          'completed',
          'Bonus referral merchant: ' || _referral.dealer_name,
          now()
        )
        RETURNING id INTO _bonus_transaction_id;

        -- Collega transazione a referral
        UPDATE public.merchant_referrals
        SET bonus_transaction_id = _bonus_transaction_id,
            bonus_paid_at = now()
        WHERE id = _referral.id;

        RAISE NOTICE 'Merchant referral % completed! Bonus transaction %',
          _referral.id, _bonus_transaction_id;
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'Failed to create bonus transaction for referral %: %',
          _referral.id, SQLERRM;
      END;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_merchant_referral
  AFTER UPDATE OF status ON public.order_relays
  FOR EACH ROW
  WHEN (NEW.status = 'picked_up' AND OLD.status <> 'picked_up')
  EXECUTE FUNCTION check_merchant_referral_completion();

-- ============================================================
-- STEP 8: EXPIRE OLD REFERRALS (Manual - run via pg_cron)
-- ============================================================

-- Function to expire old referrals (chiamare da cron job)
CREATE OR REPLACE FUNCTION expire_old_merchant_referrals()
RETURNS INTEGER AS $$
DECLARE
  _expired_count INTEGER;
BEGIN
  UPDATE public.merchant_referrals
  SET status = 'expired'
  WHERE status IN ('pending', 'active')
    AND expires_at < now();

  GET DIAGNOSTICS _expired_count = ROW_COUNT;

  RAISE NOTICE 'Expired % merchant referrals', _expired_count;
  RETURN _expired_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION expire_old_merchant_referrals IS
  'Expire merchant referrals older than expires_at. Run daily via cron.';

-- ============================================================
-- STEP 9: MIGRATE EXISTING DATA
-- ============================================================

-- Migra dealer esistenti da rider_contacts a merchant_referrals
INSERT INTO public.merchant_referrals (
  referrer_rider_id,
  dealer_contact_id,
  dealer_name,
  dealer_phone,
  dealer_email,
  status,
  current_order_count,
  bonus_amount_cents,
  created_at,
  activated_at,
  completed_at
)
SELECT
  rc.rider_id,
  rc.id,
  rc.name,
  rc.phone,
  rc.email,
  CASE
    -- Se dealer ha completato >= 10 ordini, referral completed
    WHEN rc.total_orders >= 10 THEN 'completed'
    -- Se dealer ha ordini ma < 10, referral active
    WHEN rc.total_orders > 0 THEN 'active'
    -- Altrimenti, referral pending
    ELSE 'pending'
  END,
  LEAST(rc.total_orders, 10), -- Cap a 10 per threshold
  5000, -- €50 default bonus
  rc.created_at,
  CASE
    WHEN rc.total_orders > 0 THEN rc.created_at + INTERVAL '1 day'
    ELSE NULL
  END,
  CASE
    WHEN rc.total_orders >= 10 THEN rc.created_at + INTERVAL '30 days'
    ELSE NULL
  END
FROM public.rider_contacts rc
WHERE rc.contact_type = 'dealer'
  AND NOT EXISTS (
    SELECT 1 FROM public.merchant_referrals mr
    WHERE mr.dealer_contact_id = rc.id
  );

-- Log migration result
DO $$
DECLARE
  _migrated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO _migrated_count
  FROM public.merchant_referrals;

  RAISE NOTICE 'Migrated % dealer contacts to merchant_referrals', _migrated_count;
END $$;

-- ============================================================
-- STEP 10: UPDATE rider_contacts TABLE
-- ============================================================

-- Aggiungi referral_id FK
ALTER TABLE public.rider_contacts
  ADD COLUMN IF NOT EXISTS referral_id UUID
    REFERENCES public.merchant_referrals(id) ON DELETE SET NULL;

-- Popola referral_id
UPDATE public.rider_contacts rc
SET referral_id = mr.id
FROM public.merchant_referrals mr
WHERE mr.dealer_contact_id = rc.id
  AND rc.contact_type = 'dealer';

-- Index per lookup
CREATE INDEX IF NOT EXISTS idx_rider_contacts_referral
  ON public.rider_contacts (referral_id)
  WHERE referral_id IS NOT NULL;

-- Depreca monthly_earnings se esiste (NON eliminare subito per backward compat)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'rider_contacts' AND column_name = 'monthly_earnings'
  ) THEN
    ALTER TABLE public.rider_contacts
      ADD COLUMN IF NOT EXISTS monthly_earnings_deprecated BOOLEAN DEFAULT false;
    UPDATE public.rider_contacts
    SET monthly_earnings_deprecated = true
    WHERE monthly_earnings IS NOT NULL;
    EXECUTE 'COMMENT ON COLUMN public.rider_contacts.monthly_earnings IS ''DEPRECATED: Use merchant_referrals.bonus_amount_cents instead''';
  END IF;
END $$;

-- ============================================================
-- STEP 11: DEPRECATE dealer_subscriptions
-- ============================================================

-- Flag deprecato se la tabella esiste (NON eliminare per backward compat backend)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'dealer_subscriptions'
  ) THEN
    ALTER TABLE public.dealer_subscriptions
      ADD COLUMN IF NOT EXISTS deprecated BOOLEAN DEFAULT true;
    UPDATE public.dealer_subscriptions SET deprecated = true;
    EXECUTE 'COMMENT ON TABLE public.dealer_subscriptions IS ''DEPRECATED: Replaced by merchant_referrals system. Keep for backend compatibility.''';
  END IF;
END $$;

-- ============================================================
-- STEP 12: HELPER VIEWS
-- ============================================================

-- View: Active merchant referrals per rider
CREATE OR REPLACE VIEW public.active_merchant_referrals AS
SELECT
  mr.referrer_rider_id,
  COUNT(*) FILTER (WHERE mr.status = 'pending') AS pending_count,
  COUNT(*) FILTER (WHERE mr.status = 'active') AS active_count,
  COUNT(*) FILTER (WHERE mr.status = 'completed') AS completed_count,
  COALESCE(SUM(mr.bonus_amount_cents) FILTER (WHERE mr.status = 'completed'), 0) AS total_bonus_earned_cents
FROM public.merchant_referrals mr
GROUP BY mr.referrer_rider_id;

COMMENT ON VIEW public.active_merchant_referrals IS
  'Summary stats per rider: pending/active/completed referrals and total bonus earned';

-- ============================================================
-- STEP 13: GRANT PERMISSIONS
-- ============================================================

GRANT SELECT, INSERT, UPDATE ON public.merchant_referrals TO authenticated;
GRANT SELECT ON public.active_merchant_referrals TO authenticated;

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================

DO $$
DECLARE
  _count INTEGER;
BEGIN
  SELECT COUNT(*) INTO _count FROM public.merchant_referrals;
  RAISE NOTICE '✅ Merchant referrals system migration complete!';
  RAISE NOTICE '   - Created merchant_referrals table';
  RAISE NOTICE '   - Migrated % dealer contacts', _count;
  RAISE NOTICE '   - Set up triggers for auto-activation and completion';
  RAISE NOTICE '   - Deprecated dealer_subscriptions (kept for backend compat)';
  RAISE NOTICE '   - Next: Update Flutter app to use new merchant_referrals API';
END $$;
