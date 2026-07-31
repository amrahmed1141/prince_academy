import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/widgets/branded_pull_to_refresh.dart';
import 'package:prince_academy/core/widgets/shimmer_widgets.dart';
import 'package:prince_academy/features/admin/data/models/coach_with_sessions.dart';
import 'package:prince_academy/features/admin/presentation/bloc/all_schedules/all_schedules_cubit.dart';
import 'package:prince_academy/features/admin/presentation/pages/edit_session_page.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_home/admin_empty_state.dart';
import 'package:prince_academy/features/admin/presentation/widgets/admin_smooth_scroll.dart';
import 'package:prince_academy/features/admin/presentation/widgets/session_card.dart';
import 'package:prince_academy/features/home/data/models/coach_session_model.dart';

/// Full list of every coach schedule (same source as Add Info → Sessions).
class AllSchedulesPage extends StatelessWidget {
  const AllSchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AllSchedulesCubit>()..load(),
      child: const _AllSchedulesView(),
    );
  }
}

class _AllSchedulesView extends StatelessWidget {
  const _AllSchedulesView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppGradients.homeScreenDecoration(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: EColorConstants.authTextDarkBrown),
          title: BlocSelector<AllSchedulesCubit, AllSchedulesState, int>(
            selector: (state) => state.groups.length,
            builder: (context, count) {
              return Text(
                'All Schedules${count > 0 ? ' ($count)' : ''}',
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
          onRefresh: () => context.read<AllSchedulesCubit>().refresh(),
          child: BlocBuilder<AllSchedulesCubit, AllSchedulesState>(
            builder: (context, state) {
              if (state.isLoading && state.groups.isEmpty) {
                return ListView(
                  physics: AdminSmoothScrollBehavior.physics,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: const [CoachListShimmer(itemCount: 5)],
                );
              }

              if (state.errorMessage != null && state.groups.isEmpty) {
                return ListView(
                  physics: AdminSmoothScrollBehavior.physics,
                  padding: const EdgeInsets.all(32),
                  children: [
                    const SizedBox(height: 80),
                    const Icon(
                      Iconsax.warning_2,
                      size: 48,
                      color: EColorConstants.authPlaceholderGray,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: EColorConstants.authPlaceholderGray,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            context.read<AllSchedulesCubit>().load(force: true),
                        icon: const Icon(Iconsax.refresh),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: EColorConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (state.groups.isEmpty) {
                return ListView(
                  physics: AdminSmoothScrollBehavior.physics,
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                  children: const [
                    AdminEmptyState(
                      icon: Iconsax.calendar_remove,
                      message:
                          'No sessions added yet.\nCreate schedules from Add Info.',
                    ),
                  ],
                );
              }

              return ListView.builder(
                physics: AdminSmoothScrollBehavior.physics,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  return GroupedCoachSessionCard(
                    coachWithSessions: group,
                    onEdit: (session) =>
                        _openEdit(context, session),
                    onDelete: () => _delete(context, group),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    CoachSessionModel session,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditSessionPage(session: session)),
    );
    if (result == true && context.mounted) {
      context.read<AllSchedulesCubit>().refresh();
    }
  }

  void _delete(BuildContext context, CoachWithSessions group) {
    context.read<AllSchedulesCubit>().deleteSchedule(
          group.schedules.map((s) => s.id).toList(),
        );
  }
}
