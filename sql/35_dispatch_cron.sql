-- ============================================================
-- SQL 35: Dispatch Auto-Escalation via pg_cron
-- ============================================================
-- Milestone: M4 Smart Dispatch
-- Handles expired priority assignments:
--   - dispatch_attempts < 3 → reset to 'pending' (operator re-dispatches)
--   - dispatch_attempts >= 3 → escalate to 'broadcast' (visible to all riders)
-- Logs all escalation actions to dispatch_log.
-- ============================================================

-- Enable pg_cron (Supabase has it pre-installed, just needs enabling)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ── 1. Escalation function ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.escalate_expired_dispatches()
RETURNS void AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT id, dispatch_attempts, assigned_rider_id
        FROM public.orders
        WHERE dispatch_status = 'assigned'
          AND priority_expires_at IS NOT NULL
          AND priority_expires_at < now()
    LOOP
        -- Log the timeout
        INSERT INTO public.dispatch_log (order_id, rider_id, action, attempt_number)
        VALUES (r.id, r.assigned_rider_id, 'timeout', COALESCE(r.dispatch_attempts, 0) + 1);

        IF COALESCE(r.dispatch_attempts, 0) >= 3 THEN
            -- Max attempts reached → broadcast to all riders
            UPDATE public.orders SET
                assigned_rider_id = NULL,
                priority_expires_at = NULL,
                dispatch_status = 'broadcast',
                dispatch_attempts = COALESCE(r.dispatch_attempts, 0) + 1
            WHERE id = r.id;

            INSERT INTO public.dispatch_log (order_id, rider_id, action, attempt_number)
            VALUES (r.id, NULL, 'broadcast', COALESCE(r.dispatch_attempts, 0) + 1);
        ELSE
            -- Reset to pending for re-dispatch
            UPDATE public.orders SET
                assigned_rider_id = NULL,
                priority_expires_at = NULL,
                dispatch_status = 'pending',
                dispatch_attempts = COALESCE(r.dispatch_attempts, 0) + 1
            WHERE id = r.id;

            INSERT INTO public.dispatch_log (order_id, rider_id, action, attempt_number)
            VALUES (r.id, NULL, 'escalated', COALESCE(r.dispatch_attempts, 0) + 1);
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 2. Schedule cron job (every minute — Supabase minimum) ──
SELECT cron.schedule(
    'escalate-expired-dispatches',
    '* * * * *',
    'SELECT public.escalate_expired_dispatches()'
);
