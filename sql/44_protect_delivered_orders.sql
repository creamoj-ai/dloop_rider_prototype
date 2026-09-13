-- ============================================================
-- SQL 44: Protect delivered orders from being cancelled
-- ============================================================
-- Incident: order 653fb6ed had delivered_at populated but
-- status = 'cancelled'. A cancellation write landed after the
-- delivery write and overwrote only `status`, leaving
-- delivered_at intact (the cancel path never clears it).
--
-- Guard at the DB level so every writer is covered: the rider
-- app, older app builds still in the wild, Edge Functions, and
-- anything scheduled directly on the database.
-- ============================================================

CREATE OR REPLACE FUNCTION public.protect_delivered_orders()
RETURNS trigger AS $$
BEGIN
    IF NEW.status = 'cancelled'
       AND (OLD.delivered_at IS NOT NULL OR OLD.status = 'delivered')
    THEN
        RAISE WARNING 'Blocked cancellation of delivered order % (delivered_at=%)',
            OLD.id, OLD.delivered_at;
        NEW.status := OLD.status;
        NEW.delivered_at := OLD.delivered_at;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_delivered_orders ON public.orders;

CREATE TRIGGER trg_protect_delivered_orders
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    WHEN (NEW.status IS DISTINCT FROM OLD.status)
    EXECUTE FUNCTION public.protect_delivered_orders();

-- ── Repair the affected order ───────────────────────────────
UPDATE public.orders
SET status = 'delivered'
WHERE id = '653fb6ed-79db-4482-a8c2-7b2da9e6ce92'
  AND delivered_at IS NOT NULL;

-- ── Find any other order left in the same broken state ──────
SELECT id, status, delivered_at, rider_id
FROM public.orders
WHERE delivered_at IS NOT NULL
  AND status <> 'delivered'
ORDER BY delivered_at DESC;
