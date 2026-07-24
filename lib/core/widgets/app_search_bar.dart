import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/search/search_cubit.dart';
import 'package:prince_academy/core/search/search_query_cubit.dart';

/// Visual styles shared across user and admin screens.
enum AppSearchBarVariant {
  /// Soft white field with shadow (home / coaches / user lists).
  elevated,

  /// Bordered auth-style field (admin tracking, forms).
  outlined,
}

/// App-wide reusable search field.
///
/// Pure UI — wire [onChanged] / [onClear] yourself, or use [CubitSearchBar]
/// when a [SearchCubit] is already provided above the tree.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.hintText = 'Search...',
    this.variant = AppSearchBarVariant.elevated,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final AppSearchBarVariant variant;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final bool autofocus;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  TextEditingController? _ownedController;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _controller.removeListener(_onTextTick);
    _ownedController?.dispose();
    super.dispose();
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    final showClear = hasText && (widget.onClear != null || widget.onChanged != null);

    return Padding(
      padding: widget.padding,
      child: switch (widget.variant) {
        AppSearchBarVariant.elevated => _ElevatedField(
            controller: _controller,
            hintText: widget.hintText,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            showClear: showClear,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onClear: _handleClear,
          ),
        AppSearchBarVariant.outlined => _OutlinedField(
            controller: _controller,
            hintText: widget.hintText,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            showClear: showClear,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onClear: _handleClear,
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
    this.variant = AppSearchBarVariant.elevated,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.controller,
    this.autofocus = false,
  });

  final String hintText;
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
    this.variant = AppSearchBarVariant.elevated,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.controller,
    this.autofocus = false,
  });

  final String hintText;
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
    required this.hintText,
    required this.enabled,
    required this.autofocus,
    required this.showClear,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final bool autofocus;
  final bool showClear;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 16, right: 12),
            child: const Icon(
              Iconsax.search_normal,
              color: Colors.grey,
              size: 20,
            ),
          ),
          suffixIcon: showClear
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                )
              : null,
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: EColorConstants.authTextDarkBrown,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: EColorConstants.primaryColor,
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: EColorConstants.authTextDarkBrown,
              width: 1,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  const _OutlinedField({
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.autofocus,
    required this.showClear,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final bool autofocus;
  final bool showClear;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 14,
        fontFamily: 'Poppins',
        color: EColorConstants.authTextDarkBrown,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: EColorConstants.authCardWhite,
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: EColorConstants.authPlaceholderGray,
          fontFamily: 'Poppins',
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: EColorConstants.authPlaceholderGray,
          size: 20,
        ),
        suffixIcon: showClear
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: EColorConstants.authPlaceholderGray,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EColorConstants.authFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EColorConstants.authFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EColorConstants.primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
