import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_event.dart';

class SessionsTabBar extends StatelessWidget {
  final SessionTab activeTab;
  final void Function(SessionTab) onSwitch;

  const SessionsTabBar({
    super.key,
    required this.activeTab,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          final indicatorLeft =
              activeTab == SessionTab.upcoming ? 0.0 : tabWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  _TabItem(
                    label: 'Upcoming',
                    isActive: activeTab == SessionTab.upcoming,
                    onTap: () => onSwitch(SessionTab.upcoming),
                  ),
                  _TabItem(
                    label: 'History',
                    isActive: activeTab == SessionTab.history,
                    onTap: () => onSwitch(SessionTab.history),
                  ),
                ],
              ),
              Positioned(
                left: indicatorLeft,
                bottom: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: tabWidth,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 15,
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionsTabBarHeader extends SliverPersistentHeaderDelegate {
  final SessionTab activeTab;
  final void Function(SessionTab) onSwitch;

  SessionsTabBarHeader({
    required this.activeTab,
    required this.onSwitch,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SessionsTabBar(activeTab: activeTab, onSwitch: onSwitch);
  }

  @override
  bool shouldRebuild(covariant SessionsTabBarHeader oldDelegate) {
    return oldDelegate.activeTab != activeTab;
  }
}
