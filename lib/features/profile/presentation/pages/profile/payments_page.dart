import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_state.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/booking_detail_page.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingHistoryBloc>()..add(const LoadBookingHistory()),
      child: const _PaymentsView(),
    );
  }
}

class _PaymentsView extends StatelessWidget {
  const _PaymentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Payments'),
      ),
      body: BlocBuilder<BookingHistoryBloc, BookingHistoryState>(
        builder: (context, state) {
          if (state is BookingHistoryLoading || state is BookingHistoryInitial) {
            return const BookingListShimmer();
          }

          if (state is BookingHistoryError) {
            return _PaymentsError(
              message: state.message,
              onRetry: () {
                context.read<BookingHistoryBloc>().add(
                      const LoadBookingHistory(forceRefresh: true),
                    );
              },
            );
          }

          if (state is! BookingHistoryLoaded) {
            return const SizedBox.shrink();
          }

          final payments = List<BookingHistoryModel>.from(state.allBookings)
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime(1970);
              final bDate = b.createdAt ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });

          if (payments.isEmpty) {
            return const _PaymentsEmpty();
          }

          final pendingCount = payments
              .where((b) =>
                  b.effectiveDisplayStatus == 'pending_payment' ||
                  b.effectiveDisplayStatus == 'pending' ||
                  b.bookingStatus == 'pending')
              .length;
          final paidTotal = payments
              .where((b) => b.paymentStatusText == 'Paid')
              .fold<double>(0, (sum, b) => sum + b.totalPrice);

          return RefreshIndicator(
            color: EColorConstants.primaryColor,
            onRefresh: () async {
              context.read<BookingHistoryBloc>().add(
                    const LoadBookingHistory(forceRefresh: true),
                  );
              await context.read<BookingHistoryBloc>().stream.firstWhere(
                    (s) =>
                        s is BookingHistoryLoaded || s is BookingHistoryError,
                  );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (state.isRefreshing) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Paid total',
                        value: '${paidTotal.toStringAsFixed(0)} EGP',
                        icon: Iconsax.wallet_check,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Pending',
                        value: '$pendingCount',
                        icon: Iconsax.timer_1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                ...payments.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentTile(
                      booking: booking,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailPage(booking: booking),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EColorConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: EColorConstants.primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
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

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.booking,
    required this.onTap,
  });

  final BookingHistoryModel booking;
  final VoidCallback onTap;

  Color get _statusColor {
    final status = booking.effectiveDisplayStatus;
    if (status == 'pending_payment' ||
        status == 'pending' ||
        booking.bookingStatus == 'pending') {
      return const Color(0xFFB26A00);
    }
    if (booking.paymentStatusText == 'Paid') {
      return const Color(0xFF198754);
    }
    return Colors.grey.shade700;
  }

  String get _methodLabel {
    final method = booking.paymentMethod?.trim();
    if (method == null || method.isEmpty) return 'Not set';
    if (method.toLowerCase() == 'instapay') return 'InstaPay';
    if (method.toLowerCase() == 'cash') return 'Cash';
    return method;
  }

  @override
  Widget build(BuildContext context) {
    final date = booking.createdAt;
    final dateText = date == null
        ? '—'
        : DateFormat('d MMM yyyy').format(date);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_methodLabel • $dateText',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        booking.paymentStatusText,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${booking.totalPrice.toStringAsFixed(0)} EGP',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentsEmpty extends StatelessWidget {
  const _PaymentsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.wallet_2, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No payments yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking payments will show up here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentsError extends StatelessWidget {
  const _PaymentsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text('Could not load payments'),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
