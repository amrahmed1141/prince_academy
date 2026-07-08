import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/helpers/payment_reference_helper.dart';
import 'package:prince_academy/core/helpers/session_schedule_helper.dart';
import 'package:prince_academy/features/booking/data/models/booking_model.dart';

class InstaPayPaymentSheet extends StatefulWidget {
  final BookingModel booking;
  final String sessionTime;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onConfirmPayment;
  final Future<void> Function(File file) onUploadScreenshot;
  final bool isConfirming;

  const InstaPayPaymentSheet({
    super.key,
    required this.booking,
    required this.sessionTime,
    required this.startDate,
    required this.endDate,
    required this.onConfirmPayment,
    required this.onUploadScreenshot,
    this.isConfirming = false,
  });

  static Future<void> show(
    BuildContext context, {
    required BookingModel booking,
    required String sessionTime,
    required DateTime startDate,
    required DateTime endDate,
    required VoidCallback onConfirmPayment,
    required Future<void> Function(File file) onUploadScreenshot,
    bool isConfirming = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InstaPayPaymentSheet(
        booking: booking,
        sessionTime: sessionTime,
        startDate: startDate,
        endDate: endDate,
        onConfirmPayment: onConfirmPayment,
        onUploadScreenshot: onUploadScreenshot,
        isConfirming: isConfirming,
      ),
    );
  }

  @override
  State<InstaPayPaymentSheet> createState() => _InstaPayPaymentSheetState();
}

class _InstaPayPaymentSheetState extends State<InstaPayPaymentSheet> {
  File? _screenshot;
  bool _uploading = false;
  bool _uploadComplete = false;
  String? _uploadError;

  String get _reference =>
      widget.booking.paymentReference ??
      PaymentReferenceHelper.generate(
        coachName: widget.booking.coachName ?? 'Coach',
        sessionTime: widget.sessionTime,
        startDate: widget.startDate,
      );

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _screenshot = file;
      _uploading = true;
      _uploadComplete = false;
      _uploadError = null;
    });

    try {
      await widget.onUploadScreenshot(file);
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadComplete = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadComplete = false;
        _uploadError = 'Upload failed. Please try again.';
      });
    }
  }

  Future<void> _copyReference() async {
    await Clipboard.setData(ClipboardData(text: _reference));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final period = SessionScheduleHelper.formatPeriod(
      widget.startDate,
      widget.endDate,
    );

    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(context).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Complete Your Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Subscription: $period',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount: ${widget.booking.totalPrice.toStringAsFixed(2)} EGP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  '── Transfer via InstaPay ──',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EColorConstants.authPlaceholderGray,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Name: ${PaymentReferenceHelper.instapayAccountName}',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              Text(
                'Number: ${PaymentReferenceHelper.instapayAccountNumber}',
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 20),
              const Text(
                '── Reference (required) ──',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _reference,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _copyReference,
                      child: const Text('Copy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickScreenshot,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_outlined),
                label: Text(
                  _uploading
                      ? 'Uploading screenshot...'
                      : _uploadComplete
                          ? 'Screenshot uploaded ✓'
                          : 'Upload Screenshot',
                ),
              ),
              if (_uploadError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _uploadError!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.isConfirming ||
                          _uploading ||
                          !_uploadComplete
                      ? null
                      : widget.onConfirmPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColorConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: widget.isConfirming
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "I've Completed Payment",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
