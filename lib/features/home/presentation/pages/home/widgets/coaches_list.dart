import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/cache/image_cache.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';
import 'package:prince_academy/core/search/search_query_cubit.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/home_coach_card.dart';

class CoachesList extends StatefulWidget {
  final ValueNotifier<String?> selectedCategoryNotifier;
  final SearchQueryCubit? searchQueryCubit;

  const CoachesList({
    super.key,
    required this.selectedCategoryNotifier,
    this.searchQueryCubit,
  });

  @override
  State<CoachesList> createState() => _CoachesListState();
}

class _CoachesListState extends State<CoachesList> {
  List<CoachModel> _allCoaches = [];
  List<CoachModel> _filteredCoaches = [];
  Map<String, String> _classTypesByCoachId = {};
  bool _isInitialLoading = true;
  String? _errorMessage;
  StreamSubscription<String>? _searchSub;

  @override
  void initState() {
    super.initState();
    widget.selectedCategoryNotifier.addListener(_onFiltersChanged);
    _bindSearchCubit(widget.searchQueryCubit);
    _seedFromCache();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCoaches(initial: _allCoaches.isEmpty);
    });
  }

  @override
  void didUpdateWidget(covariant CoachesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryNotifier != widget.selectedCategoryNotifier) {
      oldWidget.selectedCategoryNotifier.removeListener(_onFiltersChanged);
      widget.selectedCategoryNotifier.addListener(_onFiltersChanged);
      _applyFilters();
    }
    if (oldWidget.searchQueryCubit != widget.searchQueryCubit) {
      _bindSearchCubit(widget.searchQueryCubit);
      _applyFilters();
    }
  }

  void _bindSearchCubit(SearchQueryCubit? cubit) {
    _searchSub?.cancel();
    _searchSub = cubit?.stream.listen((_) {
      if (mounted) _applyFilters();
    });
  }

  @override
  void dispose() {
    widget.selectedCategoryNotifier.removeListener(_onFiltersChanged);
    _searchSub?.cancel();
    super.dispose();
  }

  void _onFiltersChanged() => _applyFilters();

  void _seedFromCache() {
    final repository = sl<HomeCoachRepository>();
    final cached = repository.peekActiveCoaches();
    if (cached.isEmpty) return;

    final counts = repository.peekStudentCounts();
    _allCoaches = cached
        .map(
          (coach) => coach.copyWith(
            memberCount: counts[coach.id] ?? coach.memberCount,
          ),
        )
        .toList();
    _classTypesByCoachId = repository.peekClassTypes();
    _isInitialLoading = false;
    _filteredCoaches = _computeFiltered();
  }

  void _warmPhotos(List<CoachModel> coaches) {
    final urls = CoachPhotoHelper.thumbnailUrls(
      coaches.map((coach) => coach.photoUrl),
    );
    unawaited(AppImageCache.warmUrls(urls));
    if (!mounted) return;
    unawaited(AppImageCache.precacheUrls(context, urls));
  }

  String? _mapCategoryToSpecialty(String? categoryName) {
    if (categoryName == null || categoryName == 'All') return null;
    switch (categoryName.toLowerCase()) {
      case 'jiujitsu':
      case 'bjj':
        return 'BJJ';
      case 'kickboxing':
        return 'Muay Thai';
      case 'mma':
        return 'MMA';
      case 'boxing':
        return 'Boxing';
      default:
        return categoryName;
    }
  }

  Future<void> _loadCoaches({bool initial = false, bool force = false}) async {
    if (!mounted) return;
    if (initial && _allCoaches.isEmpty) {
      setState(() {
        _isInitialLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final repository = sl<HomeCoachRepository>();
      final allCoaches = await repository.getActiveCoaches(force: force);
      if (!mounted) return;

      _emitCoaches(allCoaches, classTypes: _classTypesByCoachId);
      _warmPhotos(allCoaches);

      final coachIds = allCoaches.map((c) => c.id).toList();
      try {
        final results = await Future.wait([
          repository.getPrimaryClassTypesForCoaches(coachIds, force: force),
          repository.getStudentCountsForCoaches(coachIds, force: force),
        ]);
        if (!mounted) return;
        final classTypes = results[0] as Map<String, String>;
        final memberCounts = results[1] as Map<String, int>;
        final coaches = allCoaches
            .map<CoachModel>(
              (coach) => coach.copyWith(
                memberCount: memberCounts[coach.id] ?? coach.memberCount,
              ),
            )
            .toList();
        _emitCoaches(coaches, classTypes: classTypes);
      } catch (_) {
        // Keep the coach cards visible; extras are optional chrome.
      }
    } catch (e) {
      if (mounted && _allCoaches.isEmpty) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isInitialLoading = false;
        });
      }
    }
  }

  void _emitCoaches(
    List<CoachModel> coaches, {
    required Map<String, String> classTypes,
  }) {
    setState(() {
      _allCoaches = coaches;
      _classTypesByCoachId = classTypes;
      _isInitialLoading = false;
      _errorMessage = null;
      _filteredCoaches = _computeFiltered();
    });
  }

  List<CoachModel> _computeFiltered() {
    final specialty =
        _mapCategoryToSpecialty(widget.selectedCategoryNotifier.value);
    final query = widget.searchQueryCubit?.state ?? '';

    var filtered = specialty == null
        ? List<CoachModel>.from(_allCoaches)
        : _allCoaches
            .where((c) => c.specialty.toLowerCase() == specialty.toLowerCase())
            .toList();

    if (query.isNotEmpty) {
      filtered = filtered.where((coach) {
        final classType =
            (_classTypesByCoachId[coach.id] ?? '').toLowerCase();
        return coach.name.toLowerCase().contains(query) ||
            coach.specialty.toLowerCase().contains(query) ||
            classType.contains(query);
      }).toList();
    }
    return filtered;
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() => _filteredCoaches = _computeFiltered());
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: CoachListShimmer(itemCount: 5),
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.warning_2, color: Colors.red[400], size: 40),
                const SizedBox(height: 8),
                const Text(
                  'Failed to load coaches',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _loadCoaches(force: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColorConstants.primaryColor,
                  ),
                  child:
                      const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredCoaches.isEmpty) {
      final hasQuery = widget.searchQueryCubit?.hasQuery ?? false;
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.user_remove, color: Colors.grey[400], size: 40),
                const SizedBox(height: 12),
                Text(
                  hasQuery ? 'No matching coaches' : 'No coaches found',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasQuery
                      ? 'Try a different name or specialty.'
                      : 'Try selecting another category or check back later.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final coach = _filteredCoaches[index];
          return RepaintBoundary(
            child: HomeCoachCard(
              key: ValueKey(coach.id),
              coach: coach,
              classType: _classTypesByCoachId[coach.id],
            ),
          );
        },
        childCount: _filteredCoaches.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
      ),
    );
  }
}
