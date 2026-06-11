import 'package:flutter/material.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_tab_selector.dart';

/// Smooth segmented tab layout using [PageView] + keep-alive pages.
class AdminTabLayout extends StatefulWidget {
  final List<String> labels;
  final List<Widget> children;

  const AdminTabLayout({
    super.key,
    required this.labels,
    required this.children,
  }) : assert(labels.length >= 1);

  @override
  AdminTabLayoutState createState() => AdminTabLayoutState();
}

class AdminTabLayoutState extends State<AdminTabLayout> {
  static const _switchDuration = Duration(milliseconds: 220);

  late final PageController _pageController;
  int _selectedIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> animateToTab(int index) async {
    if (index < 0 || index >= widget.children.length) return;
    if (_selectedIndex == index || _isAnimating) return;

    _isAnimating = true;
    setState(() => _selectedIndex = index);

    try {
      await _pageController.animateToPage(
        index,
        duration: _switchDuration,
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isAnimating = false;
    }
  }

  void _onTabTapped(int index) {
    animateToTab(index);
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminTabSelector(
          selectedIndex: _selectedIndex,
          labels: widget.labels,
          onChanged: _onTabTapped,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const PageScrollPhysics(),
            children: List.generate(widget.children.length, (index) {
              return RepaintBoundary(
                child: AdminKeepAliveTab(
                  key: PageStorageKey<String>('admin_tab_$index'),
                  child: widget.children[index],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Preserves scroll position and subtree state when swiping away.
class AdminKeepAliveTab extends StatefulWidget {
  final Widget child;

  const AdminKeepAliveTab({
    super.key,
    required this.child,
  });

  @override
  State<AdminKeepAliveTab> createState() => _AdminKeepAliveTabState();
}

class _AdminKeepAliveTabState extends State<AdminKeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
