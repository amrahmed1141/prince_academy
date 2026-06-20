import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:prince_academy/core/constants/colors.dart';

class MemberQrDisplay extends StatelessWidget {
  final String qrCode;
  final double size;
  final bool showCodeLabel;
  final String? hint;

  const MemberQrDisplay({
    super.key,
    required this.qrCode,
    this.size = 180,
    this.showCodeLabel = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: QrImageView(
            data: qrCode,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(color: EColorConstants.primaryColor),
            dataModuleStyle: const QrDataModuleStyle(
              color: EColorConstants.authTextDarkBrown,
            ),
          ),
        ),
        if (showCodeLabel) ...[
          const SizedBox(height: 10),
          Text(
            qrCode,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
              letterSpacing: 0.2,
            ),
          ),
        ],
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: EColorConstants.authPlaceholderGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ],
    );
  }
}
