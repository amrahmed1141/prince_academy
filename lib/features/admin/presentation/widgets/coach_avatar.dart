import 'package:flutter/material.dart';
import 'package:prince_academy/core/cache/image_cache.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/coach_photo_helper.dart';
import 'package:shimmer/shimmer.dart';

class CoachAvatar extends StatelessWidget {
  final String? photoUrl;
  final String coachName;
  final double size;

  const CoachAvatar({
    super.key,
    this.photoUrl,
    required this.coachName,
    this.size = 48,
  });

  String? get _resolvedUrl => CoachPhotoHelper.normalize(photoUrl);

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    if (url == null) {
      return _InitialsAvatar(name: coachName, size: size);
    }

    final localFile = CoachPhotoHelper.localFile(url);
    if (localFile != null) {
      return ClipOval(
        child: Image.file(
          localFile,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _InitialsAvatar(name: coachName, size: size),
        ),
      );
    }

    final cacheSize = (size * 3).round().clamp(96, 512);

    return ClipOval(
      child: Image(
        image: ResizeImage(
          AppImageCache.provider(url),
          width: cacheSize,
          height: cacheSize,
        ),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _ShimmerAvatar(size: size);
        },
        errorBuilder: (_, __, ___) {
          return _InitialsAvatar(name: coachName, size: size);
        },
      ),
    );
  }
}

class _ShimmerAvatar extends StatelessWidget {
  const _ShimmerAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _InitialsAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join();

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: EColorConstants.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.isEmpty ? '?' : initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
