import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/schedule_selector.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/booking_bottom_bar.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/booking_total_card.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/widgets/payment_method_selector.dart';
import 'widgets/coach_header_card.dart';
import 'widgets/package_selector.dart';


class BookingPage extends StatefulWidget {
  final MMABookingModel bookingInfo;

  const BookingPage({super.key, required this.bookingInfo});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int? selectedSessions; // 8 or 12 later (now accepts from model)
  final Set<String> selectedDays = {};
  String? selectedTime;
  PaymentMethod selectedPaymentMethod = PaymentMethod.card;

  double get totalPrice {
    final sessions = selectedSessions ?? 0;
    return sessions * widget.bookingInfo.pricePerSession;
  }

  bool get canContinue {
    return selectedSessions != null &&
        selectedDays.isNotEmpty &&
        selectedTime != null;
  }

  void onConfirm() {
    // UI only for now
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Booking Ready'),
        content: Text(
          'Coach: ${widget.bookingInfo.coachName}\n'
          'Sessions: $selectedSessions\n'
          'Days: ${selectedDays.join(", ")}\n'
          'Time: $selectedTime\n'
          'Payment: ${selectedPaymentMethod.label}\n\n'
          'Next step: connect payment + create enrollment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.message),
            onPressed: () {
              // Keep WhatsApp later (or open chat)
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          CoachHeaderCard(info: widget.bookingInfo),

          const SizedBox(height: 16),

          SectionTitle(
            title: '1) Choose Package',
            subtitle: 'Private sessions per month',
            icon: Iconsax.ticket,
          ),
          const SizedBox(height: 10),
          PackageSelector(
            options: widget.bookingInfo.sessionPackages,
            selected: selectedSessions,
            pricePerSession: widget.bookingInfo.pricePerSession,
            onChanged: (v) => setState(() => selectedSessions = v),
          ),

          const SizedBox(height: 18),

          SectionTitle(
            title: '2) Pick Schedule',
            subtitle: 'Choose days and preferred time',
            icon: Iconsax.calendar,
          ),
          const SizedBox(height: 10),
          ScheduleSelector(
            availableDays: widget.bookingInfo.availableDays,
            availableTimes: widget.bookingInfo.availableTimes,
            selectedDays: selectedDays,
            selectedTime: selectedTime,
            onToggleDay: (day) {
              setState(() {
                if (selectedDays.contains(day)) {
                  selectedDays.remove(day);
                } else {
                  selectedDays.add(day);
                }
              });
            },
            onSelectTime: (time) => setState(() => selectedTime = time),
          ),

          const SizedBox(height: 18),

          SectionTitle(
            title: '3) Payment Method',
            subtitle: 'Choose your preferred payment',
            icon: Iconsax.wallet,
          ),
          const SizedBox(height: 10),
          PaymentMethodSelector(
            selected: selectedPaymentMethod,
            onChanged: (m) => setState(() => selectedPaymentMethod = m),
          ),

          const SizedBox(height: 18),

          SectionTitle(
            title: 'Summary',
            subtitle: 'Review before continuing',
            icon: Iconsax.document_text,
          ),
          const SizedBox(height: 10),
          BookingTotalCard(
            coachName: widget.bookingInfo.coachName,
            sessions: selectedSessions,
            days: selectedDays,
            time: selectedTime,
            pricePerSession: widget.bookingInfo.pricePerSession,
            total: totalPrice,
          ),
        ],
      ),
      bottomNavigationBar: BookingBottomBar(
        enabled: canContinue,
        total: totalPrice,
        buttonText: 'Continue',
        onPressed: canContinue ? onConfirm : null,
      ),
      backgroundColor: dark ? Colors.black : const Color(0xFFF7F7F7),
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
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
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