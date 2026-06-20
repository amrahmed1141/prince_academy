import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';
import 'package:prince_academy/features/home/data/models/coaches_model.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_details/booking.dart';
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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = sl<HomeCoachRepository>();
      final coachFuture = repository.getCoachById(widget.coachId);
      final sessionsFuture = repository.getCoachSessions(widget.coachId);

      final coach = await coachFuture;
      final sessions = await sessionsFuture;

      if (mounted) {
        setState(() {
          _coach = coach;
          _sessions = sessions;
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

  Widget _buildCoachHeaderImage(String? photoUrl, Size size) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Icon(Iconsax.user, color: Colors.white24, size: 80),
      );
    }
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return Image.network(
        photoUrl,
        fit: BoxFit.cover,
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

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: EColorConstants.primaryColor,
          ),
        ),
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

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: size.height * 0.4,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoachHeaderImage(coach.photoUrl, size),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child:
                      const Icon(Iconsax.share, color: Colors.white, size: 20),
                ),
                onPressed: () {},
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      dark ? EColorConstants.darkContainerColor : Colors.white,
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
          ),
          SliverToBoxAdapter(
            child: Container(
              color: dark ? EColorConstants.darkContainerColor : Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    const SizedBox(height: 8),
                    Text(
                      coach.specialty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: dark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                EColorConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color:
                                  EColorConstants.primaryColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.user,
                                  size: 14,
                                  color: EColorConstants.primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                '120 Students Trained',
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
                    const SizedBox(height: 24),
                    Text(
                      'About Me',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: dark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                            height: 1.5,
                          ),
                    ),
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
                        final classesTaught = _sessions
                            .map((s) => s.sessionType)
                            .where((t) => t.isNotEmpty)
                            .toSet()
                            .toList();
                        if (classesTaught.isEmpty) {
                          classesTaught.add(coach.specialty);
                        }
                        return classesTaught
                            .map((className) =>
                                _buildSpecialtyChip(className, context))
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
                    if (_sessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 16),
                        decoration: BoxDecoration(
                          color: dark ? Colors.grey[900] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: dark ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.calendar_remove,
                              size: 40,
                              color: dark ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No sessions available yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                            )
                          ],
                        ),
                      )
                    else
                      ...expandCoachSessions(_sessions).map(
                        (pair) => SessionInfoCard(
                          classType: pair.classType,
                          day: pair.day,
                          time: pair.time,
                          sessionsPerWeek: pair.sessionsPerWeek,
                        ),
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
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
                onPressed: () {
                  // Handle message action
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: EColorConstants.primaryColor,
                    width: 1.5,
                  ),
                ),
                child: const Icon(Iconsax.message,
                    color: EColorConstants.primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
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
                        ),
                      ),
                    ),
                  );
                },
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
                      'Book Session',
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

  Widget _buildSpecialtyChip(String specialty, BuildContext context) {
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
        specialty,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: dark ? Colors.white : EColorConstants.primaryColor,
              fontSize: 12,
            ),
      ),
    );
  }
}
