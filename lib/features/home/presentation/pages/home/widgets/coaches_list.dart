import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/features/home/presentation/pages/home/coach_profile.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/booking.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';

class CoachesList extends StatefulWidget {
  final ValueNotifier<String?> selectedCategoryNotifier;

  const CoachesList({super.key, required this.selectedCategoryNotifier});

  @override
  State<CoachesList> createState() => _CoachesListState();
}

class _CoachesListState extends State<CoachesList> {
  List<CoachModel> _coaches = [];
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

      if (mounted) {
        setState(() {
          _coaches = result;
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

  Widget _buildCoachImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        width: 90,
        height: 110,
        color: Colors.grey[300],
        child: const Icon(Iconsax.user, color: Colors.grey, size: 36),
      );
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        width: 90,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 90,
          height: 110,
          color: Colors.grey[300],
          child: const Icon(Iconsax.user, color: Colors.grey, size: 36),
        ),
      );
    }
    return Image.asset(
      photoUrl,
      width: 90,
      height: 110,
      fit: BoxFit.cover,
    );
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
          return RepaintBoundary(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoachProfilePage(
                      coachId: coach.id,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: dark ? Colors.grey[800] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildCoachImage(coach.photoUrl),
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
                                    coach.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: dark ? Colors.white : Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Iconsax.verify5,
                                    size: 18, color: EColorConstants.primaryColor)
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              coach.specialty,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        dark ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // AbsorbPointer / GestureDetector stops click bubbling up to the card
                                GestureDetector(
                                  onTap: () {}, // consume details tap
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookingPage(
                                            bookingInfo: MMABookingModel(
                                              coachId: coach.id,
                                              coachName: coach.name,
                                              coachImage: coach.photoUrl ?? '',
                                              specialty: coach.specialty,
                                              coachWhatsapp: '+1234567890',
                                              availableDays: const ['Monday', 'Wednesday', 'Friday', 'Saturday'],
                                              availableTimes: const ['7:00 AM', '8:00 AM', '9:00 AM', '5:00 PM', '6:00 PM', '7:00 PM'],
                                              sessionPackages: const [8, 12],
                                              pricePerSession: 25.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EColorConstants.primaryColor,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 3,
                                      shadowColor: EColorConstants.primaryColor.withOpacity(0.3),
                                    ),
                                    icon: const Icon(Iconsax.ticket,
                                        size: 16, color: Colors.white),
                                    label: const Text(
                                      'Booking Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: _coaches.length,
      ),
    );
  }
}
