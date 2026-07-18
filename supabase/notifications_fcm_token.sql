-- Notifications + FCM token support for Prince Academy.
-- Safe to re-run. Live project already has public.notifications.

-- Latest device token used to send Firebase push messages.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS fcm_token text;

COMMENT ON COLUMN public.profiles.fcm_token IS
  'Latest Firebase Cloud Messaging device token for push notifications.';

-- In-app notification feed (idempotent create for local/dev setups).
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  title text NOT NULL,
  body text,
  type text NOT NULL,
  data jsonb,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_created_at_idx
  ON public.notifications (user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_can_view_own_notifications ON public.notifications;
CREATE POLICY users_can_view_own_notifications
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS users_can_update_own_notifications ON public.notifications;
CREATE POLICY users_can_update_own_notifications
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users update their own fcm_token via existing profiles UPDATE policies.
-- Realtime for unread badge + live list.
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
