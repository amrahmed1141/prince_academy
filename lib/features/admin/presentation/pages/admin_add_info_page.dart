import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/features/admin/data/models/coach_model.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_home/admin_home_state.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_create_coach_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_create_session_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/all_schedules_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_coach_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_session_page.dart';
import 'package:prince_academy/features/admin/presentation/pages/tracking/all_coaches_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/create_choice_chips.dart';
import 'package:prince_academy/features/admin/presentation/widgets/specialty_chip.dart';

/// Create hub (formerly Add Info). Starts a create flow and lists every
/// coach and session group for quick edit. Full management also lives on
/// Tracking and All Schedules.
class AdminAddInfoPage extends StatelessWidget {
  const AdminAddInfoPage({
    super.key,
    this.showAsStandalone = false,
    this.initialTabIndex = 0,
  });

  /// When true, shows a back button (pushed from dashboard).
  final bool showAsStandalone;

  /// Kept for call-site compatibility. 1 opens the session form.
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return _AdminCreateHubView(
      showAsStandalone: showAsStandalone,
      openSessionOnLoad: initialTabIndex == 1,
    );
  }
}

class _AdminCreateHubView extends StatefulWidget {
  const _AdminCreateHubView({
    required this.showAsStandalone,
    required this.openSessionOnLoad,
  });

  final bool showAsStandalone;
  final bool openSessionOnLoad;

  @override
  State<_AdminCreateHubView> createState() => _AdminCreateHubViewState();
}

class _AdminCreateHubViewState extends State<_AdminCreateHubView> {
  bool _didOpenInitialForm = false;

  @override
  void initState() {
    super.initState();
    if (widget.openSessionOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didOpenInitialForm) return;
        _didOpenInitialForm = true;
        AdminCreateSessionPage.open(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CreateHubHeader(showBack: widget.showAsStandalone),
          Expanded(
            child: BlocBuilder<AdminHomeBloc, AdminHomeState>(
              builder: (context, admin) {
                return ScrollConfiguration(
                  behavior: const AdminSmoothScrollBehavior(),
                  child: AdminSmoothScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      widget.showAsStandalone ? 24 : 120,
                    ),
                    child: _CreateHubBody(admin: admin),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (!widget.showAsStandalone) return page;

    return AppGradients.lightBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: page,
    ));
  }
}

class _CreateHubHeader extends StatelessWidget {
  const _CreateHubHeader({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(showBack ? 8 : 20, 4, 20, 8),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Iconsax.arrow_left,
                color: EColorConstants.authTextDarkBrown,
              ),
            ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create',
                  style: TextStyle(
                    color: EColorConstants.authTextDarkBrown,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Add a coach or schedule a class',
                  style: TextStyle(
                    color: EColorConstants.authPlaceholderGray,
                    fontSize: 13,
                    fontFamily: 'Poppins',
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

class _CreateHubBody extends StatelessWidget {
  const _CreateHubBody({required this.admin});

  final AdminHomeState admin;

  @override
  Widget build(BuildContext context) {
    final coaches = admin.coaches;
    final sessionGroups = CoachWithSessions.group(admin.sessions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _HubActionCard(
                icon: Iconsax.user_add,
                title: 'Coach',
                subtitle: 'Add a profile',
                onTap: () => AdminCreateCoachPage.open(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HubActionCard(
                icon: Iconsax.calendar_add,
                title: 'Session',
                subtitle: 'Schedule a class',
                onTap: () => AdminCreateSessionPage.open(context),
              ),
            ),
          ],
        ),
        if (coaches.isNotEmpty || sessionGroups.isNotEmpty) ...[
          const SizedBox(height: 28),
          if (coaches.isNotEmpty) ...[
            _RecentSectionHeader(
              label: 'Coaches',
              onViewAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllCoachesPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            ...coaches.map(
              (coach) => _RecentCoachRow(
                coach: coach,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditCoachPage(coach: coach)),
                ),
              ),
            ),
          ],
          if (sessionGroups.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RecentSectionHeader(
              label: 'Sessions',
              onViewAll: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllSchedulesPage()),
                );
              },
            ),
            const SizedBox(height: 10),
            ...sessionGroups.map((group) {
              final session = group.schedules.first;
              return _RecentSessionRow(
                group: group,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditSessionPage(session: session),
                  ),
                ),
              );
            }),
          ],
        ],
      ],
    );
  }
}

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 136),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3EDE4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: EColorConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: EColorConstants.authTextDarkBrown,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: EColorConstants.authPlaceholderGray,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSectionHeader extends StatelessWidget {
  const _RecentSectionHeader({
    required this.label,
    required this.onViewAll,
  });

  final String label;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: EColorConstants.authTextDarkBrown,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'View all',
              style: TextStyle(
                color: EColorConstants.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentCoachRow extends StatelessWidget {
  const _RecentCoachRow({
    required this.coach,
    required this.onTap,
  });

  final CoachModel coach;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                CoachAvatar(
                  coachName: coach.name,
                  photoUrl: coach.photoUrl,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coach.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        SpecialtyChip.displayLabel(coach.specialty),
                        style: const TextStyle(
                          fontSize: 12,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: EColorConstants.authPlaceholderGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentSessionRow extends StatelessWidget {
  const _RecentSessionRow({
    required this.group,
    required this.onTap,
  });

  final CoachWithSessions group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = group.schedules.first;
    final dayLabels = group.schedules
        .expand((item) => item.days)
        .map((day) => WeekDayChipRow.shortLabels[day] ?? day)
        .toSet()
        .take(4)
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                CoachAvatar(
                  coachName: group.name,
                  photoUrl: group.photoUrl,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: EColorConstants.authTextDarkBrown,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (dayLabels.isNotEmpty) dayLabels,
                          if (session.timeSlots.isNotEmpty)
                            session.timeSlots.first,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: EColorConstants.primaryColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  size: 18,
                  color: EColorConstants.authPlaceholderGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
