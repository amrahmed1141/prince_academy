-- Core push notifications for user + admin event priorities.
-- Safe to re-run.

CREATE TABLE IF NOT EXISTS public.notification_delivery_keys (
  dedupe_key text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notification_delivery_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notification_delivery_keys_admin_select
  ON public.notification_delivery_keys;
CREATE POLICY notification_delivery_keys_admin_select
  ON public.notification_delivery_keys
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE OR REPLACE FUNCTION public._enqueue_notification(
  p_user_id uuid,
  p_type text,
  p_title text,
  p_body text DEFAULT NULL,
  p_data jsonb DEFAULT '{}'::jsonb,
  p_dedupe_key text DEFAULT NULL,
  p_send_push boolean DEFAULT true
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_notification_id uuid;
  v_token text;
  v_push_url text := 'https://sfeudxyhmivlinvshvpe.functions.supabase.co/send-push';
  v_push_secret text := NULLIF(current_setting('app.push_dispatch_secret', true), '');
BEGIN
  IF p_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  IF p_dedupe_key IS NOT NULL AND btrim(p_dedupe_key) <> '' THEN
    INSERT INTO public.notification_delivery_keys (dedupe_key)
    VALUES (p_dedupe_key)
    ON CONFLICT (dedupe_key) DO NOTHING;

    IF NOT FOUND THEN
      RETURN NULL;
    END IF;
  END IF;

  INSERT INTO public.notifications (user_id, title, body, type, data, is_read)
  VALUES (
    p_user_id,
    p_title,
    p_body,
    p_type,
    COALESCE(p_data, '{}'::jsonb),
    false
  )
  RETURNING id INTO v_notification_id;

  IF NOT p_send_push THEN
    RETURN v_notification_id;
  END IF;

  SELECT p.fcm_token
  INTO v_token
  FROM public.profiles p
  WHERE p.id = p_user_id;

  IF v_token IS NULL OR btrim(v_token) = '' THEN
    RETURN v_notification_id;
  END IF;

  BEGIN
    PERFORM net.http_post(
      url := v_push_url,
      headers := CASE
        WHEN v_push_secret IS NULL THEN
          jsonb_build_object('Content-Type', 'application/json')
        ELSE
          jsonb_build_object(
            'Content-Type', 'application/json',
            'x-push-secret', v_push_secret
          )
      END,
      body := jsonb_build_object(
        'token', v_token,
        'notification', jsonb_build_object('title', p_title, 'body', COALESCE(p_body, '')),
        'data', COALESCE(p_data, '{}'::jsonb) ||
          jsonb_build_object(
            'type', p_type,
            'notification_id', v_notification_id::text
          )
      )
    );
  EXCEPTION
    WHEN undefined_function THEN
      -- pg_net not installed: keep in-app notification row only.
      NULL;
    WHEN OTHERS THEN
      -- Push dispatch failure must not fail business flow.
      NULL;
  END;

  RETURN v_notification_id;
END;
$$;

CREATE OR REPLACE FUNCTION public._notify_admins(
  p_type text,
  p_title text,
  p_body text DEFAULT NULL,
  p_data jsonb DEFAULT '{}'::jsonb,
  p_dedupe_base text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid;
  v_key text;
BEGIN
  FOR v_admin_id IN
    SELECT id
    FROM public.profiles
    WHERE role = 'admin'
  LOOP
    v_key := CASE
      WHEN p_dedupe_base IS NULL OR btrim(p_dedupe_base) = '' THEN NULL
      ELSE p_dedupe_base || ':' || v_admin_id::text
    END;

    PERFORM public._enqueue_notification(
      p_user_id => v_admin_id,
      p_type => p_type,
      p_title => p_title,
      p_body => p_body,
      p_data => p_data,
      p_dedupe_key => v_key,
      p_send_push => true
    );
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public._on_booking_notification_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_data jsonb;
  v_pending_states text[] := ARRAY['pending', 'pending_payment', 'awaiting_verification'];
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF lower(coalesce(NEW.payment_status, '')) = ANY(v_pending_states) THEN
      v_data := jsonb_build_object(
        'type', 'payment_pending',
        'booking_id', NEW.id,
        'user_id', NEW.user_id,
        'payment_method', COALESCE(NEW.payment_method, 'cash')
      );
      PERFORM public._notify_admins(
        p_type => 'payment_pending',
        p_title => 'New pending payment',
        p_body => 'A member submitted a ' || COALESCE(NEW.payment_method, 'cash') || ' payment.',
        p_data => v_data,
        p_dedupe_base => 'payment_pending:' || NEW.id::text
      );
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF lower(coalesce(OLD.payment_status, '')) <> 'verified'
      AND lower(coalesce(NEW.payment_status, '')) = 'verified' THEN
      PERFORM public._enqueue_notification(
        p_user_id => NEW.user_id,
        p_type => 'booking_confirmed',
        p_title => 'Booking confirmed',
        p_body => 'Your payment was verified and your booking is now active.',
        p_data => jsonb_build_object('type', 'booking_confirmed', 'booking_id', NEW.id),
        p_dedupe_key => 'booking_confirmed:' || NEW.id::text,
        p_send_push => true
      );
    END IF;

    IF lower(coalesce(OLD.status, '')) <> 'rejected'
      AND lower(coalesce(NEW.status, '')) = 'rejected' THEN
      PERFORM public._enqueue_notification(
        p_user_id => NEW.user_id,
        p_type => 'booking_rejected',
        p_title => 'Booking rejected',
        p_body => 'Your payment was rejected. Please review and submit again.',
        p_data => jsonb_build_object('type', 'booking_rejected', 'booking_id', NEW.id),
        p_dedupe_key => 'booking_rejected:' || NEW.id::text,
        p_send_push => true
      );
    END IF;

    IF lower(coalesce(OLD.payment_status, '')) <> ANY(v_pending_states)
      AND lower(coalesce(NEW.payment_status, '')) = ANY(v_pending_states) THEN
      v_data := jsonb_build_object(
        'type', 'payment_pending',
        'booking_id', NEW.id,
        'user_id', NEW.user_id,
        'payment_method', COALESCE(NEW.payment_method, 'cash')
      );
      PERFORM public._notify_admins(
        p_type => 'payment_pending',
        p_title => 'New pending payment',
        p_body => 'A member submitted a ' || COALESCE(NEW.payment_method, 'cash') || ' payment.',
        p_data => v_data,
        p_dedupe_base => 'payment_pending:' || NEW.id::text
      );
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF lower(coalesce(OLD.payment_method, '')) = 'cash'
      AND lower(coalesce(OLD.payment_status, '')) = ANY(v_pending_states) THEN
      PERFORM public._enqueue_notification(
        p_user_id => OLD.user_id,
        p_type => 'booking_auto_cancelled',
        p_title => 'Booking auto-cancelled',
        p_body => 'Your cash booking expired after 3 days without verification.',
        p_data => jsonb_build_object('type', 'booking_auto_cancelled', 'booking_id', OLD.id),
        p_dedupe_key => 'booking_auto_cancelled:' || OLD.id::text,
        p_send_push => true
      );
    END IF;
    RETURN OLD;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_booking_notification_events ON public.bookings;
CREATE TRIGGER trg_booking_notification_events
AFTER INSERT OR UPDATE OR DELETE ON public.bookings
FOR EACH ROW
EXECUTE FUNCTION public._on_booking_notification_events();

CREATE OR REPLACE FUNCTION public._on_freeze_notification_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_data jsonb;
BEGIN
  IF TG_OP = 'INSERT' AND NEW.status = 'pending' THEN
    v_data := jsonb_build_object(
      'type', 'freeze_request',
      'freeze_id', NEW.id,
      'booking_id', NEW.booking_id,
      'user_id', NEW.user_id
    );
    PERFORM public._notify_admins(
      p_type => 'freeze_request',
      p_title => 'New freeze request',
      p_body => 'A member submitted a session freeze request.',
      p_data => v_data,
      p_dedupe_base => 'freeze_request:' || NEW.id::text
    );
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.status = 'pending' AND NEW.status IN ('approved', 'rejected') THEN
    PERFORM public._enqueue_notification(
      p_user_id => NEW.user_id,
      p_type => 'freeze_review',
      p_title => CASE WHEN NEW.status = 'approved' THEN 'Freeze approved' ELSE 'Freeze rejected' END,
      p_body => CASE
        WHEN NEW.status = 'approved' THEN
          'Your freeze was approved. New expiry date: ' || COALESCE(NEW.new_subscription_end::text, 'updated')
        ELSE
          'Your freeze request was rejected.'
      END,
      p_data => jsonb_build_object(
        'type', 'freeze_review',
        'freeze_id', NEW.id,
        'booking_id', NEW.booking_id,
        'status', NEW.status,
        'new_subscription_end', NEW.new_subscription_end
      ),
      p_dedupe_key => 'freeze_review:' || NEW.id::text || ':' || NEW.status,
      p_send_push => true
    );
    RETURN NEW;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_freeze_notification_events ON public.booking_freezes;
CREATE TRIGGER trg_freeze_notification_events
AFTER INSERT OR UPDATE ON public.booking_freezes
FOR EACH ROW
EXECUTE FUNCTION public._on_freeze_notification_events();

CREATE OR REPLACE FUNCTION public._on_attendance_notification_events()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF lower(coalesce(NEW.status, '')) = 'attended' THEN
    PERFORM public._enqueue_notification(
      p_user_id => NEW.user_id,
      p_type => 'attendance',
      p_title => 'Attendance marked',
      p_body => 'Your attendance has been marked for today.',
      p_data => jsonb_build_object(
        'type', 'attendance',
        'booking_id', NEW.booking_id,
        'attended_on', NEW.attended_on
      ),
      p_dedupe_key => 'attendance:' || NEW.booking_id::text || ':' || NEW.attended_on::text,
      p_send_push => true
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_attendance_notification_events ON public.attendance;
CREATE TRIGGER trg_attendance_notification_events
AFTER INSERT ON public.attendance
FOR EACH ROW
EXECUTE FUNCTION public._on_attendance_notification_events();

CREATE OR REPLACE FUNCTION public.send_session_reminder_notifications()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
  v_count integer := 0;
  v_session_at timestamptz;
BEGIN
  FOR r IN
    SELECT
      us.booking_id,
      us.user_id,
      us.session_date,
      b.selected_time
    FROM public.user_schedules us
    JOIN public.bookings b ON b.id = us.booking_id
    WHERE us.session_date >= CURRENT_DATE
      AND lower(coalesce(us.session_status, us.status, 'upcoming')) IN ('upcoming', 'scheduled')
      AND lower(coalesce(b.status, '')) IN ('active', 'approved')
      AND lower(coalesce(b.payment_status, '')) IN ('verified', 'paid', 'active')
  LOOP
    BEGIN
      v_session_at := (r.session_date::text || ' ' || r.selected_time)::timestamptz;
    EXCEPTION
      WHEN OTHERS THEN
        CONTINUE;
    END;

    IF v_session_at > now() + interval '1 hour' AND v_session_at <= now() + interval '2 hours' THEN
      PERFORM public._enqueue_notification(
        p_user_id => r.user_id,
        p_type => 'session_reminder',
        p_title => 'Session reminder',
        p_body => 'You have a booked session in about 1-2 hours.',
        p_data => jsonb_build_object(
          'type', 'session_reminder',
          'booking_id', r.booking_id,
          'session_date', r.session_date
        ),
        p_dedupe_key => 'session_reminder:' || r.booking_id::text || ':' || r.session_date::text,
        p_send_push => true
      );
      v_count := v_count + 1;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.send_subscription_expiry_notifications()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
  v_count integer := 0;
  v_days_left integer;
BEGIN
  FOR r IN
    SELECT id, user_id, subscription_end
    FROM public.bookings
    WHERE subscription_end IS NOT NULL
      AND lower(coalesce(status, '')) IN ('active', 'approved')
      AND lower(coalesce(payment_status, '')) IN ('verified', 'paid', 'active')
  LOOP
    v_days_left := (r.subscription_end::date - CURRENT_DATE);
    IF v_days_left IN (3, 1) THEN
      PERFORM public._enqueue_notification(
        p_user_id => r.user_id,
        p_type => 'subscription',
        p_title => 'Subscription expiring soon',
        p_body => CASE
          WHEN v_days_left = 1 THEN 'Your subscription expires tomorrow.'
          ELSE 'Your subscription expires in 3 days.'
        END,
        p_data => jsonb_build_object(
          'type', 'subscription',
          'booking_id', r.id,
          'subscription_end', r.subscription_end,
          'days_left', v_days_left
        ),
        p_dedupe_key => 'subscription_expiry:' || r.id::text || ':' || v_days_left::text || ':' || CURRENT_DATE::text,
        p_send_push => true
      );
      v_count := v_count + 1;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.send_admin_low_attendance_notifications()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r record;
  v_count integer := 0;
BEGIN
  FOR r IN
    SELECT user_id, full_name
    FROM public.get_dashboard_low_attendance_members(14, 25)
  LOOP
    PERFORM public._notify_admins(
      p_type => 'needs_attention',
      p_title => 'Member needs attention',
      p_body => COALESCE(r.full_name, 'Member') || ' has low attendance and needs follow-up.',
      p_data => jsonb_build_object(
        'type', 'needs_attention',
        'user_id', r.user_id
      ),
      p_dedupe_base => 'needs_attention:' || r.user_id::text || ':' || CURRENT_DATE::text
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_net;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'notifications-session-reminder') THEN
    PERFORM cron.unschedule('notifications-session-reminder');
  END IF;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'notifications-subscription-expiry') THEN
    PERFORM cron.unschedule('notifications-subscription-expiry');
  END IF;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'notifications-low-attendance') THEN
    PERFORM cron.unschedule('notifications-low-attendance');
  END IF;

  PERFORM cron.schedule(
    'notifications-session-reminder',
    '*/30 * * * *',
    $job$SELECT public.send_session_reminder_notifications();$job$
  );
  PERFORM cron.schedule(
    'notifications-subscription-expiry',
    '10 9 * * *',
    $job$SELECT public.send_subscription_expiry_notifications();$job$
  );
  PERFORM cron.schedule(
    'notifications-low-attendance',
    '20 9 * * *',
    $job$SELECT public.send_admin_low_attendance_notifications();$job$
  );
EXCEPTION
  WHEN undefined_table THEN
    RAISE NOTICE 'pg_cron unavailable — scheduled notification jobs not installed.';
END $$;
