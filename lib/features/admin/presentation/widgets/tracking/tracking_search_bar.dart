import 'package:flutter/material.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';

/// Legacy alias — prefer [AppSearchBar] with [AppSearchBarVariant.outlined].
class TrackingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const TrackingSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      controller: controller,
      onChanged: onChanged,
      onClear: onClear ??
          () {
            controller.clear();
            onChanged('');
          },
      hintText: 'Search by name or phone...',
      variant: AppSearchBarVariant.outlined,
      padding: EdgeInsets.zero,
    );
  }
}
