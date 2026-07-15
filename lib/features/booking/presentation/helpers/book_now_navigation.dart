import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/custom_snackbar.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_page.dart';
import 'package:prince_academy/features/booking/presentation/widgets/branch_picker_sheet.dart';

class BookNowNavigation {
  const BookNowNavigation._();

  static Future<void> openBookingForCoach({
    required BuildContext context,
    required String coachId,
    required String coachName,
    required String coachImage,
    required String specialty,
    String? branchId,
    String? branchName,
  }) async {
    List<String> bookedCoachIds = const [];
    try {
      bookedCoachIds = context.read<BookingBloc>().state.bookedCoachIds;
    } catch (_) {}

    if (bookedCoachIds.isEmpty) {
      try {
        bookedCoachIds = await sl<BookingRepository>().getUserActiveCoachIds();
      } catch (_) {}
    }

    if (bookedCoachIds.contains(coachId)) {
      if (!context.mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'You already have an active booking for $coachName',
      );
      return;
    }

    try {
      final isDuplicate =
          await sl<BookingRepository>().hasActiveBookingWithCoach(coachId);
      if (isDuplicate) {
        if (!context.mounted) return;
        CustomSnackbar.show(
          context: context,
          message: 'You already have an active booking for $coachName',
        );
        return;
      }
    } catch (_) {}

    if (!context.mounted) return;

    var resolvedBranchId = branchId;
    var resolvedBranchName = branchName;

    if (resolvedBranchId == null || resolvedBranchId.isEmpty) {
      try {
        final sessions =
            await sl<BookingRepository>().getActiveSessions(coachId);
        final branches = uniqueBranchesFromSessions(sessions);

        if (branches.length > 1) {
          if (!context.mounted) return;
          final selected = await showBranchPickerSheet(
            context: context,
            branches: branches,
          );
          if (selected == null) return;
          resolvedBranchId = selected.id;
          resolvedBranchName = selected.name;
        } else if (branches.length == 1) {
          resolvedBranchId = branches.first.id;
          resolvedBranchName = branches.first.name;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(
          bookingInfo: MMABookingModel(
            coachId: coachId,
            coachName: coachName,
            coachImage: coachImage,
            specialty: specialty,
            coachWhatsapp: '+1234567890',
            branchId: resolvedBranchId,
            branchName: resolvedBranchName,
          ),
          initialBookedCoachIds: bookedCoachIds,
        ),
      ),
    );
  }
}
