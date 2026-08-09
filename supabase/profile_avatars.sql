-- Profile avatars: column + public storage bucket
-- Run once in Supabase → SQL Editor (safe to re-run).
-- Live DB historically used photo_url; keep both in sync for readers.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url text;

-- Backfill avatar_url from photo_url when only photo_url is set.
UPDATE public.profiles
SET avatar_url = photo_url
WHERE avatar_url IS NULL
  AND photo_url IS NOT NULL;

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-avatars', 'profile-avatars', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "profile_avatars_public_read" ON storage.objects;
CREATE POLICY "profile_avatars_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-avatars');

DROP POLICY IF EXISTS "profile_avatars_owner_insert" ON storage.objects;
CREATE POLICY "profile_avatars_owner_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "profile_avatars_owner_update" ON storage.objects;
CREATE POLICY "profile_avatars_owner_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "profile_avatars_owner_delete" ON storage.objects;
CREATE POLICY "profile_avatars_owner_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);
