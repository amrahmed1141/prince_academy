import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/search/search_cubit.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/home_coach_card.dart';

/// Full coaches directory with search — opened from Home "View All"
/// and the First Time Booking Card CTA.
class CoachesPage extends StatefulWidget {
  const CoachesPage({super.key});

  @override
  State<CoachesPage> createState() => _CoachesPageState();
}

class _CoachesPageState extends State<CoachesPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _classTypesByCoachId = {};

  late final SearchCubit<CoachModel> _searchCubit;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchCubit = SearchCubit<CoachModel>(
      matcher: (coach, query) {
        final classType =
            (_classTypesByCoachId[coach.id] ?? '').toLowerCase();
        return coach.name.toLowerCase().contains(query) ||
            coach.specialty.toLowerCase().contains(query) ||
            classType.contains(query);
      },
    );
    // Defer so a sync cache hit never setStates during the first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCoaches();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchCubit.close();
    super.dispose();
  }

  Future<void> _loadCoaches({bool force = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = sl<HomeCoachRepository>();
      final allCoaches = await repository.getActiveCoaches(force: force);
      final coachIds = allCoaches.map((c) => c.id).toList();
      final results = await Future.wait([
        repository.getPrimaryClassTypesForCoaches(coachIds, force: force),
        repository.getStudentCountsForCoaches(coachIds, force: force),
      ]);
      final classTypes = results[0] as Map<String, String>;
      final memberCounts = results[1] as Map<String, int>;

      if (!mounted) return;

      final coaches = allCoaches
          .map(
            (coach) => coach.copyWith(
              memberCount: memberCounts[coach.id] ?? coach.memberCount,
            ),
          )
          .toList();

      _classTypesByCoachId
        ..clear()
        ..addAll(classTypes);
      _searchCubit.setItems(coaches);

      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchCubit,
      child: Theme(
        data: EAppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        child: Material(
          color: const Color(0xFFFFF9F5),
          child: Container(
            decoration: AppGradients.homeScreenDecoration(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                foregroundColor: Colors.black,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text('Choose Your Coach'),
                centerTitle: false,
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CubitSearchBar<CoachModel>(
                    controller: _searchController,
                    hintText: 'Search coaches by name or specialty',
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: CoachListShimmer(itemCount: 6),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, color: Colors.red[400], size: 40),
              const SizedBox(height: 8),
              const Text(
                'Failed to load coaches',
                style: TextStyle(
                  color: AppColors.textPrimary,
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
      );
    }

    return BlocBuilder<SearchCubit<CoachModel>, SearchState<CoachModel>>(
      builder: (context, state) {
        if (state.filteredItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.user_remove, color: Colors.grey[400], size: 40),
                  const SizedBox(height: 12),
                  Text(
                    state.hasQuery ? 'No matching coaches' : 'No coaches found',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.hasQuery
                        ? 'Try a different name or specialty.'
                        : 'Check back later for available coaches.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(15, 4, 15, 24),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: state.filteredItems.length,
          itemBuilder: (context, index) {
            final coach = state.filteredItems[index];
            return RepaintBoundary(
              child: HomeCoachCard(
                key: ValueKey(coach.id),
                coach: coach,
                classType: _classTypesByCoachId[coach.id],
              ),
            );
          },
        );
      },
    );
  }
}
