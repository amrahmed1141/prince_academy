import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/core/helpers/subscription_pricing.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
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
  late BookingHistoryModel _displayBooking;
  late List<String> _selectedDays;
  late List<String> _availableDays;
  double _fullMonthlyPrice = 0;
  int _planSessions = 3;
  _PendingAction _pendingAction = _PendingAction.none;
  bool _skipPopRefresh = false;

  @override
  void initState() {
    super.initState();
    _displayBooking = widget.booking;
    _selectedDays = List.from(widget.booking.selectedDays);
    _availableDays = List.from(widget.booking.selectedDays);
    _planSessions = widget.booking.selectedDays.length == 2 ? 2 : 3;
    _fullMonthlyPrice = _deriveFullMonthlyPrice(widget.booking);
    _detailBloc = sl<BookingDetailBloc>();
    _loadCoachSession();
  }

  Future<void> _loadCoachSession() async {
    try {
      final session =
          await sl<BookingRepository>().getActiveSession(widget.booking.coachId);
      if (!mounted || session == null) return;

      setState(() {
        if (session.days.isNotEmpty) {
          _availableDays = List<String>.from(session.days);
        }
        if (session.pricePerSession > 0) {
          _fullMonthlyPrice = session.pricePerSession;
        }
      });
    } catch (_) {
      // Keep booking-derived fallback values.
    }
  }

  double _deriveFullMonthlyPrice(BookingHistoryModel booking) {
    final count = booking.selectedDays.length;
    final price = booking.totalPrice;
    if (count == 2) return price / 0.8;
    if (count >= 3) return price;
    return price;
  }

  double _priceForSessionsPerWeek(int sessionsPerWeek) {
    return SubscriptionPricing.monthlyPrice(_fullMonthlyPrice, sessionsPerWeek);
  }

  int _totalSessionsForWeek(int sessionsPerWeek) {
    return SubscriptionPricing.monthlySessionCount(sessionsPerWeek);
  }

  void _applySelectionPreview(List<String> days) {
    final planSessions = days.length >= 3 ? 3 : 2;
    setState(() {
      _selectedDays = List<String>.from(days);
      _planSessions = planSessions;
      _displayBooking = _displayBooking.copyWith(
        selectedDays: days,
        totalPrice: _priceForSessionsPerWeek(planSessions),
        totalSessions: _totalSessionsForWeek(planSessions),
      );
    });
  }

  @override
  void dispose() {
    _detailBloc.close();
    super.dispose();
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
              _pendingAction = _PendingAction.delete;
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
    final previousDays = List<String>.from(_selectedDays);
    final previousBooking = _displayBooking;
    final previousPlanSessions = _planSessions;
    var didSave = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _TrainingDaysSheet(
          availableDays: _availableDays,
          initialSelectedDays: _selectedDays,
          fullMonthlyPrice: _fullMonthlyPrice,
          onPreviewChanged: _applySelectionPreview,
          onSave: (days) {
            didSave = true;
            Navigator.pop(ctx);
            _pendingAction = _PendingAction.updateDays;
            _detailBloc.add(
              UpdateBookingDays(
                bookingId: widget.booking.bookingId,
                days: days,
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (!didSave && mounted) {
        setState(() {
          _selectedDays = previousDays;
          _displayBooking = previousBooking;
          _planSessions = previousPlanSessions;
        });
      }
    });
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
        _pendingAction = _PendingAction.reschedule;
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
    try {
      context.read<BookingHistoryBloc>().add(
            const LoadBookingHistory(forceRefresh: true),
          );
    } catch (_) {
      // History bloc is not available in this route tree.
    }
  }

  void _handleSuccess(BookingDetailSuccess state) {
    switch (_pendingAction) {
      case _PendingAction.delete:
        _refreshHistory();
        _skipPopRefresh = true;
        Navigator.pop(context);
      case _PendingAction.updateDays:
        _refreshHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _detailBloc.add(const ResetBookingDetail());
      case _PendingAction.reschedule:
        _refreshHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _detailBloc.add(const ResetBookingDetail());
      case _PendingAction.none:
        break;
    }
    _pendingAction = _PendingAction.none;
  }

  void _onPopInvoked(bool didPop) {
    if (didPop && !_skipPopRefresh) {
      _refreshHistory();
    }
    _skipPopRefresh = false;
  }

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    final theme = Theme.of(context);
    final booking = _displayBooking;
    final status = booking.effectiveDisplayStatus;
    final liveTotal = _priceForSessionsPerWeek(_planSessions);
    final liveTotalSessions = _totalSessionsForWeek(_planSessions);

    return BlocProvider.value(
      value: _detailBloc,
      child: PopScope(
        canPop: true,
        onPopInvoked: _onPopInvoked,
        child: Scaffold(
          backgroundColor: dark ? Colors.black : const Color(0xFFF7F7F7),
          appBar: AppBar(
            title: const Text('Booking Details'),
          ),
          body: BlocConsumer<BookingDetailBloc, BookingDetailState>(
            listenWhen: (previous, current) =>
                current is BookingDetailSuccess ||
                current is BookingDetailError,
            listener: (context, state) {
              if (state is BookingDetailSuccess) {
                _handleSuccess(state);
              }
              if (state is BookingDetailError) {
                _pendingAction = _PendingAction.none;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
                _detailBloc.add(const ResetBookingDetail());
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
                                value: 'EGP ${liveTotal.toStringAsFixed(0)}',
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
                                    '$_planSessions per week • $liveTotalSessions total',
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

enum _PendingAction { none, delete, updateDays, reschedule }

class _TrainingDaysSheet extends StatefulWidget {
  const _TrainingDaysSheet({
    required this.availableDays,
    required this.initialSelectedDays,
    required this.fullMonthlyPrice,
    required this.onPreviewChanged,
    required this.onSave,
  });

  final List<String> availableDays;
  final List<String> initialSelectedDays;
  final double fullMonthlyPrice;
  final ValueChanged<List<String>> onPreviewChanged;
  final ValueChanged<List<String>> onSave;

  @override
  State<_TrainingDaysSheet> createState() => _TrainingDaysSheetState();
}

class _TrainingDaysSheetState extends State<_TrainingDaysSheet> {
  late List<String> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = List<String>.from(widget.initialSelectedDays);
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else if (_selectedDays.length < 3) {
        _selectedDays.add(day);
      }
    });
    widget.onPreviewChanged(_selectedDays);
  }

  double _priceFor(int sessionsPerWeek) {
    return SubscriptionPricing.monthlyPrice(
      widget.fullMonthlyPrice,
      sessionsPerWeek,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedDays.length;
    final canSave = selectedCount == 2 || selectedCount == 3;
    final livePrice = _priceFor(selectedCount >= 3 ? 3 : 2);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        32 + MediaQuery.viewInsetsOf(context).bottom,
      ),
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
            'Pick your training days (2 or 3 per week)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Selected: $selectedCount / 3',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: canSave
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            canSave
                ? 'Total: EGP ${livePrice.toStringAsFixed(0)}'
                : 'Select at least 2 days',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: canSave
                      ? EColorConstants.primaryColor
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.availableDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              final canSelect = isSelected || _selectedDays.length < 3;
              return FilterChip(
                label: Text(_capitalizeDay(day)),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: EColorConstants.primaryColor.withOpacity(0.15),
                checkmarkColor: EColorConstants.primaryColor,
                onSelected: canSelect ? (_) => _toggleDay(day) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSave
                  ? () => widget.onSave(List<String>.from(_selectedDays))
                  : null,
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
  }

  String _capitalizeDay(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
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
