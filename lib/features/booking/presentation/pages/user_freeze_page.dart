import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/core/widgets/custom_snackbar.dart';
import 'package:prince_academy/features/admin/data/models/session_detail_model.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/user_freeze/user_freeze_cubit.dart';
import 'package:prince_academy/features/booking/presentation/widgets/freeze/freeze_confirm_button.dart';
import 'package:prince_academy/features/booking/presentation/widgets/freeze/freeze_expiry_preview.dart';
import 'package:prince_academy/features/booking/presentation/widgets/freeze/freeze_session_selector.dart';

/// Shared freeze flow for Admin (apply) and Member (request).
class UserFreezePage extends StatelessWidget {
  const UserFreezePage({
    super.key,
    required this.bookingId,
    required this.actor,
  });

  final String bookingId;
  final FreezeActor actor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserFreezeCubit>()
        ..load(bookingId: bookingId, actor: actor),
      child: const _UserFreezeView(),
    );
  }
}

class _UserFreezeView extends StatelessWidget {
  const _UserFreezeView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserFreezeCubit, UserFreezeState>(
      listenWhen: (prev, next) =>
          prev.successMessage != next.successMessage ||
          prev.errorMessage != next.errorMessage,
      listener: (context, state) {
        if (state.successMessage != null) {
          CustomSnackbar.show(
            context: context,
            message: state.successMessage!,
            backgroundColor: const Color(0xFF2E7D32),
            icon: Iconsax.tick_circle,
          );
          Navigator.of(context).pop(true);
          return;
        }
        if (state.errorMessage != null) {
          CustomSnackbar.show(
            context: context,
            message: state.errorMessage!,
            backgroundColor: const Color(0xFFC62828),
            icon: Iconsax.warning_2,
          );
        }
      },
      child: Theme(
        data: EAppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
        ),
        child: Material(
          color: const Color(0xFFFFF9F5),
          child: Container(
            decoration: AppGradients.homeScreenDecoration(),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: const BackButton(
                  color: EColorConstants.authTextDarkBrown,
                ),
                title: const Text(
                  'Freeze Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: EColorConstants.authTextDarkBrown,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              body: BlocBuilder<UserFreezeCubit, UserFreezeState>(
            buildWhen: (prev, next) =>
                prev.isLoading != next.isLoading ||
                prev.sessions != next.sessions,
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: EColorConstants.primaryColor,
                  ),
                );
              }

              if (state.sessions.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No remaining sessions available to freeze.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: EColorConstants.authPlaceholderGray,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        const Text(
                          'Select sessions to freeze',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: EColorConstants.authTextDarkBrown,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap a circled day to freeze it. Red = missed, green = upcoming. Expiry extends by one day per session.',
                          style: TextStyle(
                            fontSize: 12,
                            color: EColorConstants.authPlaceholderGray,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 16),
                        BlocSelector<UserFreezeCubit, UserFreezeState,
                            Set<String>>(
                          selector: (s) => s.selectedKeys,
                          builder: (context, selected) {
                            return FreezeSessionSelector(
                              sessions: state.sessions,
                              selectedKeys: selected,
                              onToggle: (SessionDetail session) {
                                context
                                    .read<UserFreezeCubit>()
                                    .toggleDate(session.sessionDate);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        BlocSelector<UserFreezeCubit, UserFreezeState,
                            ({int count, DateTime? expiry})>(
                          selector: (s) => (
                            count: s.selectedCount,
                            expiry: s.previewNewExpiry,
                          ),
                          builder: (context, preview) {
                            return FreezeExpiryPreview(
                              frozenCount: preview.count,
                              newExpiry: preview.expiry,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: BlocSelector<UserFreezeCubit, UserFreezeState,
                          ({bool canSubmit, bool submitting, String label})>(
                        selector: (s) => (
                          canSubmit: s.canSubmit,
                          submitting: s.isSubmitting,
                          label: s.confirmLabel,
                        ),
                        builder: (context, slice) {
                          return FreezeConfirmButton(
                            label: slice.label,
                            enabled: slice.canSubmit,
                            loading: slice.submitting,
                            onPressed: () =>
                                context.read<UserFreezeCubit>().submit(),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
            ),
          ),
        ),
      ),
    );
  }
}
