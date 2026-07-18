import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/constants/text.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/category_list.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/coaches_list.dart';
import 'package:prince_academy/features/home/presentation/pages/home/widgets/searchbar.dart';
import 'package:prince_academy/features/home/presentation/pages/coaches_page.dart';
import 'package:prince_academy/features/maps/data/models/maps_model.dart';
import 'package:prince_academy/features/maps/presentation/pages/maps/widgets/maps.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<String?> _selectedCategoryNotifier = ValueNotifier<String?>('All');

  @override
  void dispose() {
    _selectedCategoryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppGradients.sessionsScreenDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ETexts.appBarTitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              ETexts.appBarSubTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: const Icon(Iconsax.notification, size: 20),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const HomeSearchBar(),
                const SizedBox(height: 24),

                // Gym Location Map Container - ADD THIS
                GymMapContainer(
                    gymLocation:
                        gymLocations[0]), // Show the first gym location

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                CategoryList(selectedCategoryNotifier: _selectedCategoryNotifier),
                const SizedBox(height: 24),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Your Coach',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const CoachesPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: EColorConstants.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            sliver: CoachesList(selectedCategoryNotifier: _selectedCategoryNotifier),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    ),
    );
  }
}

