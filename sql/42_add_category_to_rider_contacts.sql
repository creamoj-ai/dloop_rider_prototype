-- ============================================
-- 42. Add category field to rider_contacts
-- ============================================
-- Add category field to filter dealers by type (grocery, pet, pharmacy, etc.)
-- This field is critical for the Daily Delivery MVP pivot

ALTER TABLE public.rider_contacts
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'grocery'
CHECK (category IN ('grocery', 'pet', 'pharmacy', 'fashion', 'beauty', 'wellness', 'home_garden', 'electronics'));

CREATE INDEX IF NOT EXISTS idx_rider_contacts_category ON public.rider_contacts(category);

-- Update existing dealers to have a category (default to grocery)
UPDATE public.rider_contacts
SET category = 'grocery'
WHERE category IS NULL;
