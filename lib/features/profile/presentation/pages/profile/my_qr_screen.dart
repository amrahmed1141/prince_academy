import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/helpers/subscription_formatters.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/models/user_qr_profile_model.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';

class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  static const _successGreen = Color(0xFF2E7D32);
  static const _expiredRed = Color(0xFFD32F2F);

  bool _isLoading = true;
  String? _error;
  String? _qrCode;
  String _fullName = 'Member';
  List<UserQrProfile> _subscriptions = [];
  final Set<String> _renewingBookingIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    final keepVisible = silent && _qrCode != null;
    setState(() {
      if (!keepVisible) {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('You must be signed in to view your QR code.');
      }

      final results = await Future.wait([
        sl<BookingRepository>().getProfileQrCode(userId),
        sl<CoachRepository>()
            .getUserQrProfileByUserId(userId)
            .catchError((_) => <UserQrProfile>[]),
      ]);

      if (!mounted) return;

      final qrFromProfile = results[0] as String?;
      final profiles = results[1] as List<UserQrProfile>;

      final qrCode = profiles.isNotEmpty
          ? profiles.first.qrCode
          : qrFromProfile;

      if (qrCode == null || qrCode.isEmpty) {
        setState(() {
          _isLoading = false;
          if (!keepVisible) {
            _error = 'No QR profile found. Book a coach to get your QR code.';
          }
        });
        return;
      }

      final first = profiles.isNotEmpty ? profiles.first : null;
      setState(() {
        _qrCode = qrCode;
        _fullName = first?.fullName ?? 'Member';
        _subscriptions = profiles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (!keepVisible) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  Future<void> _handleRenew(UserQrProfile profile) async {
    if (_renewingBookingIds.contains(profile.bookingId)) return;

    setState(() => _renewingBookingIds.add(profile.bookingId));

    try {
      await sl<CoachRepository>().renewSubscription(profile.bookingId);
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;

      final updated = _subscriptions.firstWhere(
        (s) => s.bookingId == profile.bookingId,
        orElse: () => profile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Subscription renewed until ${SubscriptionFormatters.formatRenewedUntil(updated.subscriptionEnd)}',
          ),
          backgroundColor: _successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: _expiredRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _renewingBookingIds.remove(profile.bookingId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        title: const Text('My QR Code'),
        backgroundColor: EColorConstants.authFieldBackground,
        elevation: 0,
      ),
      body: _isLoading && _qrCode == null
          ? const QrScreenShimmer()
          : _error != null && _qrCode == null
              ? _buildErrorState()
              : RefreshIndicator(
                  color: EColorConstants.primaryColor,
                  onRefresh: () => _loadData(silent: true),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      const SizedBox(height: 8),
                      Center(child: _buildQrCard()),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: EColorConstants.authTextDarkBrown,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          _qrCode ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: EColorConstants.authPlaceholderGray,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildSubscriptionsCard(),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Show this code to the front desk',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: EColorConstants.authPlaceholderGray,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: QrImageView(
        data: _qrCode ?? '',
        size: 220,
        backgroundColor: Colors.white,
        eyeStyle: const QrEyeStyle(color: EColorConstants.primaryColor),
        dataModuleStyle: const QrDataModuleStyle(
          color: EColorConstants.authTextDarkBrown,
        ),
      ),
    );
  }

  Widget _buildSubscriptionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EColorConstants.authFieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Active Subscriptions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: EColorConstants.authTextDarkBrown,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_subscriptions.length, (index) {
            final profile = _subscriptions[index];
            final isLast = index == _subscriptions.length - 1;
            return Column(
              children: [
                _SubscriptionRow(
                  profile: profile,
                  isRenewing: _renewingBookingIds.contains(profile.bookingId),
                  onRenew: () => _handleRenew(profile),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Colors.grey.shade200),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({
    required this.profile,
    required this.isRenewing,
    required this.onRenew,
  });

  final UserQrProfile profile;
  final bool isRenewing;
  final VoidCallback onRenew;

  static const _successGreen = Color(0xFF2E7D32);
  static const _expiredRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final isActive = profile.isActive;
    final statusColor = isActive ? _successGreen : _expiredRed;
    final statusText = SubscriptionFormatters.formatExpiryLabel(
      isActive: isActive,
      daysRemaining: profile.daysRemaining,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.coachLabel,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: EColorConstants.authTextDarkBrown,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                statusText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        if (!isActive) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: isRenewing ? null : onRenew,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColorConstants.primaryColor,
                disabledBackgroundColor: EColorConstants.authPlaceholderGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isRenewing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Renew Subscription',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
