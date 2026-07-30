# RPC excerpts

## A. SQL — `create_booking_with_schedule`

SOURCE: `supabase/booking_flow.sql`

```sql
CREATE OR REPLACE FUNCTION public.create_booking_with_schedule(
  p_user_id uuid,
  p_coach_id uuid,
  p_branch_id uuid,
  p_days text[],
  p_time text,
  p_start_date date,
  p_price numeric,
  p_method text,
  p_payment_reference text DEFAULT NULL
)
RETURNS public.bookings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_booking public.bookings;
  -- …
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Cannot create booking for another user';
  END IF;

  -- insert booking + generate_user_schedules — see full SQL source
  RETURN v_booking;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_booking_with_schedule(
  uuid, uuid, uuid, text[], text, date, numeric, text, text
) TO authenticated;
```

## B. Dart — call site in datasource

SOURCE: `lib/features/booking/data/datasources/booking_remote_ds.dart`

```dart
final response = await _supabase.rpc(
  'create_booking_with_schedule',
  params: {
    'p_user_id': userId,
    'p_coach_id': coachId,
    'p_branch_id': branchId,
    'p_days': days,
    'p_time': time,
    'p_start_date': SessionScheduleHelper.formatDateForDb(startDate),
    'p_price': price,
    'p_method': method,
    if (paymentReference != null) 'p_payment_reference': paymentReference,
  },
);

if (response is Map) {
  return BookingModel.fromJson(Map<String, dynamic>.from(response));
}
// … list / error handling — see source

} on PostgrestException catch (e) {
  throw Exception(_mapPostgrestError(e, 'create booking'));
}
```

## C. Simpler mutation — `cancel_booking`

SQL SOURCE: `supabase/user_booking_actions.sql`  
Dart SOURCE: same `booking_remote_ds.dart`

```dart
Future<void> cancelBooking(String bookingId) async {
  try {
    await _supabase.rpc('cancel_booking', params: {
      'p_booking_id': bookingId,
    });
  } on PostgrestException catch (e) {
    throw Exception(_mapPostgrestError(e, 'cancel booking'));
  }
}
```
