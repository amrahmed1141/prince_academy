import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/colors.dart';
import 'package:prince_academy/core/di/injection.dart';
import 'package:prince_academy/core/theme/app_gradients.dart';
import 'package:prince_academy/core/widgets/branded_pull_to_refresh.dart';
import 'package:prince_academy/core/widgets/custom_snackbar.dart';
import 'package:prince_academy/features/booking/data/models/booking_freeze_model.dart';
import 'package:prince_academy/features/booking/presentation/bloc/my_freeze_requests/my_freeze_requests_cubit.dart';
import 'package:prince_academy/features/booking/presentation/widgets/freeze/member_freeze_request_card.dart';

/// Member Profile → Freeze Requests: pending, approved, and rejected sections.
class MyFreezeRequestsPage extends StatelessWidget {
  const MyFreezeRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MyFreezeRequestsCubit>()..load(),
      child: const _MyFreezeRequestsView(),
    );
  }
}

class _MyFreezeRequestsView extends StatelessWidget {
  const _MyFreezeRequestsView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyFreezeRequestsCubit, MyFreezeRequestsState>(
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
      child: Container(
        decoration: AppGradients.screenDecoration(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text('Freeze Requests'),
          ),
          body: BrandedPullToRefresh(
            onRefresh: () => context.read<MyFreezeRequestsCubit>().refresh(),
            child: BlocBuilder<MyFreezeRequestsCubit, MyFreezeRequestsState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: EColorConstants.primaryColor,
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
                    children: const [
                      _EmptyState(
                        icon: Iconsax.pause_circle,
                        title: 'No freeze requests yet',
                        subtitle:
                            'Request a freeze from an active booking on Sessions.',
                      ),
                    ],
                  );
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (state.isRefreshing) ...[
                      const LinearProgressIndicator(minHeight: 2),
                      const SizedBox(height: 10),
                    ],
                    _Section(
                      title: 'Pending',
                      emptyMessage: 'No pending freeze requests',
                      items: state.pending,
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Approved',
                      emptyMessage: 'No approved freezes yet',
                      items: state.approved,
                    ),
                    if (state.rejected.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _Section(
                        title: 'Rejected',
                        emptyMessage: 'No rejected requests',
                        items: state.rejected,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyMessage,
    required this.items,
  });

  final String title;
  final String emptyMessage;
  final List<MemberFreezeRequest> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _InlineEmpty(message: emptyMessage)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MemberFreezeRequestCard(
                key: ValueKey(item.freezeId),
                request: item,
              ),
            ),
          ),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Iconsax.tick_circle, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 48, color: EColorConstants.primaryColor.withOpacity(0.7)),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
