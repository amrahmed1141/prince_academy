import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/cache/image_cache.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/booking/presentation/helpers/book_now_navigation.dart';
import 'package:prince_academy/features/booking/presentation/widgets/branch_picker_sheet.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/session_info_card.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/custom_snackbar.dart';

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
  String? _selectedBranchId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    setState(() {
      if (!silent || _coach == null) {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final repository = sl<HomeCoachRepository>();
      final results = await Future.wait([
        repository.getCoachById(widget.coachId),
        repository.getCoachSessions(widget.coachId),
      ]);

      if (mounted) {
        final sessions = results[1] as List<CoachSessionModel>;
        final branches = uniqueBranchesFromSessions(sessions);
        setState(() {
          _coach = results[0] as CoachModel?;
          _sessions = sessions;
          _branches = branches;
          _selectedBranchId = branches.length == 1
              ? branches.first.id
              : (_selectedBranchId != null &&
                      branches.any((b) => b.id == _selectedBranchId)
                  ? _selectedBranchId
                  : null);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<CoachSessionModel> get _visibleSessions {
    if (_selectedBranchId == null || _branches.length <= 1) {
      return _sessions;
    }
    return _sessions
        .where((s) => s.branchId == _selectedBranchId)
        .toList();
  }

  String? get _selectedBranchName {
    if (_selectedBranchId == null) return null;
    for (final branch in _branches) {
      if (branch.id == _selectedBranchId) return branch.name;
    }
    return null;
  }

  Future<void> _onBookNowTap(BuildContext context, CoachModel coach) async {
    if (_branches.length > 1 &&
        (_selectedBranchId == null || _selectedBranchId!.isEmpty)) {
      CustomSnackbar.show(
        context: context,
        message: 'Please select a branch first',
      );
      return;
    }

    await BookNowNavigation.openBookingForCoach(
      context: context,
      coachId: coach.id,
      coachName: coach.name,
      coachImage: coach.photoUrl ?? '',
      specialty: coach.specialty,
      branchId: _selectedBranchId,
      branchName: _selectedBranchName,
    );
  }

  Widget _buildCoachHeaderImage(String? photoUrl, Size size) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Icon(Iconsax.user, color: Colors.white24, size: 80),
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
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Icon(Iconsax.user, color: Colors.white24, size: 80),
        ),
      );
    }
    return Image.asset(
      photoUrl,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    final size = MediaQuery.of(context).size;

    if (_isLoading && _coach == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Coach Profile')),
        body: const CoachProfileShimmer(),
      );
    }

    if (_errorMessage != null || _coach == null) {
      return Scaffold(
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
                  onPressed: _loadData,
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

    final coach = _coach!;
    final visibleSessions = _visibleSessions;
    final sheetColor =
        dark ? EColorConstants.darkContainerColor : Colors.white;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: size.height * 0.4,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoachHeaderImage(coach.photoUrl, size),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.5),
                            ),
                            child: const Icon(
                              Iconsax.share,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
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
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              EColorConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: EColorConstants.primaryColor
                                .withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.user,
                              size: 14,
                              color: EColorConstants.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              coach.memberCount == 1
                                  ? '1 Member Trained'
                                  : '${coach.memberCount} Members Trained',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: EColorConstants.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_branches.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      _branches.length > 1 ? 'Choose Branch' : 'Branch',
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
                        final selected = _selectedBranchId == branch.id;
                        final isSelectable = _branches.length > 1;
                        return GestureDetector(
                          onTap: isSelectable
                              ? () => setState(
                                    () => _selectedBranchId = branch.id,
                                  )
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? EColorConstants.primaryColor
                                      .withOpacity(0.12)
                                  : (dark
                                      ? Colors.grey[800]
                                      : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? EColorConstants.primaryColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.location,
                                  size: 14,
                                  color: selected
                                      ? EColorConstants.primaryColor
                                      : (dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  branch.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: selected
                                            ? EColorConstants.primaryColor
                                            : (dark
                                                ? Colors.white
                                                : Colors.black87),
                                        fontSize: 12,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Classes Taught',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (() {
                      final classesTaught = visibleSessions
                          .map((s) => s.sessionType)
                          .where((t) => t.isNotEmpty)
                          .expand((t) => t.split(',').map((e) => e.trim()))
                          .where((t) => t.isNotEmpty)
                          .toSet()
                          .toList();
                      if (classesTaught.isEmpty) {
                        return [
                          Text(
                            'No classes listed yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                          ),
                        ];
                      }
                      return classesTaught
                          .map(
                            (className) =>
                                _buildClassChip(className, context),
                          )
                          .toList();
                    })(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sessions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (visibleSessions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: dark ? Colors.grey[900] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              dark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Iconsax.calendar_remove,
                            size: 40,
                            color:
                                dark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _branches.length > 1 &&
                                    _selectedBranchId == null
                                ? 'Select a branch to view sessions'
                                : 'No sessions available yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: dark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...expandCoachSessions(visibleSessions).map(
                      (pair) => SessionInfoCard(
                        classType: pair.classType,
                        day: pair.day,
                        time: pair.time,
                        sessionsPerWeek: pair.sessionsPerWeek,
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
          color: dark ? Colors.grey[900] : Colors.white,
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

  Widget _buildClassChip(String className, BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.grey[800]
            : EColorConstants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        className,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? Colors.white : EColorConstants.primaryColor,
              fontSize: 12,
            ),
      ),
    );
  }
}
