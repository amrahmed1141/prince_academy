import 'package:flutter/material.dart';
import 'package:prince_academy/core/widgets/app_search_bar.dart';

/// Idle capsule that opens a dedicated search page on tap.
///
/// Shared chrome for member Home and admin Dashboard. List screens keep
/// [AppSearchBar] with [onChanged] for **local filtering** instead.
class LaunchSearchBar extends StatelessWidget {
  const LaunchSearchBar({
    super.key,
    required this.onTap,
    this.hintPhrases = const ['Search...'],
    this.hintText = 'Search...',
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.variant = AppSearchBarVariant.elevated,
  });

  final VoidCallback onTap;
  final List<String> hintPhrases;
  final String hintText;
  final EdgeInsetsGeometry padding;
  final AppSearchBarVariant variant;

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      readOnly: true,
      hintText: hintText,
      hintPhrases: hintPhrases,
      padding: padding,
      variant: variant,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        onTap();
      },
    );
  }
}
