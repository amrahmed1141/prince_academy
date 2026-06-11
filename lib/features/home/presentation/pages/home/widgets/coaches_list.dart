import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/home_coach_card.dart';

class CoachesList extends StatefulWidget {
  final ValueNotifier<String?> selectedCategoryNotifier;

  const CoachesList({super.key, required this.selectedCategoryNotifier});

  @override
  State<CoachesList> createState() => _CoachesListState();
}

class _CoachesListState extends State<CoachesList> {
  List<CoachModel> _coaches = [];
  Map<String, String> _classTypesByCoachId = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.selectedCategoryNotifier.addListener(_onCategoryChanged);
    _loadCoaches();
  }

  @override
  void didUpdateWidget(covariant CoachesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryNotifier != widget.selectedCategoryNotifier) {
      oldWidget.selectedCategoryNotifier.removeListener(_onCategoryChanged);
      widget.selectedCategoryNotifier.addListener(_onCategoryChanged);
      _loadCoaches();
    }
  }

  @override
  void dispose() {
    widget.selectedCategoryNotifier.removeListener(_onCategoryChanged);
    super.dispose();
  }

  void _onCategoryChanged() {
    _loadCoaches();
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

  Future<void> _loadCoaches() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = sl<HomeCoachRepository>();
      final specialty = _mapCategoryToSpecialty(widget.selectedCategoryNotifier.value);
      
      List<CoachModel> result;
      if (specialty == null) {
        result = await repository.getActiveCoaches();
      } else {
        result = await repository.getCoachesBySpecialty(specialty);
      }

      final classTypes = await repository.getPrimaryClassTypesForCoaches(
        result.map((c) => c.id).toList(),
      );

      if (mounted) {
        setState(() {
          _coaches = result;
          _classTypesByCoachId = classTypes;
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

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(
              color: EColorConstants.primaryColor,
            ),
          ),
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
                Text(
                  'Failed to load coaches',
                  style: TextStyle(
                    color: dark ? Colors.white : Colors.black,
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
                  onPressed: _loadCoaches,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColorConstants.primaryColor,
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_coaches.isEmpty) {
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
                  'No coaches found',
                  style: TextStyle(
                    color: dark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try selecting another category or check back later.',
                  style: TextStyle(color: Colors.grey[550], fontSize: 12),
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
          final coach = _coaches[index];
          return HomeCoachCard(
            coach: coach,
            classType: _classTypesByCoachId[coach.id],
            dark: dark,
          );
        },
        childCount: _coaches.length,
      ),
    );
  }
}
