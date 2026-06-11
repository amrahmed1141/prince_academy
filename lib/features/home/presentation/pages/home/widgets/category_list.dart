import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/features/home/data/models/catgeory_model.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/helper_function.dart';

class CategoryList extends StatelessWidget {
  final ValueNotifier<String?> selectedCategoryNotifier;

  const CategoryList({
    super.key,
    required this.selectedCategoryNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final dark = EHelperFunction.isDarkMode(context);

    // Create categories list starting with "All"
    final List<CategoryModel> displayCategories = [
      CategoryModel(id: 'all', name: 'All'),
      ...categories,
    ];

    return SizedBox(
      height: 110,
      child: ValueListenableBuilder<String?>(
        valueListenable: selectedCategoryNotifier,
        builder: (context, selectedCategory, _) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: displayCategories.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              // Default to 'All' if selectedCategory is null or matches 'All'
              final isSelected = (selectedCategory ?? 'All') == category.name;

              return GestureDetector(
                onTap: () {
                  selectedCategoryNotifier.value = category.name;
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 70,
                        width: 70,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? EColorConstants.primaryColor.withOpacity(0.15)
                              : (dark ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(
                                  color: EColorConstants.primaryColor, width: 2)
                              : Border.all(color: Colors.transparent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: category.id == 'all'
                            ? Icon(
                                Iconsax.grid_5,
                                color: isSelected
                                    ? EColorConstants.primaryColor
                                    : Colors.grey[600],
                                size: 28,
                              )
                            : Image.asset(
                                category.imageUrl ?? '',
                                fit: BoxFit.contain,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name ?? '',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isSelected
                                  ? EColorConstants.primaryColor
                                  : (dark ? Colors.white : Colors.black),
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
