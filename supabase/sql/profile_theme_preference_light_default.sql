-- ASTRA brightness default hardening.
--
-- This changes only the default used by future profile inserts that omit
-- theme_preference. Existing light/dark/sakura values are not updated.

ALTER TABLE public.profiles
  ALTER COLUMN theme_preference SET DEFAULT 'light';
