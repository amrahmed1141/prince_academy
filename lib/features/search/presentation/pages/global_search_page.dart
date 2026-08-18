import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/services/main_tab_controller.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/booking/data/models/booking_history_model.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/booking_detail_page.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/presentation/pages/coaches_page.dart';
import 'package:prince_academy/features/home/presentation/pages/home/coach_profile.dart';
import 'package:prince_academy/features/search/data/models/global_search_models.dart';
import 'package:prince_academy/features/search/data/member_app_search_index.dart';
import 'package:prince_academy/features/search/presentation/helpers/member_search_navigation.dart';
import 'package:prince_academy/features/search/presentation/member_search_hints.dart';
import 'package:prince_academy/features/search/presentation/cubit/global_search_cubit.dart';
import 'package:prince_academy/features/search/presentation/cubit/global_search_state.dart';
import 'package:prince_academy/features/sessions/data/models/session_model.dart';
import 'package:prince_academy/features/sessions/presentation/pages/user_session_detail_page.dart';

/// Opens the app-wide search overlay. Call only from Home.
Future<void> openGlobalSearch(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => Theme(
        data: EAppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          canvasColor: const Color(0xFFFFF9F5),
        ),
        child: BlocProvider(
          create: (_) => sl<GlobalSearchCubit>(),
          child: const GlobalSearchPage(),
        ),
      ),
    ),
  );
}

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
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
                hintText: 'Search...',
                hintPhrases: MemberSearchHints.global,
                onBack: () => Navigator.of(context).maybePop(),
                onChanged: context.read<GlobalSearchCubit>().search,
                onClear: () {
                  _controller.clear();
                  context.read<GlobalSearchCubit>().clear();
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<GlobalSearchCubit, GlobalSearchState>(
                  buildWhen: (prev, next) =>
                      prev.status != next.status ||
                      prev.results != next.results ||
                      prev.query != next.query ||
                      prev.errorMessage != next.errorMessage,
                  builder: (context, state) {
                    return switch (state.status) {
                      GlobalSearchStatus.idle => const _IdleHints(),
                      GlobalSearchStatus.loading when state.results.destinations.isEmpty =>
                        const Center(
                          child: CircularProgressIndicator(
                            color: EColorConstants.primaryColor,
                          ),
                        ),
                      GlobalSearchStatus.loading => Column(
                          children: [
                            const LinearProgressIndicator(
                              minHeight: 2,
                              color: EColorConstants.primaryColor,
                            ),
                            Expanded(
                              child: _ResultsList(
                                results: state.results,
                                onDestination: _openDestination,
                                onCoach: _openCoach,
                                onSession: _openSession,
                                onBooking: _openBooking,
                                onCategory: _openCategory,
                              ),
                            ),
                          ],
                        ),
                      GlobalSearchStatus.error => _MessagePane(
                          icon: Iconsax.warning_2,
                          title: state.errorMessage ?? 'Something went wrong',
                        ),
                      GlobalSearchStatus.ready when state.showEmpty =>
                        const _MessagePane(
                          icon: Iconsax.search_status,
                          title: 'No matches',
                          subtitle:
                              'Try a screen, coach, session, booking, or category',
                        ),
                      GlobalSearchStatus.ready => _ResultsList(
                          results: state.results,
                          onDestination: _openDestination,
                          onCoach: _openCoach,
                          onSession: _openSession,
                          onBooking: _openBooking,
                          onCategory: _openCategory,
                        ),
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

  Future<void> _openDestination(MemberSearchDestination destination) async {
    await openMemberSearchDestination(context, destination.id);
  }

  Future<void> _openCoach(CoachModel coach) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CoachProfilePage(coachId: coach.id),
      ),
    );
  }

  Future<void> _openSession(Session session) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UserSessionDetailPage(
          bookingId: session.bookingId,
          coachName: session.coachName,
          coachSpecialty: session.coachSpecialty.isNotEmpty
              ? session.coachSpecialty
              : 'MMA',
          sessionTime: session.selectedTime,
          branchName: session.branchName,
        ),
      ),
    );
  }

  Future<void> _openBooking(BookingHistoryModel booking) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookingDetailPage(booking: booking),
      ),
    );
  }

  Future<void> _openCategory(GlobalSearchCategoryHit _) async {
    sl<MainTabController>().goHome();
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CoachesPage()),
    );
  }
}

class _IdleHints extends StatelessWidget {
  const _IdleHints();

  @override
  Widget build(BuildContext context) {
    return const _MessagePane(
      icon: Iconsax.search_normal,
      title: 'Search the academy',
      subtitle: 'Screens, coaches, sessions, bookings & more',
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

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.results,
    required this.onDestination,
    required this.onCoach,
    required this.onSession,
    required this.onBooking,
    required this.onCategory,
  });

  final GlobalSearchResults results;
  final ValueChanged<MemberSearchDestination> onDestination;
  final ValueChanged<CoachModel> onCoach;
  final ValueChanged<Session> onSession;
  final ValueChanged<BookingHistoryModel> onBooking;
  final ValueChanged<GlobalSearchCategoryHit> onCategory;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      children: [
        if (results.destinations.isNotEmpty)
          _Section(
            title: 'Pages & actions',
            children: results.destinations
                .map(
                  (d) => _HitTile(
                    title: d.title,
                    subtitle: d.subtitle,
                    leading: _IconBadge(d.icon),
                    onTap: () => onDestination(d),
                  ),
                )
                .toList(),
          ),
        if (results.coaches.isNotEmpty)
          _Section(
            title: 'Coaches',
            children: results.coaches
                .map(
                  (c) => _HitTile(
                    title: c.name,
                    subtitle: c.specialty,
                    leading: CoachAvatar(
                      coachName: c.name,
                      photoUrl: c.photoUrl,
                      size: 40,
                    ),
                    onTap: () => onCoach(c),
                  ),
                )
                .toList(),
          ),
        if (results.sessions.isNotEmpty)
          _Section(
            title: 'Sessions',
            children: results.sessions
                .map(
                  (s) => _HitTile(
                    title: '${s.coachName} · ${s.dayName}',
                    subtitle:
                        '${s.selectedTime} · ${s.sessionStatus}${s.branchName != null ? ' · ${s.branchName}' : ''}',
                    leading: const _IconBadge(Iconsax.calendar_1),
                    onTap: () => onSession(s),
                  ),
                )
                .toList(),
          ),
        if (results.bookings.isNotEmpty)
          _Section(
            title: 'Bookings',
            children: results.bookings
                .map(
                  (b) => _HitTile(
                    title: b.coachName,
                    subtitle:
                        '${b.displayStatus}${b.selectedTime != null ? ' · ${b.selectedTime}' : ''}',
                    leading: const _IconBadge(Iconsax.ticket),
                    onTap: () => onBooking(b),
                  ),
                )
                .toList(),
          ),
        if (results.categories.isNotEmpty)
          _Section(
            title: 'Categories',
            children: results.categories
                .map(
                  (c) => _HitTile(
                    title: c.name,
                    subtitle: 'Category',
                    leading: _CategoryThumb(imageUrl: c.imageUrl),
                    onTap: () => onCategory(c),
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

class _CategoryThumb extends StatelessWidget {
  const _CategoryThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 40,
        height: 40,
        child: imageUrl == null
            ? const _IconBadge(Iconsax.category)
            : Image.asset(imageUrl!, fit: BoxFit.cover),
      ),
    );
  }
}
