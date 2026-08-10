import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/theme/theme.dart';
import 'package:prince_academy/core/widgets/branded_pull_to_refresh.dart';
import 'package:prince_academy/core/widgets/custom_snackbar.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/presentation/bloc/all_freeze/all_freeze_cubit.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_home/admin_empty_state.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/freeze/active_freeze_card.dart';
import 'package:prince_academy/features/admin/presentation/widgets/freeze/pending_freeze_request_card.dart';

class AllFreezePage extends StatelessWidget {
  const AllFreezePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AllFreezeCubit>()..load(),
      child: const _AllFreezeView(),
    );
  }
}

class _AllFreezeView extends StatelessWidget {
  const _AllFreezeView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AllFreezeCubit, AllFreezeState>(
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage && next.errorMessage != null,
      listener: (context, state) {
        CustomSnackbar.show(
          context: context,
          message: state.errorMessage!,
          backgroundColor: const Color(0xFFC62828),
          icon: Iconsax.warning_2,
        );
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
                title: BlocSelector<AllFreezeCubit, AllFreezeState, int>(
                  selector: (s) => s.pending.length,
                  builder: (context, pendingCount) {
                    return Text(
                      'Freeze${pendingCount > 0 ? ' ($pendingCount pending)' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    );
                  },
                ),
              ),
              body: BrandedPullToRefresh(
            onRefresh: () => context.read<AllFreezeCubit>().refresh(),
            child: BlocBuilder<AllFreezeCubit, AllFreezeState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const AllFreezeListShimmer();
                }

                return ListView(
                  physics: AdminSmoothScrollBehavior.physics,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    const Text(
                      'Pending requests',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (state.pending.isEmpty)
                      const AdminEmptyState(
                        icon: Iconsax.tick_circle,
                        message: 'No pending freeze requests',
                      )
                    else
                      SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.pending.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = state.pending[index];
                            return PendingFreezeRequestCard(
                              key: ValueKey(item.freezeId),
                              request: item,
                              busy: state.busyFreezeId == item.freezeId,
                              onApprove: () => context
                                  .read<AllFreezeCubit>()
                                  .approve(item.freezeId),
                              onReject: () => context
                                  .read<AllFreezeCubit>()
                                  .reject(item.freezeId),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Text(
                      'Active freezes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: EColorConstants.authTextDarkBrown,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (state.active.isEmpty)
                      const AdminEmptyState(
                        icon: Iconsax.pause_circle,
                        message: 'No active freezes yet',
                      )
                    else
                      ...state.active.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ActiveFreezeCard(
                            key: ValueKey(item.freezeId),
                            freeze: item,
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
      ),
    );
  }
}
