import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/cache/image_cache.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/core/widgets/offline_banner.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/booking/presentation/helpers/book_now_navigation.dart';
import 'package:prince_academy/features/booking/presentation/widgets/branch_picker_sheet.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/session_info_card.dart';
import 'package:prince_academy/core/di/injection.dart';

class CoachProfilePage extends StatefulWidget {
  final String coachId;

  const CoachProfilePage({super.key, required this.coachId});

  @override
  State<CoachProfilePage> createState() => _CoachProfilePageState();
}

class _CoachProfilePageState extends State<CoachProfilePage> {
  CoachModel? _coach;
  List<CoachSessionModel> _sessions = [];
  List<CoachBranchOption> _branches = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _seedFromCache();
    _loadData();
  }

  void _seedFromCache() {
    final repository = sl<HomeCoachRepository>();
    final cachedCoach = repository.cachedCoach(widget.coachId);
    final cachedSessions = repository.cachedCoachSessions(widget.coachId);

    if (cachedCoach == null && cachedSessions == null) return;

    if (cachedSessions != null) {
      _sessions = cachedSessions;
      _branches = uniqueBranchesFromSessions(cachedSessions);
    }

    if (cachedCoach != null) {
      _coach = cachedCoach;
      _isLoading = false;
      _hasLoaded = true;
    }
  }

  void _applyLoadedData({
    required CoachModel coach,
    required List<CoachSessionModel> sessions,
  }) {
    setState(() {
      _coach = coach;
      _sessions = sessions;
      _branches = uniqueBranchesFromSessions(sessions);
      _isLoading = false;
      _isRefreshing = false;
      _hasLoaded = true;
      _errorMessage = null;
    });
  }

  Future<void> _loadData({bool forceRefresh = true}) async {
    final hasCachedUi = _coach != null;

    setState(() {
      if (hasCachedUi) {
        _isRefreshing = true;
        _errorMessage = null;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    try {
      final repository = sl<HomeCoachRepository>();
      final results = await Future.wait([
        repository.getCoachById(widget.coachId, force: forceRefresh),
        repository.getCoachSessions(widget.coachId, force: forceRefresh),
      ]);

      if (!mounted) return;

      _applyLoadedData(
        coach: results[0] as CoachModel,
        sessions: results[1] as List<CoachSessionModel>,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRefreshing = false;
        _isLoading = false;
        if (!_hasLoaded || _coach == null) {
          _errorMessage = e.toString();
        }
      });
    }
  }

  int get _totalSessionCount => expandCoachSessions(_sessions).length;

  Future<void> _onBookNowTap(BuildContext context, CoachModel coach) async {
    // Branch is chosen in the booking flow when the coach has multiple branches.
    final singleBranch = _branches.length == 1 ? _branches.first : null;

    await BookNowNavigation.openBookingForCoach(
      context: context,
      coachId: coach.id,
      coachName: coach.name,
      coachImage: coach.photoUrl ?? '',
      specialty: coach.specialty,
      branchId: singleBranch?.id,
      branchName: singleBranch?.name,
    );
  }

  Widget _buildCoachHeaderImage(String? photoUrl, Size size) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return ColoredBox(
        color: Colors.grey[900]!,
        child: const Center(
          child: Icon(Iconsax.user, color: Colors.white24, size: 80),
        ),
      );
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final cacheWidth = (size.width * dpr).round().clamp(320, 1280);
      return Image(
        image: ResizeImage(
          AppImageCache.provider(photoUrl),
          width: cacheWidth,
        ),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.topCenter,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: Colors.grey[900]!,
          child: const Center(
            child: Icon(Iconsax.user, color: Colors.white24, size: 80),
          ),
        ),
      );
    }
    return Image.asset(
      photoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topCenter,
    );
  }

  Widget _overlayIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _statsRow({
    required int memberCount,
    required int sessionCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Iconsax.profile_2user,
            value: '$memberCount',
            label: 'Members',
          ),
        ),
        Container(
          width: 1,
          height: 48,
          color: Colors.grey[300],
        ),
        Expanded(
          child: _StatItem(
            icon: Iconsax.calendar_1,
            value: '$sessionCount',
            label: 'Sessions',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: EAppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;
          final topInset = MediaQuery.of(context).padding.top;

          if (_isLoading && _coach == null) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(title: const Text('Coach Profile')),
              body: const CoachProfileShimmer(),
            );
          }

          if ((_errorMessage != null && _coach == null) ||
              (!_isLoading && !_isRefreshing && _coach == null)) {
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: const Text('Coach Profile'),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.warning_2, color: Colors.red[400], size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Coach not found.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadData(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EColorConstants.primaryColor,
                        ),
                        child: const Text('Retry',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _buildLoadedProfile(
            context: context,
            size: size,
            topInset: topInset,
          );
        },
      ),
    );
  }

  Widget _buildLoadedProfile({
    required BuildContext context,
    required Size size,
    required double topInset,
  }) {
    final coach = _coach!;
    const sheetColor = Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SilentRefreshBar(visible: _isRefreshing && _hasLoaded),
          SizedBox(
            height: size.height * 0.42,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoachHeaderImage(coach.photoUrl, size),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + 72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topInset + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _overlayIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                      _overlayIconButton(
                        icon: Iconsax.share,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sheetColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: sheetColor,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          coach.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Iconsax.verify5,
                        size: 18,
                        color: EColorConstants.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _statsRow(
                    memberCount: coach.memberCount,
                    sessionCount: _totalSessionCount,
                  ),
                  if (_branches.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      _branches.length > 1 ? 'Branches' : 'Branch',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _branches.map((branch) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.location,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                branch.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.black87,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Sessions by Branch',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_sessionsByBranch.isEmpty ||
                      _sessionsByBranch.every((g) => g.pairs.isEmpty))
                    const _EmptySessionsCard()
                  else
                    ..._sessionsByBranch.map(
                      (group) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BranchSessionsCard(
                          branchName: group.branchName,
                          pairs: group.pairs,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: EColorConstants.primaryColor,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Iconsax.message,
                  color: EColorConstants.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => _onBookNowTap(context, coach),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColorConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.calendar, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Book Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_BranchSessionsGroup> get _sessionsByBranch {
    if (_branches.isEmpty) {
      final pairs = expandCoachSessions(_sessions);
      if (pairs.isEmpty) return const [];
      return [
        _BranchSessionsGroup(branchName: 'Sessions', pairs: pairs),
      ];
    }

    return _branches.map((branch) {
      final branchSessions =
          _sessions.where((s) => s.branchId == branch.id).toList();
      return _BranchSessionsGroup(
        branchName: branch.name,
        pairs: expandCoachSessions(branchSessions),
      );
    }).toList();
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: EColorConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _BranchSessionsGroup {
  const _BranchSessionsGroup({
    required this.branchName,
    required this.pairs,
  });

  final String branchName;
  final List<SessionDayTypePair> pairs;
}

String _compactDay(String day) {
  final value = day.trim();
  if (value.isEmpty || value == 'Day not set') return value;
  const map = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
    'mon': 'Mon',
    'tue': 'Tue',
    'wed': 'Wed',
    'thu': 'Thu',
    'fri': 'Fri',
    'sat': 'Sat',
    'sun': 'Sun',
  };
  return map[value.toLowerCase()] ?? value;
}

String _compactTime(String time) {
  var value = time.trim();
  if (value.isEmpty || value == 'Time not set') return value;
  value = value.replaceAll(':00', '');
  value = value.replaceAll(' ', '');
  return value;
}

String _sessionScheduleLabel(SessionDayTypePair pair) {
  final day = _compactDay(pair.day);
  final time = _compactTime(pair.time);
  if (day.isEmpty || day == 'Day not set') return time;
  if (time.isEmpty || time == 'Time not set') return day;
  return '$day $time';
}

class _BranchSessionsCard extends StatelessWidget {
  const _BranchSessionsCard({
    required this.branchName,
    required this.pairs,
  });

  final String branchName;
  final List<SessionDayTypePair> pairs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branchName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          if (pairs.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'No sessions yet',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                const columns = 3;
                const spacing = 8.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 14,
                  children: pairs.map((pair) {
                    return SizedBox(
                      width: itemWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pair.classType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sessionScheduleLabel(pair),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptySessionsCard extends StatelessWidget {
  const _EmptySessionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Iconsax.calendar_remove,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No sessions available yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
