import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_renew/booking_renew_cubit.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/booking_bottom_bar.dart';
import 'package:prince_academy/features/booking/presentation/widgets/calendar_schedule_picker.dart';
import 'package:prince_academy/features/booking/presentation/widgets/payment_method_sheet.dart';

class BookingRenewPage extends StatefulWidget {
  const BookingRenewPage({super.key});

  @override
  State<BookingRenewPage> createState() => _BookingRenewPageState();
}

class _BookingRenewPageState extends State<BookingRenewPage> {
  final ValueNotifier<int> _stepIndex = ValueNotifier(0);
  late final BookingHistoryModel? _booking;

  @override
  void initState() {
    super.initState();
    _booking = context.read<BookingRenewCubit>().state.current;
  }

  @override
  void dispose() {
    _stepIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookingRenewCubit, BookingRenewState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage ||
          previous.created?.id != current.created?.id,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        if (state.created != null) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final booking = _booking;
        if (booking == null) {
          return const Scaffold(
            body: Center(child: Text('Nothing to renew')),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: _stepIndex,
          builder: (context, step, _) {
            return PopScope(
              canPop: !state.isSubmitting,
              onPopInvoked: (didPop) {
                if (!didPop) return;
                final cubit = context.read<BookingRenewCubit>();
                if (cubit.state.created == null) {
                  cubit.closeRenewFlow();
                }
              },
              child: Theme(
                data: EAppTheme.lightTheme.copyWith(
                  scaffoldBackgroundColor: Colors.transparent,
                ),
                child: Material(
                  color: const Color(0xFFFFF9F5),
                  child: Container(
                    decoration: AppGradients.homeScreenDecoration(),
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        foregroundColor: EColorConstants.authTextDarkBrown,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        title: const Text('Renew booking'),
                      ),
                      body: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          _RenewCoachSummary(booking: booking),
                          const SizedBox(height: 18),
                          _StepHeader(
                            title: step == 0
                                ? 'Step 1 · Start date'
                                : 'Step 2 · Payment',
                            subtitle: step == 0
                                ? 'Same days and time as before'
                                : 'Same price. You can change the method.',
                          ),
                          const SizedBox(height: 12),
                          if (step == 0)
                            CalendarSchedulePicker(
                              availableDays: booking.selectedDays,
                              sessionTime: booking.selectedTime ?? '',
                              selectedStartDate: state.startDate,
                              sessionDates: state.sessionDates,
                              onStartDateSelected: (date) {
                                context
                                    .read<BookingRenewCubit>()
                                    .selectStartDate(date);
                              },
                            )
                          else
                            PaymentMethodSheet(
                              selected: state.paymentMethod,
                              totalPrice: booking.totalPrice,
                              onChanged: (method) {
                                context
                                    .read<BookingRenewCubit>()
                                    .selectPaymentMethod(method);
                              },
                            ),
                        ],
                      ),
                      bottomNavigationBar: BookingBottomBar(
                        enabled: step == 0
                            ? state.startDate != null
                            : state.canSubmit,
                        isLoading: state.isSubmitting,
                        total: booking.totalPrice,
                        buttonText: step == 0 ? 'Next' : 'Confirm renew',
                        onPressed: () {
                          if (step == 0) {
                            if (state.startDate == null) return;
                            _stepIndex.value = 1;
                            return;
                          }
                          context.read<BookingRenewCubit>().submit();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RenewCoachSummary extends StatelessWidget {
  const _RenewCoachSummary({required this.booking});

  final BookingHistoryModel booking;

  @override
  Widget build(BuildContext context) {
    final schedule = [
      SubscriptionFormatters.formatDays(booking.selectedDays),
      if (booking.selectedTime != null && booking.selectedTime!.isNotEmpty)
        booking.selectedTime!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CoachAvatar(
            coachName: booking.coachName,
            photoUrl: booking.coachPhoto,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.coachName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  schedule,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: EColorConstants.primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
