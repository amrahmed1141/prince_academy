import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Hide-on-scroll AppBar + search bar.
///
/// Scroll down to tuck it away; scroll up and it snaps back
/// ([SliverAppBar] floating + snap).
class ScrollAwaySearchHeader extends StatelessWidget {
  const ScrollAwaySearchHeader({
    super.key,
    required this.title,
    required this.searchBar,
    this.leading,
    this.automaticallyImplyLeading,
    this.backgroundColor,
    this.searchExtent = 72,
    this.toolbarHeight = kToolbarHeight,
    this.titleSpacing,
    this.primary = true,
  });

  final Widget title;
  final Widget searchBar;
  final Widget? leading;
  final bool? automaticallyImplyLeading;
  final Color? backgroundColor;
  final double searchExtent;
  final double toolbarHeight;
  final double? titleSpacing;

  /// Set false when the scroll view already sits inside [SafeArea].
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? EColorConstants.authFieldBackground;

    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      primary: primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      leading: leading,
      automaticallyImplyLeading:
          automaticallyImplyLeading ?? leading != null,
      titleSpacing: titleSpacing ?? (leading == null ? 20 : 0),
      centerTitle: false,
      title: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: EColorConstants.authTextDarkBrown,
          fontFamily: 'Poppins',
        ),
        child: title,
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(searchExtent),
        child: searchBar,
      ),
    );
  }
}
