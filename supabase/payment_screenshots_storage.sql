-- InstaPay payment screenshot storage bucket + policies
-- Run once in Supabase SQL Editor if admin cannot view uploaded screenshots.

INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-screenshots', 'payment-screenshots', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- Public read (matches getPublicUrl in the Flutter app)
DROP POLICY IF EXISTS "payment_screenshots_public_read" ON storage.objects;
CREATE POLICY "payment_screenshots_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'payment-screenshots');

-- Authenticated read fallback
DROP POLICY IF EXISTS "payment_screenshots_auth_read" ON storage.objects;
CREATE POLICY "payment_screenshots_auth_read"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'payment-screenshots');

-- Members upload to payments/{user_id}/...
DROP POLICY IF EXISTS "payment_screenshots_user_insert" ON storage.objects;
CREATE POLICY "payment_screenshots_user_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'payment-screenshots'
  AND (storage.foldername(name))[1] = 'payments'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Required for upsert: true in the Flutter upload call
DROP POLICY IF EXISTS "payment_screenshots_user_select" ON storage.objects;
CREATE POLICY "payment_screenshots_user_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment-screenshots'
  AND (storage.foldername(name))[1] = 'payments'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

DROP POLICY IF EXISTS "payment_screenshots_user_update" ON storage.objects;
CREATE POLICY "payment_screenshots_user_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'payment-screenshots'
  AND (storage.foldername(name))[1] = 'payments'
  AND (storage.foldername(name))[2] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'payment-screenshots'
  AND (storage.foldername(name))[1] = 'payments'
  AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Admins can read every payment screenshot
DROP POLICY IF EXISTS "payment_screenshots_admin_select" ON storage.objects;
CREATE POLICY "payment_screenshots_admin_select"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'payment-screenshots'
  AND public.is_admin()
);
