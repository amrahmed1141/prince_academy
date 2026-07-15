import 'dart:async';
import 'dart:ui' as ui;

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prince_academy/core/constants/colors.dart';

/// Branded pull-to-refresh using a frame-controlled Canva GIF.
///
/// [Image.asset] cannot reliably restart play-once GIFs (codec cache).
/// Frames are streamed manually so every pull starts at frame 0.
class BrandedPullToRefresh extends StatelessWidget {
  const BrandedPullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.animationAsset = AppRefreshAssets.pullToRefreshGif,
    this.displacement = 140,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final String animationAsset;
  final double displacement;

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      offsetToArmed: displacement,
      builder: (context, child, controller) {
        return _BrandedRefreshBody(
          controller: controller,
          animationAsset: animationAsset,
          displacement: displacement,
          child: child,
        );
      },
      child: child,
    );
  }
}

class AppRefreshAssets {
  static const pullToRefreshGif = 'assets/animations/pull_refresh.gif';
  static const logoFallback = 'assets/icons/logo.png';
}

class _BrandedRefreshBody extends StatefulWidget {
  const _BrandedRefreshBody({
    required this.controller,
    required this.animationAsset,
    required this.displacement,
    required this.child,
  });

  final IndicatorController controller;
  final String animationAsset;
  final double displacement;
  final Widget child;

  @override
  State<_BrandedRefreshBody> createState() => _BrandedRefreshBodyState();
}

class _BrandedRefreshBodyState extends State<_BrandedRefreshBody> {
  int _sessionId = 0;
  bool _wasActive = false;

  IndicatorController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerTick);
  }

  @override
  void didUpdateWidget(covariant _BrandedRefreshBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerTick);
      widget.controller.addListener(_onControllerTick);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    super.dispose();
  }

  bool get _isActive {
    final state = _controller.state;
    return _controller.value > 0.02 ||
        state.isDragging ||
        state.isArmed ||
        state.isLoading ||
        state.isComplete;
  }

  void _onControllerTick() {
    final active = _isActive;
    if (active && !_wasActive) {
      setState(() => _sessionId++);
    }
    _wasActive = active;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value.clamp(0.0, 1.25);
        final reveal = Curves.easeOut.transform(t.clamp(0.0, 1.0));
        final offsetY = reveal * widget.displacement;
        final active = t > 0.02;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: Offset(0, offsetY),
              child: widget.child,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: widget.displacement,
              child: IgnorePointer(
                child: Opacity(
                  opacity: active ? reveal : 0,
                  child: active
                      ? _ControlledGif(
                          key: ValueKey<int>(_sessionId),
                          assetPath: widget.animationAsset,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Streams GIF frames from a fresh codec so playback always starts at frame 0.
class _ControlledGif extends StatefulWidget {
  const _ControlledGif({
    super.key,
    required this.assetPath,
  });

  final String assetPath;

  @override
  State<_ControlledGif> createState() => _ControlledGifState();
}

class _ControlledGifState extends State<_ControlledGif> {
  static final Map<String, Uint8List> _bytesCache = {};

  ui.Image? _frame;
  int _generation = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _generation++;
    _frame?.dispose();
    _frame = null;
    super.dispose();
  }

  Future<Uint8List> _bytes() async {
    final cached = _bytesCache[widget.assetPath];
    if (cached != null) return cached;
    final data = await rootBundle.load(widget.assetPath);
    final bytes = data.buffer.asUint8List();
    _bytesCache[widget.assetPath] = bytes;
    return bytes;
  }

  Future<void> _run() async {
    final gen = ++_generation;
    try {
      final bytes = await _bytes();
      if (!mounted || gen != _generation) return;

      // Keep looping with a brand-new codec each cycle (frame 0 → end).
      while (mounted && gen == _generation) {
        final codec = await ui.instantiateImageCodec(bytes);
        final count = codec.frameCount;

        for (var i = 0; i < count; i++) {
          if (!mounted || gen != _generation) return;

          final info = await codec.getNextFrame();
          if (!mounted || gen != _generation) {
            info.image.dispose();
            return;
          }

          final previous = _frame;
          setState(() {
            _frame = info.image;
            _failed = false;
          });
          previous?.dispose();

          final delayMs = info.duration.inMilliseconds < 20
              ? 40
              : info.duration.inMilliseconds;
          await Future<void>.delayed(Duration(milliseconds: delayMs));
          if (!mounted || gen != _generation) return;
        }
      }
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: _LogoFallback());
    final frame = _frame;
    if (frame == null) return const SizedBox.expand();

    return SizedBox.expand(
      child: RawImage(
        image: frame,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
      ),
    );
  }
}

class _LogoFallback extends StatefulWidget {
  const _LogoFallback();

  @override
  State<_LogoFallback> createState() => _LogoFallbackState();
}

class _LogoFallbackState extends State<_LogoFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _spin,
      child: Container(
        width: 56,
        height: 56,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: EColorConstants.primaryColor.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          AppRefreshAssets.logoFallback,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
