import 'package:flutter/material.dart';
import 'package:prince_academy/features/home/data/models/catgeory_model.dart';
import 'package:prince_academy/core/constants/colors.dart';

class CategoryList extends StatelessWidget {
  final ValueNotifier<String?> selectedCategoryNotifier;

  const CategoryList({
    super.key,
    required this.selectedCategoryNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final List<CategoryModel> displayCategories = [
      CategoryModel(id: 'all', name: 'All'),
      ...categories,
    ];

    return SizedBox(
      height: 44,
      child: ValueListenableBuilder<String?>(
        valueListenable: selectedCategoryNotifier,
        builder: (context, selectedCategory, _) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            primary: false,
            itemCount: displayCategories.length,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            clipBehavior: Clip.none,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = displayCategories[index];
              final isSelected = (selectedCategory ?? 'All') == category.name;

              return GestureDetector(
                onTap: () {
                  selectedCategoryNotifier.value = category.name;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EColorConstants.primaryColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: Colors.grey.shade300,
                          ),
                  ),
                  child: Text(
                    category.name ?? '',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF2B2B2B),
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
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
