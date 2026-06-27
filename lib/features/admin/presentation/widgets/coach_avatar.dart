import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';

class CoachAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final BorderRadiusGeometry? borderRadius;

  const CoachAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 22,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final resolved = CoachPhotoHelper.resolve(photoUrl);

    if (resolved == null) {
      return _FallbackAvatar(
        initial: initial,
        radius: radius,
        borderRadius: borderRadius,
      );
    }

    if (CoachPhotoHelper.isAssetPath(resolved)) {
      return _ClipAvatar(
        radius: radius,
        borderRadius: borderRadius,
        child: Image.asset(
          resolved,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(
            initial: initial,
            radius: radius,
            borderRadius: borderRadius,
          ),
        ),
      );
    }

    if (CoachPhotoHelper.isLocalFile(resolved)) {
      return _ClipAvatar(
        radius: radius,
        borderRadius: borderRadius,
        child: Image.file(
          File(resolved),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(
            initial: initial,
            radius: radius,
            borderRadius: borderRadius,
          ),
        ),
      );
    }

    return _NetworkCoachAvatar(
      url: resolved,
      source: photoUrl,
      radius: radius,
      initial: initial,
      borderRadius: borderRadius,
    );
  }
}

class _NetworkCoachAvatar extends StatefulWidget {
  const _NetworkCoachAvatar({
    required this.url,
    required this.source,
    required this.radius,
    required this.initial,
    this.borderRadius,
  });

  final String url;
  final String? source;
  final double radius;
  final String initial;
  final BorderRadiusGeometry? borderRadius;

  @override
  State<_NetworkCoachAvatar> createState() => _NetworkCoachAvatarState();
}

class _NetworkCoachAvatarState extends State<_NetworkCoachAvatar> {
  late String _displayUrl;
  bool _triedSignedUrl = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _displayUrl = widget.url;
  }

  @override
  void didUpdateWidget(covariant _NetworkCoachAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.source != widget.source) {
      _displayUrl = widget.url;
      _triedSignedUrl = false;
      _loadFailed = false;
    }
  }

  Future<void> _retryWithSignedUrl() async {
    if (_triedSignedUrl) return;
    _triedSignedUrl = true;

    final signedUrl = await CoachPhotoHelper.createSignedUrl(
      widget.source ?? widget.url,
    );
    if (!mounted || signedUrl == null) {
      if (mounted) setState(() => _loadFailed = true);
      return;
    }

    setState(() {
      _displayUrl = signedUrl;
      _loadFailed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return _FallbackAvatar(
        initial: widget.initial,
        radius: widget.radius,
        borderRadius: widget.borderRadius,
      );
    }

    return _ClipAvatar(
      radius: widget.radius,
      borderRadius: widget.borderRadius,
      child: Image.network(
        _displayUrl,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) {
          if (!_triedSignedUrl) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _retryWithSignedUrl();
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _loadFailed = true);
            });
          }
          return _FallbackAvatar(
            initial: widget.initial,
            radius: widget.radius,
            borderRadius: widget.borderRadius,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ColoredBox(
            color: EColorConstants.authSoftGold,
            child: Center(
              child: SizedBox(
                width: widget.radius * 0.6,
                height: widget.radius * 0.6,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: EColorConstants.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClipAvatar extends StatelessWidget {
  const _ClipAvatar({
    required this.radius,
    required this.child,
    this.borderRadius,
  });

  final double radius;
  final Widget child;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final clip = borderRadius ?? BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: clip,
      child: SizedBox(
        width: size,
        height: size,
        child: child,
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.initial,
    required this.radius,
    this.borderRadius,
  });

  final String initial;
  final double radius;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final clip = borderRadius ?? BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: clip,
      child: Container(
        width: size,
        height: size,
        color: Colors.black87,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.7,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
