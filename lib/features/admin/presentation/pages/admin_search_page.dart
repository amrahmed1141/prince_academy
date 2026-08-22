import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/l10n/app_strings.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_search_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_search/admin_search_cubit.dart';
import 'package:prince_academy/features/admin/presentation/helpers/admin_search_navigation.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

/// Opens admin global search. List pages keep local [AppSearchBar] filters.
Future<void> openAdminSearch(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => Theme(
        data: EAppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: const Color(0xFFFFF9F5),
        ),
        child: BlocProvider(
          create: (_) => sl<AdminSearchCubit>(),
          child: const AdminSearchPage(),
        ),
      ),
    ),
  );
}

class AdminSearchPage extends StatefulWidget {
  const AdminSearchPage({super.key});

  @override
  State<AdminSearchPage> createState() => _AdminSearchPageState();
}

class _AdminSearchPageState extends State<AdminSearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: EAppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: const Color(0xFFFFF9F5),
        colorScheme: EAppTheme.lightTheme.colorScheme.copyWith(
          surface: const Color(0xFFFFF9F5),
        ),
      ),
      child: Material(
        color: const Color(0xFFFFF9F5),
        child: Container(
          decoration: AppGradients.homeScreenDecoration(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  AppSearchBar(
                    controller: _controller,
                    autofocus: true,
                    showBack: true,
                    alwaysShowClear: true,
                    hintText: context.s.search,
                    hintPhrases: AdminSearchHints.pages(context),
                    onBack: () => Navigator.of(context).maybePop(),
                    onChanged: context.read<AdminSearchCubit>().search,
                    onClear: () {
                      _controller.clear();
                      context.read<AdminSearchCubit>().clear();
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: BlocBuilder<AdminSearchCubit, AdminSearchState>(
                      buildWhen: (prev, next) =>
                          prev.status != next.status ||
                          prev.results != next.results ||
                          prev.query != next.query,
                      builder: (context, state) {
                        final s = context.s;
                        return switch (state.status) {
                          AdminSearchStatus.idle => _MessagePane(
                              icon: Iconsax.search_normal,
                              title: s.searchAdmin,
                              subtitle: s.t('destDashboardSub'),
                            ),
                          AdminSearchStatus.loading
                              when state.results.destinations.isEmpty &&
                                  state.results.coaches.isEmpty =>
                            const Center(
                              child: CircularProgressIndicator(
                                color: EColorConstants.primaryColor,
                              ),
                            ),
                          AdminSearchStatus.loading => Column(
                              children: [
                                const LinearProgressIndicator(
                                  minHeight: 2,
                                  color: EColorConstants.primaryColor,
                                ),
                                Expanded(
                                  child: _ResultsList(results: state.results),
                                ),
                              ],
                            ),
                          AdminSearchStatus.error => _MessagePane(
                              icon: Iconsax.warning_2,
                              title: state.errorMessage ??
                                  'Something went wrong',
                            ),
                          AdminSearchStatus.ready when state.showEmpty =>
                            _MessagePane(
                              icon: Iconsax.search_status,
                              title: s.noMatches,
                              subtitle: s.t('destDashboardSub'),
                            ),
                          AdminSearchStatus.ready =>
                            _ResultsList(results: state.results),
                        };
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});

  final AdminSearchResults results;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        if (results.destinations.isNotEmpty)
          _Section(
            title: s.pages,
            children: results.destinations
                .map(
                  (d) => _HitTile(
                    title: d.localizedTitle(s),
                    subtitle: d.localizedSubtitle(s),
                    leading: _IconBadge(d.icon),
                    onTap: () => openAdminSearchDestination(context, d.id),
                  ),
                )
                .toList(),
          ),
        if (results.coaches.isNotEmpty)
          _Section(
            title: s.coaches,
            children: results.coaches
                .map(
                  (c) => _HitTile(
                    title: c.name,
                    subtitle: [
                      c.specialty,
                      if (c.branchName != null && c.branchName!.isNotEmpty)
                        c.branchName!,
                    ].join(' · '),
                    leading: CoachAvatar(
                      coachName: c.name,
                      photoUrl: c.photoUrl,
                      size: 40,
                    ),
                    onTap: () => openAdminSearchCoach(context, c),
                  ),
                )
                .toList(),
          ),
        if (results.sessions.isNotEmpty)
          _Section(
            title: s.classes,
            children: results.sessions
                .map(
                  (session) => _HitTile(
                    title: session.sessionType.isNotEmpty
                        ? session.sessionType
                        : (session.coachName ?? s.classes),
                    subtitle: [
                      if (session.coachName != null &&
                          session.coachName!.isNotEmpty)
                        session.coachName!,
                      if (session.days.isNotEmpty) session.days.join(', '),
                      if (session.timeSlots.isNotEmpty)
                        session.timeSlots.first,
                    ].join(' · '),
                    leading: const _IconBadge(Iconsax.calendar_1),
                    onTap: () => openAdminSearchSession(context, session),
                  ),
                )
                .toList(),
          ),
        if (results.members.isNotEmpty)
          _Section(
            title: s.members,
            children: results.members
                .map(
                  (m) => _HitTile(
                    title: m.fullName,
                    subtitle: [
                      if (m.phone != null && m.phone!.isNotEmpty) m.phone!,
                      if (m.activeBookings > 0)
                        '${m.activeBookings} active',
                    ].join(' · '),
                    leading: CoachAvatar(
                      coachName: m.fullName,
                      size: 40,
                    ),
                    onTap: () => openAdminSearchMember(context, m),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EColorConstants.authPlaceholderGray,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: EColorConstants.authTextDarkBrown,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: EColorConstants.authPlaceholderGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
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

class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: EColorConstants.primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: EColorConstants.primaryColor),
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: EColorConstants.authPlaceholderGray),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: EColorConstants.authTextDarkBrown,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: EColorConstants.authPlaceholderGray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
