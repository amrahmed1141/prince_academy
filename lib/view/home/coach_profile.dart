import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/model/booking_model.dart';
import 'package:prince_academy/model/coaches_model.dart';
import 'package:prince_academy/utils/constants/colors.dart';
import 'package:prince_academy/utils/helpers/helper_function.dart';
import 'package:prince_academy/view/booking_details/booking.dart';

class CoachProfilePage extends StatelessWidget {
  final CoachesModel coach;

  const CoachProfilePage({super.key, required this.coach});

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    final size = MediaQuery.of(context).size;

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
                  Image.asset(
                    coach.imageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
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
                        Expanded(
                          child: Text(
                            coach.name ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                          ),
                        ),
                        const Icon(Iconsax.verify5,
                            size: 24, color: EColorConstants.primaryColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coach.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: dark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildRatingInfo(context, '4.9', 'Rating'),
                        const SizedBox(width: 16),
                        _buildRatingInfo(context, '120', 'Students'),
                        const SizedBox(width: 16),
                        _buildRatingInfo(context, '5', 'Years'),
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
                      'Specialties',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSpecialtyChip('Basketball', context),
                        _buildSpecialtyChip('Fitness Training', context),
                        _buildSpecialtyChip('Strength & Conditioning', context),
                        _buildSpecialtyChip('Nutrition', context),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Availability',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildScheduleCard(context, dark),
                    const SizedBox(height: 24),
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
                      builder: (context) => MMABookingPage(
                        bookingInfo: MMABookingModel(
                          coachName: coach.name ?? '',
                          coachImage: coach.imageUrl ?? '',
                          coachWhatsapp:
                              '+1234567890', // Add coach's WhatsApp number
                          availableDays: [
                            'Monday',
                            'Wednesday',
                            'Friday',
                            'Saturday'
                          ],
                          availableTimes: [
                            '7:00 AM',
                            '8:00 AM',
                            '9:00 AM',
                            '5:00 PM',
                            '6:00 PM',
                            '7:00 PM'
                          ],
                          sessionPackages: [6, 8, 12],
                          pricePerSession: 25.0,
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

  Widget _buildRatingInfo(BuildContext context, String value, String label) {
    final dark = EHelperFunction.isDarkMode(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: dark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
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

  Widget _buildScheduleCard(BuildContext context, bool dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.calendar,
              size: 24, color: EColorConstants.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mon - Fri',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '9:00 AM - 6:00 PM',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: dark ? Colors.grey[400] : Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const Icon(Iconsax.arrow_right_3, size: 20, color: Colors.grey),
        ],
      ),
    );
  }
}
