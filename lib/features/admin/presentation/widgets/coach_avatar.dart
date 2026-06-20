import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';

class CoachAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;

  const CoachAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final resolved = CoachPhotoHelper.resolve(photoUrl);

    if (resolved == null) {
      return _FallbackAvatar(initial: initial, radius: radius);
    }

    if (CoachPhotoHelper.isAssetPath(resolved)) {
      return _ClipAvatar(
        radius: radius,
        child: Image.asset(
          resolved,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _FallbackAvatar(initial: initial, radius: radius),
        ),
      );
    }

    if (CoachPhotoHelper.isLocalFile(resolved)) {
      return _ClipAvatar(
        radius: radius,
        child: Image.file(
          File(resolved),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _FallbackAvatar(initial: initial, radius: radius),
        ),
      );
    }

    return _NetworkCoachAvatar(
      url: resolved,
      source: photoUrl,
      radius: radius,
      initial: initial,
    );
  }
}

class _NetworkCoachAvatar extends StatefulWidget {
  const _NetworkCoachAvatar({
    required this.url,
    required this.source,
    required this.radius,
    required this.initial,
  });

  final String url;
  final String? source;
  final double radius;
  final String initial;

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
      return _FallbackAvatar(initial: widget.initial, radius: widget.radius);
    }

    return _ClipAvatar(
      radius: widget.radius,
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
          return _FallbackAvatar(initial: widget.initial, radius: widget.radius);
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
  });

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: child,
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.initial,
    required this.radius,
  });

  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.black87,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
