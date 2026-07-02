import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_form_styles.dart';

class AdminDashedUpload extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  final bool fullWidth;

  const AdminDashedUpload({
    super.key,
    this.imagePath,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: EColorConstants.authFieldBorder,
          radius: fullWidth ? 16 : 14,
        ),
        child: Container(
          width: fullWidth ? double.infinity : 108,
          height: fullWidth ? 150 : 142,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(fullWidth ? 16 : 14),
            color: AdminFormStyles.sessionPanelFill,
            image: hasImage
                ? DecorationImage(
                    image: _imageProvider(imagePath!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: hasImage
              ? Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: EColorConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.edit_2,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.gallery,
                        size: 22,
                        color: EColorConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Upload Photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: EColorConstants.primaryColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullWidth
                          ? 'JPG · PNG · RECOMMENDED 1:1'
                          : 'JPG · PNG · WEBP',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        color: EColorConstants.authPlaceholderGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (!fullWidth) ...[
                      const Text(
                        'Recommended 1:1',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          height: 1.2,
                          color: EColorConstants.authPlaceholderGray,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
