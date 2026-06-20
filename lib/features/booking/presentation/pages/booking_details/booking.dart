import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_state.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/booking_success_screen.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/booking_bottom_bar.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/booking_total_card.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/payment_method_selector.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/schedule_selector.dart';
import 'widgets/coach_header_card.dart';

class BookingPage extends StatelessWidget {
  final MMABookingModel bookingInfo;

  const BookingPage({super.key, required this.bookingInfo});

  @override
  Widget build(BuildContext context) {
    final coachId = bookingInfo.coachId;
    if (coachId == null || coachId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Coach not found')),
      );
    }

    return BlocProvider(
      create: (_) => sl<BookingBloc>()
        ..add(
          LoadBookingData(
            coachId: coachId,
            coachName: bookingInfo.coachName,
            coachImage: bookingInfo.coachImage,
          ),
        ),
      child: _BookingView(bookingInfo: bookingInfo),
    );
  }
}

class _BookingView extends StatelessWidget {
  final MMABookingModel bookingInfo;

  const _BookingView({required this.bookingInfo});

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    return BlocConsumer<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BookingSuccessScreen(
                coachName: bookingInfo.coachName,
                totalPrice: state.booking.totalPrice,
                qrCode: state.qrCode,
              ),
            ),
          );
        } else if (state is BookingSubmitFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (state is BookingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }

        final loaded = switch (state) {
          BookingLoaded s => s,
          BookingSubmitting s => s.data,
          BookingSubmitFailed s => s.data,
          _ => null,
        };

        if (loaded != null && loaded.showMinSessionsWarning) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Minimum 2 sessions required'),
              duration: Duration(seconds: 2),
            ),
          );
          context.read<BookingBloc>().add(const ClearMinSessionsWarning());
        }
      },
      builder: (context, state) {
        if (state is BookingLoading || state is BookingInitial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: EColorConstants.primaryColor,
              ),
            ),
          );
        }

        if (state is BookingError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final loaded = switch (state) {
          BookingLoaded s => s,
          BookingSubmitting s => s.data,
          BookingSubmitFailed s => s.data,
          _ => null,
        };

        if (loaded == null) {
          return const Scaffold(
            body: Center(child: Text('Unable to load booking data')),
          );
        }

        final isSubmitting = state is BookingSubmitting;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Booking'),
            actions: [
              IconButton(
                icon: const Icon(Iconsax.message),
                onPressed: () {},
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              CoachHeaderCard(info: bookingInfo),
              const SizedBox(height: 16),
              ScheduleSelector(
                availableDays: loaded.session.days,
                selectedDays: loaded.selectedDays,
                fixedTime: loaded.fixedTime,
                isLocked: loaded.isLocked,
                onToggleDay: (day) {
                  context.read<BookingBloc>().add(ToggleDay(day));
                },
              ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'Payment Method',
                subtitle: 'Choose your preferred payment',
                icon: Iconsax.wallet,
              ),
              const SizedBox(height: 10),
              PaymentMethodSelector(
                selected: loaded.paymentMethod ?? PaymentMethod.cash,
                onChanged: (method) {
                  context
                      .read<BookingBloc>()
                      .add(SelectPaymentMethod(method));
                },
              ),
              const SizedBox(height: 18),
              SectionTitle(
                title: 'Summary',
                subtitle: 'Review before continuing',
                icon: Iconsax.document_text,
              ),
              const SizedBox(height: 10),
              BookingTotalCard(
                coachName: loaded.coachName,
                selectedDays: loaded.selectedDays,
                fixedTime: loaded.fixedTime,
                pricePerSession: loaded.session.pricePerSession,
                total: loaded.totalPrice,
              ),
            ],
          ),
          bottomNavigationBar: BookingBottomBar(
            enabled: loaded.canContinue,
            isLoading: isSubmitting,
            total: loaded.totalPrice,
            buttonText: 'Continue',
            onPressed: loaded.canContinue
                ? () => context.read<BookingBloc>().add(const SubmitBooking())
                : null,
          ),
          backgroundColor: dark ? Colors.black : const Color(0xFFF7F7F7),
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: EColorConstants.primaryColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: EColorConstants.primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
