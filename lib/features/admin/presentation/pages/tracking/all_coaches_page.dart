import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/features/admin/data/models/coach_user_stats_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';

class AllCoachesPage extends StatefulWidget {
  final List<CoachUserStats> initialCoaches;

  const AllCoachesPage({
    super.key,
    this.initialCoaches = const [],
  });

  @override
  State<AllCoachesPage> createState() => _AllCoachesPageState();
}

class _AllCoachesPageState extends State<AllCoachesPage> {
  final _searchController = TextEditingController();
  final _repository = sl<CoachRepository>();

  List<CoachUserStats> _allCoaches = [];
  List<CoachUserStats> _visibleCoaches = [];
  bool _isLoading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _allCoaches = List.of(widget.initialCoaches);
    _visibleCoaches = List.of(_allCoaches);
    _loadCoaches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoaches() async {
    setState(() {
      _isLoading = _allCoaches.isEmpty;
      _error = null;
    });

    try {
      final coaches = await _repository.getCoachUserStats();
      if (!mounted) return;
      setState(() {
        _allCoaches = coaches;
        _visibleCoaches = _filter(coaches, _searchController.text);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _visibleCoaches = _filter(_allCoaches, query));
    });
  }

  List<CoachUserStats> _filter(List<CoachUserStats> source, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return List.of(source);
    return source.where((coach) {
      final name = coach.coachName.toLowerCase();
      final specialty = coach.coachSpecialty.toLowerCase();
      final branch = coach.branchName?.toLowerCase() ?? '';
      return name.contains(trimmed) ||
          specialty.contains(trimmed) ||
          branch.contains(trimmed);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        backgroundColor: EColorConstants.authFieldBackground,
        elevation: 0,
        leading: const BackButton(color: EColorConstants.authTextDarkBrown),
        title: Text(
          'All Coaches (${_visibleCoaches.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: EColorConstants.authTextDarkBrown,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search by coach name...',
            variant: AppSearchBarVariant.outlined,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            onChanged: _onSearchChanged,
            onClear: () {
              _searchController.clear();
              setState(() => _visibleCoaches = List.of(_allCoaches));
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: EColorConstants.primaryColor),
      );
    }

    if (_error != null && _allCoaches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadCoaches, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_visibleCoaches.isEmpty) {
      return const Center(
        child: Text(
          'No coaches match your search.',
          style: TextStyle(
            color: EColorConstants.authPlaceholderGray,
            fontFamily: 'Poppins',
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: EColorConstants.primaryColor,
      onRefresh: _loadCoaches,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _visibleCoaches.length,
        itemBuilder: (context, index) {
          final coach = _visibleCoaches[index];
          return _CoachListCard(
            coach: coach,
            onTap: () => Navigator.of(context).pop(coach.coachId),
          );
        },
      ),
    );
  }
}

class _CoachListCard extends StatelessWidget {
  final CoachUserStats coach;
  final VoidCallback onTap;

  const _CoachListCard({
    required this.coach,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EColorConstants.authCardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: EColorConstants.authFieldBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: EColorConstants.authFieldBorder,
                  width: 2,
                ),
              ),
              child: CoachAvatar(
                coachName: coach.coachName,
                photoUrl: coach.coachPhoto,
                size: 52,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          coach.coachName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: EColorConstants.authTextDarkBrown,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Iconsax.verify5,
                        size: 15,
                        color: EColorConstants.primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coach.coachSpecialty,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EColorConstants.authPlaceholderGray,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  if (coach.branchName != null &&
                      coach.branchName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      coach.branchName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${coach.totalSubscribers} users',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        ' ${coach.activeSubscribers} active',
                        style: const TextStyle(
                          fontSize: 11,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD32F2F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        ' ${coach.expiredSubscribers} expired',
                        style: const TextStyle(
                          fontSize: 11,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
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
    );
  }
}
