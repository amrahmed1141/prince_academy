import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/core/cache/image_cache.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/models/pending_payment_model.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_event.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_state.dart';
import 'package:prince_academy/features/admin/presentation/widgets/payment_method_filter.dart';
import 'package:prince_academy/features/admin/presentation/widgets/pending_payment_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/payment_screenshot_viewer.dart';
import 'package:prince_academy/features/admin/presentation/widgets/reject_payment_dialog.dart';

class PendingPaymentsPage extends StatelessWidget {
  const PendingPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminBloc>()..add(const LoadPendingPayments()),
      child: const _PendingPaymentsView(),
    );
  }
}

class _PendingPaymentsView extends StatelessWidget {
  const _PendingPaymentsView();

  Future<void> _onRefresh(BuildContext context) async {
    context.read<AdminBloc>().add(const LoadPendingPayments());
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  void _precacheCoachPhotos(BuildContext context, List<PendingPaymentModel> payments) {
    AppImageCache.precacheUrls(
      context,
      payments.map((p) => p.coachPhoto),
    );
  }

  void _showScreenshot(BuildContext context, PendingPaymentModel payment) {
    final url = payment.paymentScreenshotUrl;
    if (url == null || url.isEmpty) return;
    PaymentScreenshotViewer.show(context, url);
  }

  Future<void> _confirmReject(
    BuildContext context,
    PendingPaymentModel payment,
  ) async {
    final reason = await RejectPaymentDialog.show(context);
    if (reason == null || !context.mounted) return;
    context.read<AdminBloc>().add(
          RejectPayment(payment.bookingId, reason: reason),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColorConstants.authFieldBackground,
      appBar: AppBar(
        title: const Text('Pending Payments'),
        backgroundColor: EColorConstants.authFieldBackground,
        elevation: 0,
      ),
      body: BlocConsumer<AdminBloc, AdminState>(
        listener: (context, state) {
          if (state is PendingPaymentsLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: state.isSuccessMessage
                    ? const Color(0xFF2E7D32)
                    : Colors.red,
              ),
            );
            context.read<AdminBloc>().add(const ClearAdminMessage());
          } else if (state is AdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }

          final loaded = switch (state) {
            PendingPaymentsLoaded s => s,
            PaymentVerifying s => s.data,
            PaymentVerified s => s.data,
            PaymentRejected s => s.data,
            _ => null,
          };
          if (loaded != null) {
            _precacheCoachPhotos(context, loaded.payments);
          }
        },
        builder: (context, state) {
          if (state is AdminInitial || state is PendingPaymentsLoading) {
            return const PendingPaymentsListShimmer();
          }

          if (state is AdminError) {
            return _ErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<AdminBloc>().add(const LoadPendingPayments()),
            );
          }

          final loaded = switch (state) {
            PendingPaymentsLoaded s => s,
            PaymentVerifying s => s.data,
            PaymentVerified s => s.data,
            PaymentRejected s => s.data,
            _ => null,
          };

          if (loaded == null) {
            return const PendingPaymentsListShimmer();
          }

          final payments = loaded.filteredPayments;

          return Column(
            children: [
              if (loaded.isRefreshing)
                const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 8),
              PaymentMethodFilter(
                selected: loaded.filter,
                onChanged: (method) {
                  context.read<AdminBloc>().add(FilterByMethod(method));
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  color: EColorConstants.primaryColor,
                  onRefresh: () => _onRefresh(context),
                  child: payments.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No pending payments 🎉',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: EColorConstants.authPlaceholderGray,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            final isVerifying = state is PaymentVerifying &&
                                state.bookingId == payment.bookingId;
                            final isRejecting =
                                loaded.rejectingBookingId == payment.bookingId;

                            return PendingPaymentCard(
                              payment: payment,
                              isVerifying: isVerifying,
                              isRejecting: isRejecting,
                              onVerify: () {
                                context.read<AdminBloc>().add(
                                      VerifyPayment(
                                        payment.bookingId,
                                        notes: payment.isCash
                                            ? 'Cash payment confirmed from admin dashboard'
                                            : 'InstaPay payment verified from admin dashboard',
                                      ),
                                    );
                              },
                              onReject: payment.isInstaPay
                                  ? () => _confirmReject(context, payment)
                                  : null,
                              onViewScreenshot: payment
                                          .paymentScreenshotUrl !=
                                      null
                                  ? () => _showScreenshot(context, payment)
                                  : null,
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
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
}
