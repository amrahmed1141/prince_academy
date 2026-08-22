import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/l10n/app_strings.dart';
import 'package:prince_academy/core/search/search_cubit.dart';
import 'package:prince_academy/core/search/search_query_cubit.dart';
import 'package:prince_academy/core/widgets/animated_search_hint.dart';
import 'package:prince_academy/core/widgets/directional_icon.dart';

/// Visual styles shared across user and admin screens.
enum AppSearchBarVariant {
  /// Soft white capsule with shadow (member + shared lists).
  elevated,

  /// Bordered auth-style field (admin tracking, forms).
  outlined,
}

/// App-wide reusable search field (capsule chrome on every screen).
///
/// Pure UI — same capsule chrome on member and admin.
///
/// - **Launch** a search page: `readOnly` + `onTap` ([LaunchSearchBar]).
/// - **Filter** the current list: `onChanged` / [CubitSearchBar] (admin
///   tracking, finance, booking, sessions).
///
/// Animated idle hints stay inside this widget (via [hintPhrases]) so parent
/// screens are not rebuilt when phrases cycle.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.onTap,
    this.onBack,
    this.hintText = 'Search...',
    this.hintPhrases,
    this.variant = AppSearchBarVariant.elevated,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.showBack = false,
    this.alwaysShowClear = false,
    this.pillShape = true,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback? onBack;
  final String hintText;

  /// When set, cycles these phrases while the field is empty (local animation).
  final List<String>? hintPhrases;

  final AppSearchBarVariant variant;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;

  /// Leading chevron inside the field (active / global-search mode).
  final bool showBack;

  /// Show the clear (x) icon even when the field is empty (active mode).
  final bool alwaysShowClear;

  /// Stadium / capsule corners — default shared search-bar shape.
  final bool pillShape;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  TextEditingController? _ownedController;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusTick);
    _syncController();
    _controller.addListener(_onTextTick);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onTextTick);
      _syncController();
      _controller.addListener(_onTextTick);
    }
  }

  void _syncController() {
    if (widget.controller != null) {
      _ownedController?.dispose();
      _ownedController = null;
      _controller = widget.controller!;
    } else {
      _ownedController ??= TextEditingController();
      _controller = _ownedController!;
    }
  }

  void _onTextTick() {
    if (mounted) setState(() {});
  }

  void _onFocusTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusTick);
    _focusNode.dispose();
    _controller.removeListener(_onTextTick);
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }

  bool get _hasText => _controller.text.isNotEmpty;

  bool get _showAnimatedHint {
    final phrases = widget.hintPhrases;
    if (phrases == null || phrases.isEmpty || _hasText) return false;
    // Launch bars stay read-only; keep cycling even after tap/return.
    if (widget.readOnly) return true;
    return !_focusNode.hasFocus;
  }

  bool get _showClear {
    final canClear =
        widget.onClear != null || widget.onChanged != null || widget.alwaysShowClear;
    if (!canClear) return false;
    if (widget.alwaysShowClear) return true;
    return _hasText;
  }

  double get _radius => widget.pillShape || widget.showBack ? 28 : 16;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hintText =
        widget.hintText == 'Search...' ? s.search : widget.hintText;
    final hintPrefix = s.searchHintPrefix;

    return Padding(
      padding: widget.padding,
      child: switch (widget.variant) {
        AppSearchBarVariant.elevated => _ElevatedField(
            controller: _controller,
            focusNode: _focusNode,
            hintText: hintText,
            hintPrefix: hintPrefix,
            showAnimatedHint: _showAnimatedHint,
            hintPhrases: widget.hintPhrases,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            showBack: widget.showBack,
            showClear: _showClear,
            radius: _radius,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            onClear: _handleClear,
            onBack: _handleBack,
          ),
        AppSearchBarVariant.outlined => _OutlinedField(
            controller: _controller,
            focusNode: _focusNode,
            hintText: hintText,
            hintPrefix: hintPrefix,
            showAnimatedHint: _showAnimatedHint,
            hintPhrases: widget.hintPhrases,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            readOnly: widget.readOnly,
            showBack: widget.showBack,
            showClear: _showClear,
            radius: _radius,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            onClear: _handleClear,
            onBack: _handleBack,
          ),
      },
    );
  }
}

/// Convenience binder: reads [SearchCubit] from context and drives filtration.
class CubitSearchBar<T> extends StatelessWidget {
  const CubitSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.hintPhrases,
    this.variant = AppSearchBarVariant.elevated,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.controller,
    this.autofocus = false,
  });

  final String hintText;
  final List<String>? hintPhrases;
  final AppSearchBarVariant variant;
  final EdgeInsetsGeometry padding;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit<T>>();

    return AppSearchBar(
      controller: controller,
      hintText: hintText,
      hintPhrases: hintPhrases,
      variant: variant,
      padding: padding,
      autofocus: autofocus,
      onChanged: cubit.search,
      onClear: cubit.clear,
    );
  }
}

/// Binds [AppSearchBar] to a [SearchQueryCubit] (query-only).
class QuerySearchBar extends StatelessWidget {
  const QuerySearchBar({
    super.key,
    this.hintText = 'Search...',
    this.hintPhrases,
    this.variant = AppSearchBarVariant.elevated,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.controller,
    this.autofocus = false,
  });

