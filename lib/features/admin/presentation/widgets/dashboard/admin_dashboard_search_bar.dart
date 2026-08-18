import 'package:flutter/material.dart';
import 'package:prince_academy/core/widgets/launch_search_bar.dart';
import 'package:prince_academy/features/admin/data/admin_search_index.dart';
import 'package:prince_academy/features/admin/presentation/pages/admin_search_page.dart';

/// Dashboard entry for admin destination search (not list-row filtering).
class AdminDashboardSearchBar extends StatelessWidget {
  const AdminDashboardSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LaunchSearchBar(
      hintPhrases: AdminSearchHints.pages,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      onTap: () => openAdminSearch(context),
    );
  }
}
