import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ---- Demo data (replace later with BLoC/Supabase) ----
  final _summary = const _BookingSummary(
    total: 12,
    completed: 5,
    remaining: 7,
    nextSessionLabel: 'Wed, 6:00 PM',
  );

  late final List<_SessionItem> upcoming = [
    _SessionItem(
      coachName: 'Coach Ahmed',
      dateLabel: 'Wed, Feb 26',
      timeLabel: '6:00 PM',
      status: _SessionStatus.scheduled,
      location: 'Prince Academy - Main Gym',
    ),
    _SessionItem(
      coachName: 'Coach Ahmed',
      dateLabel: 'Fri, Feb 28',
      timeLabel: '7:00 PM',
      status: _SessionStatus.scheduled,
      location: 'Prince Academy - Main Gym',
    ),
  ];

  late final List<_SessionItem> history = [
    _SessionItem(
      coachName: 'Coach Ahmed',
      dateLabel: 'Mon, Feb 17',
      timeLabel: '6:00 PM',
      status: _SessionStatus.completed,
      location: 'Prince Academy - Main Gym',
    ),
    _SessionItem(
      coachName: 'Coach Ahmed',
      dateLabel: 'Wed, Feb 19',
      timeLabel: '6:00 PM',
      status: _SessionStatus.completed,
      location: 'Prince Academy - Main Gym',
    ),
    _SessionItem(
      coachName: 'Coach Ahmed',
      dateLabel: 'Fri, Feb 21',
      timeLabel: '7:00 PM',
      status: _SessionStatus.missed,
      location: 'Prince Academy - Main Gym',
    ),
  ];
  // ------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    return Container(
      decoration: dark ? null : AppGradients.screenDecoration(),
      color: dark ? Colors.black : null,
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Sessions'),
        actions: [
          IconButton(
            onPressed: () {
              // Later: open filters or refresh
            },
            icon: const Icon(Iconsax.filter),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryHeader(summary: _summary),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: dark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: EColorConstants.primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: EColorConstants.primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SessionList(
                  items: upcoming,
                  emptyTitle: 'No upcoming sessions',
                  emptySubtitle:
                      'Book a coach and your upcoming sessions will show here.',
                  emptyIcon: Iconsax.calendar_add,
                ),
                _SessionList(
                  items: history,
                  emptyTitle: 'No history yet',
                  emptySubtitle:
                      'After you attend sessions, your history will appear here.',
                  emptyIcon: Iconsax.document_text,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final _BookingSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EColorConstants.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: EColorConstants.primaryColor.withOpacity(0.18),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: EColorConstants.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.activity,
                      color: EColorConstants.primaryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month Progress',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Next session: ${summary.nextSessionLabel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
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
                Expanded(
                  child: _MiniStat(
                    label: 'Total',
                    value: summary.total.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Completed',
                    value: summary.completed.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    label: 'Remaining',
                    value: summary.remaining.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Container(
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
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.items,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
  });

  final List<_SessionItem> items;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: emptyIcon,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _SessionCard(item: items[i]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.item});

  final _SessionItem item;

  @override
  Widget build(BuildContext context) {
    final chip = _StatusChip.from(item.status);

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
      child: Row(
        children: [
          // left icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: chip.bg.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(chip.icon, color: chip.fg, size: 20),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _ChipView(label: chip.label, fg: chip.fg, bg: chip.bg),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Iconsax.calendar_1,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${item.dateLabel} • ${item.timeLabel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Iconsax.location,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (item.status == _SessionStatus.scheduled) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Later: reschedule logic
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('Reschedule'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Later: open details / QR / check-in info
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EColorConstants.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

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
              child: Icon(icon, color: EColorConstants.primaryColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

class _ChipView extends StatelessWidget {
  const _ChipView({required this.label, required this.fg, required this.bg});

  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: bg.withOpacity(0.28)),
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

class _StatusChip {
  final String label;
  final Color fg;
  final Color bg;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.fg,
    required this.bg,
    required this.icon,
  });

  factory _StatusChip.from(_SessionStatus status) {
    switch (status) {
      case _SessionStatus.scheduled:
        return const _StatusChip(
          label: 'Scheduled',
          fg: Color(0xFF0B5ED7),
          bg: Color(0xFF0B5ED7),
          icon: Iconsax.calendar_1,
        );
      case _SessionStatus.completed:
        return const _StatusChip(
          label: 'Completed',
          fg: Color(0xFF198754),
          bg: Color(0xFF198754),
          icon: Iconsax.tick_circle,
        );
      case _SessionStatus.missed:
        return const _StatusChip(
          label: 'Missed',
          fg: Color(0xFFDC3545),
          bg: Color(0xFFDC3545),
          icon: Iconsax.close_circle,
        );
      case _SessionStatus.cancelled:
        return const _StatusChip(
          label: 'Cancelled',
          fg: Color(0xFF6C757D),
          bg: Color(0xFF6C757D),
          icon: Iconsax.minus_cirlce,
        );
    }
  }
}

enum _SessionStatus { scheduled, completed, missed, cancelled }

class _SessionItem {
  final String coachName;
  final String dateLabel;
  final String timeLabel;
  final _SessionStatus status;
  final String location;

  const _SessionItem({
    required this.coachName,
    required this.dateLabel,
    required this.timeLabel,
    required this.status,
    required this.location,
  });
}

class _BookingSummary {
  final int total;
  final int completed;
  final int remaining;
  final String nextSessionLabel;

  const _BookingSummary({
    required this.total,
    required this.completed,
    required this.remaining,
    required this.nextSessionLabel,
  });
}
