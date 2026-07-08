import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_event.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_state.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/booking_detail_page.dart';
import 'package:prince_academy/features/home/presentation/pages/home/coach_profile.dart';

abstract final class _AppColors {
  static const primary = EColorConstants.primaryColor;
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
  static const activeBlue = Color(0xFF0B5ED7);
  static const completedGreen = Color(0xFF198754);
  static const pendingOrange = Color(0xFFB26A00);
  static const expiredRed = Color(0xFFD32F2F);
}

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingHistoryBloc>()..add(const LoadBookingHistory()),
      child: const _BookingHistoryView(),
    );
  }
}

class _BookingHistoryView extends StatelessWidget {
  const _BookingHistoryView();

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: dark ? Colors.black : const Color(0xFFF7F7F7),
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: const Text('Booking History'),
      ),
      body: BlocBuilder<BookingHistoryBloc, BookingHistoryState>(
        builder: (context, state) {
          if (state is BookingHistoryLoading ||
              state is BookingHistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingHistoryError) {
            return _ErrorState(
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

          if (state.allBookings.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              children: [
                if (state.isRefreshing) ...[
                  const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 8),
                ],
                _FilterCardsRow(
                  totalCount: state.countForFilter(null),
                  activeCount: state.countForFilter('active'),
                  completedCount: state.countForFilter('completed'),
                  pendingCount: state.countForFilter('pending'),
                  expiredCount: state.countForFilter('expired'),
                  selectedFilter: state.activeFilter,
                  onFilterSelected: (filter) {
                    context
                        .read<BookingHistoryBloc>()
                        .add(FilterBookings(filter));
                  },
                ),
                const SizedBox(height: 12),
                if (state.bookings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        'No bookings match this filter',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...state.bookings.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BookingHistoryCard(
                        booking: booking,
                        onDetails: () => _onDetails(context, booking),
                        onEnrollAgain: () => _onEnrollAgain(context, booking),
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

  void _onDetails(BuildContext context, BookingHistoryModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailPage(booking: booking),
      ),
    );
  }

  void _onEnrollAgain(BuildContext context, BookingHistoryModel booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoachProfilePage(coachId: booking.coachId),
      ),
    );
  }
}

class _FilterCardsRow extends StatelessWidget {
  const _FilterCardsRow({
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.pendingCount,
    required this.expiredCount,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final int totalCount;
  final int activeCount;
  final int completedCount;
  final int pendingCount;
  final int expiredCount;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterSelected;

  static const _filters = [
    (null, 'Total'),
    ('active', 'Active'),
    ('completed', 'Complete'),
    ('pending', 'Pending'),
    ('expired', 'Expired'),
  ];

  int _countFor(String? filter) {
    return switch (filter) {
      null => totalCount,
      'active' => activeCount,
      'completed' => completedCount,
      'pending' => pendingCount,
      'expired' => expiredCount,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _AppColors.primary.withOpacity(0.18),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _filters.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              _FilterCard(
                count: _countFor(_filters[i].$1),
                label: _filters[i].$2,
                isSelected: selectedFilter == _filters[i].$1,
                onTap: () => onFilterSelected(_filters[i].$1),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.count,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final int count;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? _AppColors.primary.withOpacity(0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? _AppColors.primary
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Colors.black.withOpacity(0.04),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? _AppColors.primary
                      : _AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingHistoryCard extends StatelessWidget {
  const _BookingHistoryCard({
    required this.booking,
    required this.onDetails,
    required this.onEnrollAgain,
  });

  final BookingHistoryModel booking;
  final VoidCallback onDetails;
  final VoidCallback onEnrollAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = booking.effectiveDisplayStatus;
    final showActions = status != 'pending';

    return GestureDetector(
      onTap: onDetails,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 8),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        child: Column(
        children: [
          Row(
            children: [
              _BookingLeadImage(
                coachName: booking.coachName,
                photoUrl: booking.coachPhoto,
                status: status,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.coachName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: _AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(status: status),
                      ],
                    ),
                    if (booking.branchName != null &&
                        booking.branchName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: _AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking.branchName!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${booking.totalSessions} sessions • ${booking.paymentStatusText}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.calendar_1, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatDateRange(
                    booking.subscriptionStart,
                    booking.subscriptionEnd,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: 14),
            status == 'completed'
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onEnrollAgain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Enroll Again',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Details',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
          ],
        ],
      ),
      ),
    );
  }
}

class _BookingLeadImage extends StatelessWidget {
  const _BookingLeadImage({
    required this.coachName,
    required this.photoUrl,
    required this.status,
  });

  final String coachName;
  final String? photoUrl;
  final String status;

  @override
  Widget build(BuildContext context) {
    final statusUI = _BookingStatusUI.from(status);

    if (photoUrl == null || photoUrl!.trim().isEmpty) {
      return _StatusIconTile(statusUI: statusUI);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 42,
        height: 42,
        child: CoachAvatar(
          coachName: coachName,
          photoUrl: photoUrl,
          size: 42,
        ),
      ),
    );
  }
}

class _StatusIconTile extends StatelessWidget {
  const _StatusIconTile({required this.statusUI});

  final _BookingStatusUI statusUI;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: statusUI.badgeColor.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(statusUI.icon, color: statusUI.badgeColor, size: 20),
    );
  }
}

class _BookingStatusUI {
  const _BookingStatusUI({
    required this.badgeColor,
    required this.icon,
  });

  final Color badgeColor;
  final IconData icon;

  factory _BookingStatusUI.from(String status) {
    return switch (status.toLowerCase()) {
      'active' => const _BookingStatusUI(
          badgeColor: _AppColors.activeBlue,
          icon: Iconsax.activity,
        ),
      'completed' => const _BookingStatusUI(
          badgeColor: _AppColors.completedGreen,
          icon: Iconsax.tick_circle,
        ),
      'expired' => const _BookingStatusUI(
          badgeColor: _AppColors.expiredRed,
          icon: Iconsax.close_circle,
        ),
      'pending' => const _BookingStatusUI(
          badgeColor: _AppColors.pendingOrange,
          icon: Iconsax.warning_2,
        ),
      _ => const _BookingStatusUI(
          badgeColor: _AppColors.textSecondary,
          icon: Iconsax.info_circle,
        ),
    };
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(status);
    final label = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

Color _badgeColor(String status) {
  return switch (status.toLowerCase()) {
    'active' => _AppColors.activeBlue,
    'completed' => _AppColors.completedGreen,
    'expired' => _AppColors.expiredRed,
    'pending' => _AppColors.pendingOrange,
    _ => _AppColors.textSecondary,
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.ticket,
                color: _AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No bookings yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a coach to get started',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
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
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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

String _statusLabel(String status) {
  if (status.isEmpty) return 'Unknown';
  return status[0].toUpperCase() + status.substring(1).toLowerCase();
}

String _formatDisplayDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  return '${months[local.month - 1]} $day, ${local.year}';
}

String _formatDateRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return 'Dates not set';
  if (start != null && end != null) {
    return '${_formatDisplayDate(start)}  →  ${_formatDisplayDate(end)}';
  }
  if (start != null) return _formatDisplayDate(start);
  return _formatDisplayDate(end!);
}
