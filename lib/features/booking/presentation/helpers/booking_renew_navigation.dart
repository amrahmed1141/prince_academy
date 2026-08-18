import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/main_tab_controller.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_renew/booking_renew_cubit.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_renew_page.dart';
import 'package:prince_academy/features/booking/presentation/widgets/booking_confirmation_dialog.dart';
import 'package:prince_academy/features/booking/presentation/widgets/instapay_payment_sheet.dart';

/// Opens the member renew wizard for a specific booking (history Renew button).
class BookingRenewNavigation {
  const BookingRenewNavigation._();

  static Future<void> openForBooking(
    BuildContext context,
    BookingHistoryModel booking,
  ) async {
    BookingRenewCubit? shellCubit;
    try {
      shellCubit = context.read<BookingRenewCubit>();
    } catch (_) {}

    final ownsCubit = shellCubit == null;
    final cubit = shellCubit ?? sl<BookingRenewCubit>();
    cubit.startRenewFor(booking);

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const BookingRenewPage(),
        ),
      ),
    );

    if (ownsCubit) {
      final state = cubit.state;
      if (context.mounted && state.created != null) {
        await showBookingRenewSuccess(context, state);
        cubit.clearCreated();
      }
      await cubit.close();
    }
  }
}

/// Shared success sheets after a renew completes (shell prompt or history).
Future<void> showBookingRenewSuccess(
  BuildContext context,
  BookingRenewState state,
) async {
  final booking = state.created;
  final start = state.createdStartDate;
  final end = state.createdEndDate;
  if (booking == null || start == null || end == null) return;

  final method = booking.paymentMethod?.toLowerCase();
  if (method == PaymentMethod.instapay.name) {
    await InstaPayPaymentSheet.show(
      context,
      booking: booking,
      sessionTime: state.createdSessionTime ?? '',
      startDate: start,
      endDate: end,
      onUploadScreenshot: (file) async {
        final bookingId = booking.id;
        if (bookingId == null || bookingId.isEmpty) {
          throw Exception('Booking not found. Please try again.');
        }
        await sl<BookingRepository>().uploadPaymentScreenshot(
          bookingId: bookingId,
          file: file,
        );
      },
      onConfirmPayment: () async {
        final bookingId = booking.id;
        if (bookingId != null && bookingId.isNotEmpty) {
          await sl<BookingRepository>().confirmInstaPayPayment(bookingId);
        }
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        sl<MainTabController>().select(MainTabController.booking);
      },
    );
  } else {
    await BookingConfirmationDialog.show(
      context,
      booking: booking,
      startDate: start,
      endDate: end,
      onClose: () {
        sl<MainTabController>().select(MainTabController.home);
      },
      onViewBookings: () {
        sl<MainTabController>().select(MainTabController.booking);
      },
    );
  }
}
