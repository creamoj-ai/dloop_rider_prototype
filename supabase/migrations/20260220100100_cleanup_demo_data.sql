-- ============================================================
-- SQL 37: Cleanup Demo Data (pre-launch)
-- Date: 2026-02-20
-- Milestone: M6 Scale Ready
-- IDEMPOTENT: Safe to run multiple times
-- ============================================================

-- 1. Delete demo dispatch_log entries (references orders)
DELETE FROM public.dispatch_log
WHERE order_id IN (
  SELECT id FROM public.orders
  WHERE source = 'demo' OR id::text LIKE 'demo_%'
);

-- 2. Delete demo order_relays
DELETE FROM public.order_relays
WHERE order_id IN (
  SELECT id FROM public.orders
  WHERE source = 'demo' OR id::text LIKE 'demo_%'
);

-- 3. Delete demo orders
DELETE FROM public.orders
WHERE source = 'demo' OR id::text LIKE 'demo_%';

-- 4. Clean up incomplete Stripe Express accounts
-- KEEP: Sara Moretti Custom account acct_1T2tTkCsFAfgHWVA (charges+payouts enabled)
-- DELETE: accounts that never completed onboarding
UPDATE public.dealer_platforms
SET stripe_account_id = NULL,
    stripe_onboarding_status = 'pending',
    stripe_charges_enabled = false,
    stripe_payouts_enabled = false,
    stripe_onboarded_at = NULL
WHERE stripe_account_id IS NOT NULL
  AND stripe_account_id != 'acct_1T2tTkCsFAfgHWVA'
  AND stripe_charges_enabled = false;

-- 5. Clean up test whatsapp_conversations (optional — uncomment if needed)
-- DELETE FROM public.whatsapp_messages
-- WHERE conversation_id IN (
--   SELECT id FROM public.whatsapp_conversations
--   WHERE phone LIKE '+1555%'
-- );
-- DELETE FROM public.whatsapp_conversations WHERE phone LIKE '+1555%';

-- 6. Reset bot_messages test data (optional — uncomment if needed)
-- DELETE FROM public.bot_messages WHERE created_at < '2026-02-20';

-- 7. Verify cleanup
SELECT 'demo_orders' AS check_type, count(*) AS remaining
FROM public.orders WHERE source = 'demo' OR id::text LIKE 'demo_%'
UNION ALL
SELECT 'incomplete_stripe', count(*)
FROM public.dealer_platforms
WHERE stripe_account_id IS NOT NULL
  AND stripe_account_id != 'acct_1T2tTkCsFAfgHWVA'
  AND stripe_charges_enabled = false
UNION ALL
SELECT 'active_stripe_accounts', count(*)
FROM public.dealer_platforms
WHERE stripe_account_id IS NOT NULL
  AND stripe_charges_enabled = true;
