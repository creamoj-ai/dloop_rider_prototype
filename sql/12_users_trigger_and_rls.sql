-- ============================================================================
-- DLoop Rider Prototype - Users Table: Trigger + RLS
-- ============================================================================
-- This script:
--   1. Creates a trigger function that auto-creates a `users` row
--      whenever a new user signs up via Supabase Auth
--   2. Enables RLS on the `users` table
--   3. Adds SELECT/UPDATE policies (id = auth.uid())
--   4. Backfills existing auth users who don't have a `users` row
-- ============================================================================

-- ========================================================================
-- STEP 1: Trigger function — auto-create users row on auth signup
-- ========================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_full_name TEXT;
    v_first_name TEXT;
    v_last_name TEXT;
BEGIN
    -- Extract full_name from signup metadata
    v_full_name := COALESCE(NEW.raw_user_meta_data->>'full_name', '');

    -- Parse first/last name
    IF v_full_name != '' AND POSITION(' ' IN v_full_name) > 0 THEN
        v_first_name := SPLIT_PART(v_full_name, ' ', 1);
        v_last_name  := SUBSTRING(v_full_name FROM POSITION(' ' IN v_full_name) + 1);
    ELSE
        v_first_name := NULLIF(v_full_name, '');
        v_last_name  := NULL;
    END IF;

    INSERT INTO public.users (
        id,
        email,
        first_name,
        last_name,
        is_online,
        is_active,
        total_earnings,
        rating,
        total_orders,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.email,
        v_first_name,
        v_last_name,
        false,
        true,
        0.0,
        5.0,
        0,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- ========================================================================
-- STEP 2: Attach trigger to auth.users
-- ========================================================================
-- Drop if exists to allow re-running
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ========================================================================
-- STEP 3: Enable RLS + policies on users table
-- ========================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to allow re-running
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

-- SELECT: users can only read their own row
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (id = auth.uid());

-- UPDATE: users can only update their own row
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- ========================================================================
-- STEP 4: Backfill existing auth users who don't have a users row
-- ========================================================================
INSERT INTO public.users (id, email, first_name, last_name, is_online, is_active, total_earnings, rating, total_orders, created_at, updated_at)
SELECT
    au.id,
    au.email,
    CASE
        WHEN COALESCE(au.raw_user_meta_data->>'full_name', '') != ''
             AND POSITION(' ' IN COALESCE(au.raw_user_meta_data->>'full_name', '')) > 0
        THEN SPLIT_PART(au.raw_user_meta_data->>'full_name', ' ', 1)
        ELSE NULLIF(COALESCE(au.raw_user_meta_data->>'full_name', ''), '')
    END AS first_name,
    CASE
        WHEN COALESCE(au.raw_user_meta_data->>'full_name', '') != ''
             AND POSITION(' ' IN COALESCE(au.raw_user_meta_data->>'full_name', '')) > 0
        THEN SUBSTRING(au.raw_user_meta_data->>'full_name' FROM POSITION(' ' IN au.raw_user_meta_data->>'full_name') + 1)
        ELSE NULL
    END AS last_name,
    false,
    true,
    0.0,
    5.0,
    0,
    NOW(),
    NOW()
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
);
