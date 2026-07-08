import 'package:flutter/material.dart';
import 'package:prince_academy/core/constants/app_colors.dart';

class RejectPaymentDialog extends StatefulWidget {
  const RejectPaymentDialog({super.key});

  static const presetReasons = [
    'Screenshot unclear',
    'Wrong amount',
    'Reference mismatch',
    'Other',
  ];

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const RejectPaymentDialog(),
    );
  }

  @override
  State<RejectPaymentDialog> createState() => _RejectPaymentDialogState();
}

class _RejectPaymentDialogState extends State<RejectPaymentDialog> {
  String? _selectedReason;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String? get _resolvedReason {
    if (_selectedReason == null) return null;
    if (_selectedReason == 'Other') {
      final text = _customController.text.trim();
      return text.isEmpty ? null : text;
    }
    return _selectedReason;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Reject Payment',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you rejecting this payment?',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            ...RejectPaymentDialog.presetReasons.map((reason) {
              return RadioListTile<String>(
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) => setState(() => _selectedReason = value),
                title: Text(
                  reason,
                  style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                ),
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _resolvedReason == null
                ? null
                : () => Navigator.pop(context, _resolvedReason),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Confirm Rejection',
              style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            ),
          ),
        ),
      ],
    );
  }
}
