import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Demo data (replace with repo/BLoC later)
  final List<_EnrollmentItem> enrollments = [
    _EnrollmentItem(
      id: 'enr_001',
      coachName: 'Coach Ahmed',
      packageSessions: 12,
      usedSessions: 5,
      startDateLabel: 'Feb 01, 2026',
      endDateLabel: 'Feb 29, 2026',
      status: _EnrollmentStatus.active,
      paidLabel: 'Paid',
    ),
    _EnrollmentItem(
      id: 'enr_000',
      coachName: 'Coach Ahmed',
      packageSessions: 8,
      usedSessions: 8,
      startDateLabel: 'Jan 01, 2026',
      endDateLabel: 'Jan 31, 2026',
      status: _EnrollmentStatus.completed,
      paidLabel: 'Paid',
    ),
    _EnrollmentItem(
      id: 'enr_002',
      coachName: 'Coach Omar',
      packageSessions: 12,
      usedSessions: 0,
      startDateLabel: 'Mar 01, 2026',
      endDateLabel: 'Mar 31, 2026',
      status: _EnrollmentStatus.pendingPayment,
      paidLabel: 'Payment pending',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    final activeCount =
        enrollments.where((e) => e.status == _EnrollmentStatus.active).length;
    final completedCount =
        enrollments.where((e) => e.status == _EnrollmentStatus.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        actions: [
          IconButton(
            onPressed: () {
              // later: filters (month/coach/status)
            },
            icon: const Icon(Iconsax.filter),
          ),
        ],
      ),
      backgroundColor: dark ? Colors.black : const Color(0xFFF7F7F7),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          _EnrollmentStatsHeader(
            total: enrollments.length,
            active: activeCount,
            completed: completedCount,
          ),
          const SizedBox(height: 12),

          if (enrollments.isEmpty)
            const _EmptyEnrollments()
          else
            ...enrollments.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EnrollmentCard(
                    item: e,
                    onViewSessions: () {
                      // Navigate to "Sessions of this enrollment"
                      // Example:
                      // Navigator.push(context, MaterialPageRoute(
                      //  builder: (_) => EnrollmentSessionsPage(enrollmentId: e.id),
                      // ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open sessions for ${e.id}')),
                      );
                    },
                    onEnrollAgain: e.status == _EnrollmentStatus.completed
                        ? () {
                            // Later: start new booking with same coach
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Enroll again with ${e.coachName}')),
                            );
                          }
                        : null,
                    onPayNow: e.status == _EnrollmentStatus.pendingPayment
                        ? () {
                            // Later: open payment page for that enrollment
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Go to payment for ${e.id}')),
                            );
                          }
                        : null,
                  ),
                )),
        ],
      ),
    );
  }
}

class _EnrollmentStatsHeader extends StatelessWidget {
  const _EnrollmentStatsHeader({
    required this.total,
    required this.active,
    required this.completed,
  });

  final int total;
  final int active;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EColorConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EColorConstants.primaryColor.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          _MiniStat(label: 'Total', value: total.toString()),
          const SizedBox(width: 10),
          _MiniStat(label: 'Active', value: active.toString()),
          const SizedBox(width: 10),
          _MiniStat(label: 'Completed', value: completed.toString()),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({
    required this.item,
    required this.onViewSessions,
    this.onEnrollAgain,
    this.onPayNow,
  });

  final _EnrollmentItem item;
  final VoidCallback onViewSessions;
  final VoidCallback? onEnrollAgain;
  final VoidCallback? onPayNow;

  @override
  Widget build(BuildContext context) {
    final statusUI = _EnrollmentStatusUI.from(item.status);

    final used = item.usedSessions.clamp(0, item.packageSessions);
    final total = item.packageSessions;
    final progress = total == 0 ? 0.0 : used / total;

    return Container(
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
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusUI.bg.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusUI.icon, color: statusUI.fg, size: 20),
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
                            item.coachName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusChip(label: statusUI.label, fg: statusUI.fg, bg: statusUI.bg),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.packageSessions} sessions • ${item.paidLabel}',
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

          const SizedBox(height: 12),

          // Dates row
          Row(
            children: [
              Icon(Iconsax.calendar_1, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.startDateLabel}  →  ${item.endDateLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '$used / $total',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: statusUI.fg,
            ),
          ),

          const SizedBox(height: 14),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewSessions,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View Sessions'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onPayNow ?? onEnrollAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColorConstants.primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    onPayNow != null
                        ? 'Pay Now'
                        : (onEnrollAgain != null ? 'Enroll Again' : 'Details'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: bg.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _EmptyEnrollments extends StatelessWidget {
  const _EmptyEnrollments();

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
                color: EColorConstants.primaryColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.ticket, color: EColorConstants.primaryColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'No enrollments yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once you book a package with a coach, it will appear here.',
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

enum _EnrollmentStatus { pendingPayment, active, completed, cancelled }

class _EnrollmentItem {
  final String id;
  final String coachName;
  final int packageSessions;
  final int usedSessions;
  final String startDateLabel;
  final String endDateLabel;
  final _EnrollmentStatus status;
  final String paidLabel;

  const _EnrollmentItem({
    required this.id,
    required this.coachName,
    required this.packageSessions,
    required this.usedSessions,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.status,
    required this.paidLabel,
  });
}

class _EnrollmentStatusUI {
  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;

  const _EnrollmentStatusUI({
    required this.label,
    required this.fg,
    required this.bg,
    required this.icon,
  });

  factory _EnrollmentStatusUI.from(_EnrollmentStatus s) {
    switch (s) {
      case _EnrollmentStatus.pendingPayment:
        return const _EnrollmentStatusUI(
          label: 'Pending',
          fg: Color(0xFFB26A00),
          bg: Color(0xFFB26A00),
          icon: Iconsax.warning_2,
        );
      case _EnrollmentStatus.active:
        return const _EnrollmentStatusUI(
          label: 'Active',
          fg: Color(0xFF0B5ED7),
          bg: Color(0xFF0B5ED7),
          icon: Iconsax.activity,
        );
      case _EnrollmentStatus.completed:
        return const _EnrollmentStatusUI(
          label: 'Completed',
          fg: Color(0xFF198754),
          bg: Color(0xFF198754),
          icon: Iconsax.tick_circle,
        );
      case _EnrollmentStatus.cancelled:
        return const _EnrollmentStatusUI(
          label: 'Cancelled',
          fg: Color(0xFF6C757D),
          bg: Color(0xFF6C757D),
          icon: Iconsax.close_circle,
        );
    }
  }
}