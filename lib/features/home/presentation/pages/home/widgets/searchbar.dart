import 'package:flutter/material.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';

/// Legacy alias — prefer [AppSearchBar] / [CubitSearchBar] directly.
class HomeSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const HomeSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.hintText = 'Search For Coaches, Classes, or Events',
  });

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      controller: controller,
      onChanged: onChanged,
      onClear: onChanged == null
          ? null
          : () {
              controller?.clear();
              onChanged?.call('');
            },
      hintText: hintText,
      variant: AppSearchBarVariant.elevated,
    );
  }
}
