import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_detail_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_detail_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_detail_state.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_event.dart';

class BookingDetailPage extends StatefulWidget {
  final BookingHistoryModel booking;

  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late final BookingDetailBloc _detailBloc;
  late List<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.booking.selectedDays);
    _detailBloc = sl<BookingDetailBloc>();
  }

  Color _badgeColor(String status) {
    return switch (status.toLowerCase()) {
      'active' => const Color(0xFF0B5ED7),
      'completed' => const Color(0xFF198754),
      'expired' => const Color(0xFFD32F2F),
      'pending' || 'pending_payment' => const Color(0xFFB26A00),
      _ => const Color(0xFF757575),
    };
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    if (status == 'pending_payment') return 'Pending Payment';
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel your booking with ${widget.booking.coachName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _detailBloc.add(DeleteBooking(widget.booking.bookingId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSessionPicker() {
    final allDays = widget.booking.selectedDays;
    final uniqueDays = allDays.toSet().toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selected = List<String>.from(_selectedDays);
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Training Days',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select the days you want to train per week',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...uniqueDays.map(
                    (day) => CheckboxListTile(
                      title: Text(_capitalize(day)),
                      value: selected.contains(day),
                      activeColor: EColorConstants.primaryColor,
                      onChanged: (checked) {
                        setSheetState(() {
                          if (checked == true) {
                            selected.add(day);
                          } else {
                            selected.remove(day);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedDays = selected;
                              });
                              _detailBloc.add(
                                UpdateBookingDays(
                                  bookingId: widget.booking.bookingId,
                                  days: selected,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EColorConstants.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReschedulePicker() {
    final now = DateTime.now();
    showDatePicker(
      context: context,
      initialDate: widget.booking.subscriptionStart ?? now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'Select new start date',
    ).then((picked) {
      if (picked != null) {
        _detailBloc.add(
          RescheduleBooking(
            bookingId: widget.booking.bookingId,
            startDate: picked,
          ),
        );
      }
    });
  }

  void _refreshHistory() {
    context.read<BookingHistoryBloc>().add(
          const LoadBookingHistory(forceRefresh: true),
        );
  }

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    final theme = Theme.of(context);
    final booking = widget.booking;
    final status = booking.effectiveDisplayStatus;

    return BlocProvider.value(
      value: _detailBloc,
      child: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          if (didPop) _refreshHistory();
        },
        child: Scaffold(
          backgroundColor: dark ? Colors.black : const Color(0xFFF7F7F7),
          appBar: AppBar(
            title: const Text('Booking Details'),
          ),
          body: BlocConsumer<BookingDetailBloc, BookingDetailState>(
            listener: (context, state) {
              if (state is BookingDetailSuccess) {
                _refreshHistory();
                Navigator.pop(context);
              }
              if (state is BookingDetailError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is BookingDetailLoading;

              return Column(
                children: [
                  if (isLoading)
                    const LinearProgressIndicator(minHeight: 3),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      child: Column(
                        children: [
                          _CoachHeaderCard(
                            booking: booking,
                            status: status,
                            dark: dark,
                            theme: theme,
                            badgeColor: _badgeColor(status),
                            statusLabel: _statusLabel(status),
                          ),
                          const SizedBox(height: 12),
                          _InfoSection(
                            dark: dark,
                            children: [
                              _InfoRow(
                                icon: Iconsax.calendar_1,
                                label: 'Schedule',
                                value: SubscriptionFormatters.formatDays(
                                  _selectedDays,
                                ),
                              ),
                              if (booking.selectedTime != null &&
                                  booking.selectedTime!.isNotEmpty)
                                _InfoRow(
                                  icon: Iconsax.clock,
                                  label: 'Time',
                                  value: booking.selectedTime!,
                                ),
                              _InfoRow(
                                icon: Iconsax.calendar,
                                label: 'Start',
                                value: SubscriptionFormatters.formatDate(
                                  booking.subscriptionStart,
                                ),
                              ),
                              _InfoRow(
                                icon: Iconsax.calendar_tick,
                                label: 'End',
                                value: SubscriptionFormatters.formatDate(
                                  booking.subscriptionEnd,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoSection(
                            dark: dark,
                            children: [
                              _InfoRow(
                                icon: Iconsax.money,
                                label: 'Total',
                                value: 'EGP ${booking.totalPrice.toStringAsFixed(0)}',
                              ),
                              _InfoRow(
                                icon: Iconsax.wallet,
                                label: 'Payment',
                                value: booking.paymentStatusText,
                              ),
                              _InfoRow(
                                icon: Iconsax.note,
                                label: 'Method',
                                value: booking.paymentMethod != null
                                    ? _capitalize(booking.paymentMethod!)
                                    : '—',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoSection(
                            dark: dark,
                            children: [
                              _InfoRow(
                                icon: Iconsax.tick_circle,
                                label: 'Status',
                                value: _statusLabel(status),
                              ),
                              _InfoRow(
                                icon: Iconsax.calendar_edit,
                                label: 'Sessions',
                                value:
                                    '${_selectedDays.length} per week • ${booking.totalSessions} total',
                              ),
                            ],
                          ),
                          if (status != 'completed' &&
                              status != 'expired') ...[
                            const SizedBox(height: 20),
                            _ActionButtons(
                              isLoading: isLoading,
                              onEditSessions: _showSessionPicker,
                              onReschedule: _showReschedulePicker,
                              onDelete: _showDeleteConfirmation,
                              theme: theme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CoachHeaderCard extends StatelessWidget {
  const _CoachHeaderCard({
    required this.booking,
    required this.status,
    required this.dark,
    required this.theme,
    required this.badgeColor,
    required this.statusLabel,
  });

  final BookingHistoryModel booking;
  final String status;
  final bool dark;
  final ThemeData theme;
  final Color badgeColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CoachAvatar(
                coachName: booking.coachName,
                photoUrl: booking.coachPhoto,
                size: 80,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            booking.coachName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (booking.coachSpecialty != null &&
              booking.coachSpecialty!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              booking.coachSpecialty!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
          if (booking.branchName != null &&
              booking.branchName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: EColorConstants.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  booking.branchName!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EColorConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: badgeColor.withOpacity(0.22)),
            ),
            child: Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final bool dark;
  final List<Widget> children;

  const _InfoSection({required this.dark, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: EColorConstants.primaryColor),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onEditSessions;
  final VoidCallback onReschedule;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _ActionButtons({
    required this.isLoading,
    required this.onEditSessions,
    required this.onReschedule,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: disabled ? null : onEditSessions,
              icon: const Icon(Iconsax.edit_2, size: 18),
              label: const Text(
                'Edit Training Days',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: disabled ? null : onReschedule,
              icon: const Icon(Iconsax.calendar_edit, size: 18),
              label: const Text(
                'Reschedule',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: EColorConstants.primaryColor,
                side: const BorderSide(color: EColorConstants.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: disabled ? null : onDelete,
              icon: const Icon(Iconsax.trash, size: 18),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
