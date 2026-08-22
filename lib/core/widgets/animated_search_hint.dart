import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Cycles the suffix after a static [prefix] with a local fade/slide —
/// never rebuilds ancestors.
class AnimatedSearchHint extends StatefulWidget {
  const AnimatedSearchHint({
    super.key,
    this.prefix = 'Search ',
    this.phrases = const [
      'coaches',
      "today's session",
      'booking',
      'category',
    ],
    this.style,
    this.interval = const Duration(milliseconds: 2400),
    this.animationDuration = const Duration(milliseconds: 320),
  });

  /// Stays on screen; only [phrases] animate.
  final String prefix;
  final List<String> phrases;
  final TextStyle? style;
  final Duration interval;
  final Duration animationDuration;

  @override
  State<AnimatedSearchHint> createState() => _AnimatedSearchHintState();
}

class _AnimatedSearchHintState extends State<AnimatedSearchHint>
    with SingleTickerProviderStateMixin {
  AnimationController? _cycle;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _armCycle();
  }

  @override
  void didUpdateWidget(covariant AnimatedSearchHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phrases != widget.phrases ||
        oldWidget.prefix != widget.prefix ||
        oldWidget.interval != widget.interval) {
      _index = 0;
      _armCycle();
    }
  }

  void _armCycle() {
    _cycle?.dispose();
    _cycle = null;
    if (widget.phrases.length < 2) return;
    final controller = AnimationController(
      vsync: this,
      duration: widget.interval,
    );
    _cycle = controller;
    controller.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      setState(() => _index = (_index + 1) % widget.phrases.length);
      controller.forward(from: 0);
    });
    controller.forward();
  }

  @override
  void dispose() {
    _cycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phrases.isEmpty) return const SizedBox.shrink();

    final style = widget.style ??
        const TextStyle(
          fontSize: 14,
          color: EColorConstants.authPlaceholderGray,
          fontFamily: 'Poppins',
        );

    final phrase = widget.phrases[_index % widget.phrases.length];
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            widget.prefix,
            maxLines: 1,
            style: style,
          ),
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: widget.animationDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final begin = Offset(0, isRtl ? -0.35 : 0.35);
                  final offset = Tween<Offset>(
                    begin: begin,
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offset, child: child),
                  );
                },
                child: Text(
                  key: ValueKey<String>('${widget.prefix}$phrase'),
                  phrase,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: style,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