  final String hintText;
  final List<String>? hintPhrases;
  final AppSearchBarVariant variant;
  final EdgeInsetsGeometry padding;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchQueryCubit>();

    return AppSearchBar(
      controller: controller,
      hintText: hintText,
      hintPhrases: hintPhrases,
      variant: variant,
      padding: padding,
      autofocus: autofocus,
      onChanged: cubit.search,
      onClear: cubit.clear,
    );
  }
}

class _ElevatedField extends StatelessWidget {
  const _ElevatedField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.hintPrefix,
    required this.showAnimatedHint,
    required this.hintPhrases,
    required this.enabled,
    required this.autofocus,
    required this.readOnly,
    required this.showBack,
    required this.showClear,
    required this.radius,
    required this.onChanged,
    required this.onSubmitted,
    required this.onTap,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String hintPrefix;
  final bool showAnimatedHint;
  final List<String>? hintPhrases;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final bool showBack;
  final bool showClear;
  final double radius;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _SearchFieldShell(
        controller: controller,
        focusNode: focusNode,
        hintText: hintText,
        hintPrefix: hintPrefix,
        showAnimatedHint: showAnimatedHint,
        hintPhrases: hintPhrases,
        enabled: enabled,
        autofocus: autofocus,
        readOnly: readOnly,
        showBack: showBack,
        showClear: showClear,
        radius: radius,
        fillColor: Colors.white,
        borderColor: EColorConstants.authTextDarkBrown,
        focusedBorderColor: EColorConstants.primaryColor,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        onClear: onClear,
        onBack: onBack,
      ),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.hintPrefix,
    required this.showAnimatedHint,
    required this.hintPhrases,
    required this.enabled,
    required this.autofocus,
    required this.readOnly,
    required this.showBack,
    required this.showClear,
    required this.radius,
    required this.onChanged,
    required this.onSubmitted,
    required this.onTap,
    required this.onClear,
    required this.onBack,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String hintPrefix;
  final bool showAnimatedHint;
  final List<String>? hintPhrases;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final bool showBack;
  final bool showClear;
  final double radius;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _SearchFieldShell(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      hintPrefix: hintPrefix,
      showAnimatedHint: showAnimatedHint,
      hintPhrases: hintPhrases,
      enabled: enabled,
      autofocus: autofocus,
      readOnly: readOnly,
      showBack: showBack,
      showClear: showClear,
      radius: radius,
      fillColor: EColorConstants.authCardWhite,
      borderColor: EColorConstants.authFieldBorder,
      focusedBorderColor: EColorConstants.primaryColor,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      onClear: onClear,
      onBack: onBack,
      textStyle: const TextStyle(
        fontSize: 14,
        fontFamily: 'Poppins',
        color: EColorConstants.authTextDarkBrown,
      ),
      hintStyle: const TextStyle(
        fontSize: 13,
        color: EColorConstants.authPlaceholderGray,
        fontFamily: 'Poppins',
      ),
    );
  }
}

class _SearchFieldShell extends StatelessWidget {
  const _SearchFieldShell({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.hintPrefix,
    required this.showAnimatedHint,
    required this.hintPhrases,
    required this.enabled,
    required this.autofocus,
    required this.readOnly,
    required this.showBack,
    required this.showClear,
    required this.radius,
    required this.fillColor,
    required this.borderColor,
    required this.focusedBorderColor,
    required this.onChanged,
    required this.onSubmitted,
    required this.onTap,
    required this.onClear,
    required this.onBack,
    this.textStyle,
    this.hintStyle,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String hintPrefix;
  final bool showAnimatedHint;
  final List<String>? hintPhrases;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final bool showBack;
  final bool showClear;
  final double radius;
  final Color fillColor;
  final Color borderColor;
  final Color focusedBorderColor;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  @override
  Widget build(BuildContext context) {
    final resolvedHintStyle = hintStyle ??
        const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontFamily: 'Poppins',
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            autofocus: autofocus,
            readOnly: readOnly,
            canRequestFocus: !readOnly,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: onTap,
            textInputAction: TextInputAction.search,
            style: textStyle,
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor,
              hoverColor: Colors.transparent,
              prefixIcon: showBack
                  ? IconButton(
                      onPressed: onBack,
                      tooltip: 'Back',
                      icon: Icon(
                        DirectionalIcons.back(context),
                        color: EColorConstants.authTextDarkBrown,
                        size: 22,
                        textDirection: TextDirection.ltr,
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsetsDirectional.only(start: 8),
                      child: Icon(
                        Iconsax.search_normal,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
              prefixIconConstraints: showBack
                  ? null
                  : const BoxConstraints(minWidth: 48, minHeight: 48),
              suffixIcon: showClear
                  ? IconButton(
                      onPressed: onClear,
                      tooltip: 'Clear',
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    )
                  : null,
              hintText: showAnimatedHint ? null : hintText,
              hintStyle: resolvedHintStyle,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: focusedBorderColor, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(radius),
                borderSide: BorderSide(color: borderColor, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (showAnimatedHint && hintPhrases != null)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: showBack ? 52 : 48,
                  end: showClear ? 48 : 16,
                ),
                child: IgnorePointer(
                  child: AnimatedSearchHint(
                    prefix: hintPrefix,
                    phrases: hintPhrases!,
                    style: resolvedHintStyle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
