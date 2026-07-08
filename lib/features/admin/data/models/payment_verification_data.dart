import 'package:prince_academy/features/admin/data/models/admin_scan_profile_model.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';

class PaymentVerificationData {
  final String bookingId;
  final String? memberName;
  final String? memberPhone;
  final String coachName;
  final String? coachPhoto;
  final String? coachSpecialty;
  final String? branchName;
  final List<String> selectedDays;
  final String? selectedTime;
  final double totalPrice;
  final String paymentMethod;
  final DateTime? createdAt;
  final DateTime? paymentDeadline;
  final String? paymentReference;
  final String? paymentScreenshotUrl;

  const PaymentVerificationData({
    required this.bookingId,
    this.memberName,
    this.memberPhone,
    required this.coachName,
    this.coachPhoto,
    this.coachSpecialty,
    this.branchName,
    this.selectedDays = const [],
    this.selectedTime,
    this.totalPrice = 0,
    this.paymentMethod = 'cash',
    this.createdAt,
    this.paymentDeadline,
    this.paymentReference,
    this.paymentScreenshotUrl,
  });

  bool get isCash => paymentMethod.toLowerCase() == 'cash';

  bool get isInstaPay =>
      paymentMethod.toLowerCase() == 'instapay' ||
      paymentMethod.toLowerCase() == 'insta_pay';

  /// Days until auto-delete (cash bookings expire 3 days after creation).
  int get autoDeleteDaysRemaining {
    if (paymentDeadline != null) {
      final now = DateTime.now();
      final deadline = paymentDeadline!.toLocal();
      final today = DateTime(now.year, now.month, now.day);
      final end = DateTime(deadline.year, deadline.month, deadline.day);
      return end.difference(today).inDays.clamp(0, 999);
    }
    if (createdAt != null) {
      final elapsed = DateTime.now().difference(createdAt!).inDays;
      return (3 - elapsed).clamp(0, 3);
    }
    return 3;
  }

  factory PaymentVerificationData.fromPendingPayment(PendingPaymentModel payment) {
    return PaymentVerificationData(
      bookingId: payment.bookingId,
      memberName: payment.userName,
      memberPhone: payment.userPhone,
      coachName: payment.coachName,
      coachPhoto: payment.coachPhoto,
      coachSpecialty: payment.coachSpecialty,
      branchName: payment.branchName,
      selectedDays: payment.selectedDays,
      selectedTime: payment.selectedTime,
      totalPrice: payment.totalPrice,
      paymentMethod: payment.paymentMethod,
      createdAt: payment.createdAt,
      paymentDeadline: payment.paymentDeadline,
      paymentReference: payment.paymentReference,
      paymentScreenshotUrl: payment.paymentScreenshotUrl,
    );
  }

  factory PaymentVerificationData.fromScanProfile(AdminScanProfile profile) {
    return PaymentVerificationData(
      bookingId: profile.bookingId,
      memberName: profile.fullName,
      memberPhone: profile.phone,
      coachName: profile.coachName,
      coachPhoto: profile.coachPhoto,
      coachSpecialty: profile.coachSpecialty,
      branchName: profile.branchName,
      selectedDays: profile.selectedDays,
      selectedTime: profile.selectedTime,
      totalPrice: profile.totalPrice,
      paymentMethod: profile.paymentMethod ?? 'cash',
      createdAt: profile.createdAt,
      paymentDeadline: profile.paymentDeadline,
      paymentReference: profile.paymentReference,
      paymentScreenshotUrl: profile.paymentScreenshotUrl,
    );
  }
}
