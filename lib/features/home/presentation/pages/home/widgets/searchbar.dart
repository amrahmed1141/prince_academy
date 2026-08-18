import 'package:flutter/material.dart';
import 'package:prince_academy/core/widgets/launch_search_bar.dart';
import 'package:prince_academy/features/search/presentation/member_search_hints.dart';
import 'package:prince_academy/features/search/presentation/pages/global_search_page.dart';

/// Home entry point for app-wide member search.
///
/// Idle: animated hints only (no parent rebuilds).
/// Tap: opens [GlobalSearchPage]. Booking/Sessions stay local [AppSearchBar] filters.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LaunchSearchBar(
      hintPhrases: MemberSearchHints.global,
      onTap: () => openGlobalSearch(context),
    );
  }
}
