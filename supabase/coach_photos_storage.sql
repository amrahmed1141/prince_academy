-- Coach photos storage bucket + read policies
-- Run once in Supabase SQL Editor if coach images fail to load.

INSERT INTO storage.buckets (id, name, public)
VALUES ('coach-photos', 'coach-photos', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- Allow anyone to read coach photos (public bucket)
DROP POLICY IF EXISTS "coach_photos_public_read" ON storage.objects;
CREATE POLICY "coach_photos_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'coach-photos');

-- Allow signed URLs for authenticated users (private bucket fallback)
DROP POLICY IF EXISTS "coach_photos_auth_read" ON storage.objects;
CREATE POLICY "coach_photos_auth_read"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'coach-photos');

-- Admins can upload/replace coach photos
DROP POLICY IF EXISTS "coach_photos_admin_insert" ON storage.objects;
CREATE POLICY "coach_photos_admin_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'coach-photos'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "coach_photos_admin_update" ON storage.objects;
CREATE POLICY "coach_photos_admin_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'coach-photos'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

DROP POLICY IF EXISTS "coach_photos_admin_delete" ON storage.objects;
CREATE POLICY "coach_photos_admin_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'coach-photos'
  AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);
