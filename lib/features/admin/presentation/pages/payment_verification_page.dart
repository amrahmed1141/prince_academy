import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/features/admin/data/models/payment_verification_data.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_repository.dart';
import 'package:prince_academy/features/admin/presentation/widgets/coach_avatar.dart';
import 'package:prince_academy/features/admin/presentation/widgets/payment_screenshot_viewer.dart';
import 'package:prince_academy/features/admin/presentation/widgets/reject_payment_dialog.dart';

class PaymentVerificationPage extends StatefulWidget {
  const PaymentVerificationPage({
    super.key,
    required this.data,
    this.onVerified,
  });

  final PaymentVerificationData data;
  final VoidCallback? onVerified;

  @override
  State<PaymentVerificationPage> createState() =>
      _PaymentVerificationPageState();
}

class _PaymentVerificationPageState extends State<PaymentVerificationPage> {
  bool _isVerifying = false;
  bool _isRejecting = false;

  PaymentVerificationData get data => widget.data;

  Future<void> _verify() async {
    if (_isVerifying || _isRejecting) return;
    setState(() => _isVerifying = true);

    try {
      await sl<AdminRepository>().verifyPayment(data.bookingId);
      if (!mounted) return;
      widget.onVerified?.call();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified successfully'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _reject() async {
    if (_isRejecting || _isVerifying || !data.isInstaPay) return;
    final reason = await RejectPaymentDialog.show(context);
    if (reason == null || !mounted) return;

    setState(() => _isRejecting = true);
    try {
      await sl<AdminRepository>().rejectPayment(data.bookingId, reason);
      if (!mounted) return;
      widget.onVerified?.call();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment rejected'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRejecting = false);
    }
  }

  void _viewScreenshot() {
    final url = data.paymentScreenshotUrl;
    if (url == null || url.isEmpty) return;
    PaymentScreenshotViewer.show(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = SubscriptionFormatters.formatDays(data.selectedDays);
    final time = data.selectedTime?.trim().isNotEmpty == true
        ? data.selectedTime!
        : 'Time not set';
    final methodLabel = data.isCash ? 'Cash' : 'InstaPay';
    final bookedAgo = data.createdAt != null
        ? SubscriptionFormatters.formatTimeAgo(data.createdAt!)
        : 'Recently';
    final deadline = data.paymentDeadline != null
        ? DateFormat('MMM d, yyyy').format(data.paymentDeadline!.toLocal())
        : null;
    final memberName = data.memberName?.trim().isNotEmpty == true
        ? data.memberName!
        : 'Member';

    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        backgroundColor: EColorConstants.authFieldBackground,
        elevation: 0,
        foregroundColor: EColorConstants.authTextDarkBrown,
        title: const Text(
          'Payment Verification',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF9A825).withOpacity(0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('👤', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      memberName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        color: EColorConstants.authTextDarkBrown,
                      ),
                    ),
                  ),
                  if (data.memberPhone != null && data.memberPhone!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.call,
                          size: 14,
                          color: EColorConstants.authPlaceholderGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.memberPhone!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: EColorConstants.authPlaceholderGray,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoachAvatar(
                    coachName: data.coachName,
                    photoUrl: data.coachPhoto,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoLine(
                          icon: Iconsax.user_octagon,
                          text:
                              'Coach: ${data.coachName}${data.coachSpecialty != null ? ' · ${data.coachSpecialty}' : ''}',
                        ),
                        if (data.branchName != null &&
                            data.branchName!.isNotEmpty)
                          _InfoLine(
                            icon: Iconsax.location,
                            text: 'Branch: ${data.branchName}',
                          ),
                        _InfoLine(
                          icon: Iconsax.calendar,
                          text: 'Days: $schedule · $time',
                        ),
                        _InfoLine(
                          icon: Iconsax.wallet_3,
                          text:
                              'Amount: ${data.totalPrice.toStringAsFixed(0)} EGP',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: EColorConstants.authPlaceholderGray,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: data.isCash ? Iconsax.money : Iconsax.mobile,
                text: 'Method: $methodLabel',
              ),
              _InfoLine(icon: Iconsax.clock, text: 'Booked: $bookedAgo'),
              if (deadline != null)
                _InfoLine(
                  icon: Iconsax.timer_1,
                  text: 'Deadline: $deadline',
                  color: const Color(0xFFF9A825),
                ),
              if (data.isInstaPay && data.paymentReference != null)
                _InfoLine(
                  icon: Iconsax.key,
                  text: 'Reference: ${data.paymentReference}',
                ),
              if (data.isInstaPay &&
                  data.paymentScreenshotUrl != null &&
                  data.paymentScreenshotUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _viewScreenshot,
                  icon: const Icon(Iconsax.gallery, size: 18),
                  label: const Text('View Screenshot'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EColorConstants.primaryColor,
                    side: const BorderSide(color: EColorConstants.authFieldBorder),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (data.isCash)
                _ActionButton(
                  label: 'Confirm Payment Received',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF2E7D32),
                  isLoading: _isVerifying,
                  onPressed: _verify,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Verify Payment',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF2E7D32),
                        isLoading: _isVerifying,
                        onPressed: _verify,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        icon: Icons.close,
                        color: const Color(0xFFD32F2F),
                        isLoading: _isRejecting,
                        onPressed: _reject,
                        outlined: true,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.color,
  });

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? EColorConstants.authPlaceholderGray,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color ?? EColorConstants.authTextDarkBrown,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final iconWidget = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? color : Colors.white,
            ),
          )
        : Icon(icon, size: 18);

    if (outlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: iconWidget,
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: iconWidget,
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
