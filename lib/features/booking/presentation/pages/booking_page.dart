import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/app/app.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_state.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/booking_bottom_bar.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/coach_header_card.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_history_page.dart';
import 'package:prince_academy/features/booking/presentation/widgets/booking_confirmation_dialog.dart';
import 'package:prince_academy/features/booking/presentation/widgets/calendar_schedule_picker.dart';
import 'package:prince_academy/features/booking/presentation/widgets/day_selector.dart';
import 'package:prince_academy/features/booking/presentation/widgets/instapay_payment_sheet.dart';
import 'package:prince_academy/features/booking/presentation/widgets/payment_method_sheet.dart';

/// MODIFIED: 4-step booking wizard — coach → days → calendar → payment
class BookingPage extends StatelessWidget {
  final MMABookingModel bookingInfo;
  final List<String> initialBookedCoachIds;

  const BookingPage({
    super.key,
    required this.bookingInfo,
    this.initialBookedCoachIds = const [],
  });

  @override
  Widget build(BuildContext context) {
    final coachId = bookingInfo.coachId;
    if (coachId == null || coachId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Coach not found')),
      );
    }

    return BlocProvider(
      create: (_) => BookingBloc(
        sl<BookingRepository>(),
        bookedCoachIds: initialBookedCoachIds,
      )..add(
          CheckDuplicateBooking(
            coachId: coachId,
            coachName: bookingInfo.coachName,
            coachImage: bookingInfo.coachImage,
            specialty: bookingInfo.specialty,
          ),
        ),
      child: _BookingWizardView(bookingInfo: bookingInfo),
    );
  }
}

class _BookingWizardView extends StatefulWidget {
  final MMABookingModel bookingInfo;

  const _BookingWizardView({required this.bookingInfo});

  @override
  State<_BookingWizardView> createState() => _BookingWizardViewState();
}

class _BookingWizardViewState extends State<_BookingWizardView> {
  final ValueNotifier<int> _stepIndex = ValueNotifier(0);
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _confirmingInstaPay = false;
  bool _showDaysValidationError = false;

  @override
  void dispose() {
    _stepIndex.dispose();
    super.dispose();
  }

  void _goToStep(int step) => _stepIndex.value = step;

  BookingWizardData? _dataFromState(BookingState state) {
    return switch (state) {
      BookingStep1CoachSelected s => s.data,
      BookingStep2DaysSelected s => s.data,
      BookingStep3DateSelected s => s.data,
      BookingStep4PaymentSelected s => s.data,
      BookingCreating s => s.data,
      _ => null,
    };
  }

