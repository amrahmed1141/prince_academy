import 'dart:io';
import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/colors.dart';

class CoachCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String sessionCount;
  final String? rating;
  final String? imagePath;

  const CoachCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.sessionCount,
    this.rating,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .join()
        .toUpperCase();
    
    final displayInitials = initials.length >= 2 
        ? initials.substring(0, 2) 
        : initials.isNotEmpty ? initials : name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: EColorConstants.authCardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EColorConstants.authSoftGold,
              shape: BoxShape.circle,
              image: imagePath != null && imagePath!.isNotEmpty
                  ? DecorationImage(
                      image: _getImageProvider(imagePath!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagePath == null || imagePath!.isEmpty
                ? Center(
                    child: Text(
                      displayInitials,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authCardWhite,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  specialty,
                  style: const TextStyle(
                    fontSize: 12,
                    color: EColorConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '$sessionCount sessions',
                      style: const TextStyle(
                        fontSize: 11,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (rating != null && rating!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: EColorConstants.authFieldBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: EColorConstants.authFieldBorder),
              ),
              child: Text(
                rating!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EColorConstants.primaryColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }
}
