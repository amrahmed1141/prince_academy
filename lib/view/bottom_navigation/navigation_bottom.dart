import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/utils/constants/colors.dart';
import 'package:prince_academy/utils/helpers/helper_function.dart';
import 'package:prince_academy/view_model/navigation_view_model.dart';
import 'package:provider/provider.dart';

class NavigationBottom extends StatelessWidget {
  const NavigationBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);
    return Scaffold(
      bottomNavigationBar: Consumer<NavigationViewModel>(
        builder: (context, viewModel, child) {
          return NavigationBar(
              height: 80,
              elevation: 0,
              backgroundColor: dark?EColorConstants.darkColor:EColorConstants.lightColor,
              selectedIndex: viewModel.currentIndex,
              onDestinationSelected: viewModel.changeIndex,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Iconsax.home_1), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Iconsax.ticket), label: 'Booking'),
                NavigationDestination(
                    icon: Icon(Iconsax.user), label: 'Profile')
              ]);
        },
      ),
      body: Consumer<NavigationViewModel>(builder: (context, viewModel, child) {
        return viewModel.currentPage;
      }),
    );
  }
}