  void _handleContinue(BuildContext context, BookingState state) {
    if (state is BookingStep1CoachSelected) {
      _showDaysValidationError = false;
      context.read<BookingBloc>().add(SelectDays(state.data.selectedDays));
      _goToStep(1);
      return;
    }

    final step = _stepIndex.value;

    if (step == 1) {
      final data = _dataFromState(state);
      if (data == null || data.selectedDays.length < 2) {
        setState(() => _showDaysValidationError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least 2 days'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      setState(() => _showDaysValidationError = false);
      _goToStep(2);
      return;
    }

    if (step == 2 && state is BookingStep3DateSelected) {
      context.read<BookingBloc>().add(
            SelectPaymentMethod(_paymentMethod.apiValue),
          );
      _goToStep(3);
      return;
    }

    if (step == 3 && state is BookingStep4PaymentSelected) {
      context.read<BookingBloc>().add(const CreateBooking());
    }
  }

  bool _canContinue(BookingState state, int step) {
    if (step == 0) return state is BookingStep1CoachSelected;
    if (step == 1) {
      final data = _dataFromState(state);
      return data != null && data.selectedDays.length >= 2;
    }
    if (step == 2) {
      return state is BookingStep3DateSelected ||
          state is BookingStep4PaymentSelected;
    }
    if (step == 3) return state is BookingStep4PaymentSelected;
    return false;
  }

  double _total(BookingState state) {
    final data = _dataFromState(state);
    return data?.totalPrice ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFFF7F7F7);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return BlocConsumer<BookingBloc, BookingState>(
      listenWhen: (previous, current) =>
          current is BookingCheckResult ||
          current is BookingError ||
          current is BookingCreated,
      listener: (context, state) {
        if (state is BookingCheckResult && state.isDuplicate) {
          final coachName = state.existingCoachName ?? 'this coach';
          Navigator.of(context).pop();
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('You already have an active booking for $coachName'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        if (state is BookingCreated) {
          final method = state.booking.paymentMethod?.toLowerCase();
          if (method == PaymentMethod.cash.name) {
            BookingConfirmationDialog.show(
              context,
              booking: state.booking,
              startDate: state.data.startDate!,
              endDate: state.data.endDate!,
              onViewBookings: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const BookingHistoryPage(),
                  ),
                  (route) => route.isFirst,
                );
              },
            );
          } else {
            InstaPayPaymentSheet.show(
              context,
              booking: state.booking,
              sessionTime: state.data.sessionTime,
              startDate: state.data.startDate!,
              endDate: state.data.endDate!,
              isConfirming: _confirmingInstaPay,
              onUploadScreenshot: (file) async {
                final created = context.read<BookingBloc>().state;
                if (created is! BookingCreated) {
                  throw Exception('Booking not found. Please try again.');
                }

                final bookingId = created.booking.id;
                if (bookingId == null || bookingId.isEmpty) {
                  throw Exception('Booking not found. Please try again.');
                }

                await sl<BookingRepository>().uploadPaymentScreenshot(
                  bookingId: bookingId,
                  file: file,
                );
              },
              onConfirmPayment: () async {
                setState(() => _confirmingInstaPay = true);
                context.read<BookingBloc>().add(const ConfirmInstaPayPayment());
                if (!context.mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const BookingHistoryPage(),
                  ),
                  (route) => route.isFirst,
                );
              },
            );
          }
        }
      },
      builder: (context, state) {
        if (state is BookingLoading ||
            state is BookingInitial ||
            state is BookingCheckLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book a Session')),
            backgroundColor: scaffoldBg,
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                CoachHeaderCard(info: widget.bookingInfo),
                const SizedBox(height: 48),
                const Center(
                  child: CircularProgressIndicator(
                    color: EColorConstants.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }

        if (state is BookingError && state.message.contains('No schedule')) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking')),
            backgroundColor: scaffoldBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          );
        }

        if (state is BookingError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book a Session')),
            backgroundColor: scaffoldBg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.warning_2,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final wizardState = switch (state) {
          BookingStep1CoachSelected s => s,
          BookingStep2DaysSelected s => s,
          BookingStep3DateSelected s => s,
          BookingStep4PaymentSelected s => s,
          BookingCreating _ => null,
          BookingCreated _ => null,
          _ => null,
        };

        if (wizardState == null && state is! BookingCreating) {
          if (state is BookingCheckResult && state.isDuplicate) {
            return const Scaffold(
              backgroundColor: scaffoldBg,
              body: SizedBox.shrink(),
            );
          }
          if (state is BookingCreated) {
            return Scaffold(
              appBar: AppBar(title: const Text('Book a Session')),
              backgroundColor: scaffoldBg,
              body: const Center(
                child: CircularProgressIndicator(
                  color: EColorConstants.primaryColor,
                ),
              ),
            );
          }
          return Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(title: const Text('Book a Session')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load booking',
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          );
        }

        final isCreating = state is BookingCreating;
        final wizardData = _dataFromState(state);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Book a Session'),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.message),
                onPressed: () {},
              ),
            ],
          ),
          backgroundColor: scaffoldBg,
          body: ValueListenableBuilder<int>(
              valueListenable: _stepIndex,
              builder: (context, step, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: [
                    _StepIndicator(currentStep: step),
                    const SizedBox(height: 16),
                    CoachHeaderCard(info: widget.bookingInfo),
                    const SizedBox(height: 18),
                    if (step == 0) ...[
                      const _SectionHeader(
                        title: 'Step 1 · Confirm Coach',
                        subtitle: 'Review your coach and continue',
                      ),
                      const SizedBox(height: 8),
                      if (wizardData?.coach.branchName != null)
                        Text(
                          'Branch: ${wizardData!.coach.branchName}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                    // ADDED: Step 2 — choose days per week
                    if (step == 1 && wizardData != null) ...[
                      const _SectionHeader(
                        title: 'Step 2 · Training Days',
                        subtitle: 'Select at least 2 days per week',
                      ),
                      const SizedBox(height: 12),
                      DaySelector(
                        availableDays: wizardData.availableDays,
                        selectedDays: wizardData.selectedDays,
                        coachName: wizardData.coach.name,
                        showValidationError: _showDaysValidationError,
                        onChanged: (days) {
                          if (_showDaysValidationError && days.length >= 2) {
                            setState(() => _showDaysValidationError = false);
                          }
                          context.read<BookingBloc>().add(SelectDays(days));
                        },
                      ),
                    ],
                    if (step == 2 && wizardData != null) ...[
                      const _SectionHeader(
                        title: 'Step 3 · Calendar Schedule',
                        subtitle: 'Pick your subscription start date',
                      ),
                      const SizedBox(height: 12),
                      CalendarSchedulePicker(
                        availableDays: wizardData.selectedDays,
                        sessionTime: wizardData.sessionTime,
                        selectedStartDate: wizardData.startDate,
                        sessionDates: wizardData.sessionDates,
                        isLoading: false,
                        onStartDateSelected: (date) {
                          context
                              .read<BookingBloc>()
                              .add(SelectStartDate(date));
                        },
                      ),
                    ],
                    if (step == 3 && wizardData != null) ...[
                      const _SectionHeader(
                        title: 'Step 4 · Payment',
                        subtitle: 'Choose payment method and continue',
                      ),
                      const SizedBox(height: 12),
                      PaymentMethodSheet(
                        selected: _paymentMethod,
                        totalPrice: _total(state),
                        onChanged: (method) {
                          setState(() => _paymentMethod = method);
                          context.read<BookingBloc>().add(
                                SelectPaymentMethod(method.apiValue),
                              );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
            bottomNavigationBar: wizardState != null || isCreating
                ? ValueListenableBuilder<int>(
                    valueListenable: _stepIndex,
                    builder: (context, step, _) {
                      final isLastStep = step == 3;
                      return BookingBottomBar(
                        enabled: _canContinue(state, step) && !isCreating,
                        isLoading: isCreating,
                        total: _total(state),
                        buttonText: isLastStep ? 'Continue' : 'Next',
                        onPressed: _canContinue(state, step) && !isCreating
                            ? () => _handleContinue(context, state)
                            : null,
                      );
                    },
                  )
                : null,
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    // ADDED: 4 steps including Days
    const labels = ['Coach', 'Days', 'Schedule', 'Payment'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: active
                          ? EColorConstants.primaryColor
                          : Colors.grey.shade300,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: active ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: index == currentStep
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: active
                            ? EColorConstants.primaryColor
                            : Colors.grey.shade600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: index < currentStep
                        ? EColorConstants.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
        ),
      ],
    );
  }
}
