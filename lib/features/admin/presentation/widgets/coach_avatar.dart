import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

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

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: EColorConstants.authSoftGold,
        backgroundImage: _imageProvider(photoUrl!),
      );
    }

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

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('assets/')) return AssetImage(path);
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }
}
