import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_renew/booking_renew_cubit.dart';
import 'package:prince_academy/features/booking/presentation/helpers/booking_renew_navigation.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking_renew_page.dart';
import 'package:prince_academy/features/booking/presentation/widgets/renew_booking_prompt_card.dart';

/// Shows the expired-booking renew dialog for the authenticated member shell.
class RenewPromptHost extends StatefulWidget {
  const RenewPromptHost({super.key, required this.child});

  final Widget child;

  @override
  State<RenewPromptHost> createState() => _RenewPromptHostState();
}

class _RenewPromptHostState extends State<RenewPromptHost> {
  bool _dialogOpen = false;
  bool _handlingCreated = false;

  @override
  void initState() {
    super.initState();
    // load() may finish before BlocListener is mounted — sync once after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromState());
  }

  void _syncFromState() {
    if (!mounted) return;
    _onState(context, context.read<BookingRenewCubit>().state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingRenewCubit, BookingRenewState>(
      listenWhen: (previous, current) =>
          previous.hasPrompt != current.hasPrompt ||
          previous.current?.bookingId != current.current?.bookingId ||
          previous.created?.id != current.created?.id ||
          previous.isDismissing != current.isDismissing ||
          (previous.isLoading && !current.isLoading),
      listener: _onState,
      child: widget.child,
    );
  }

  void _onState(BuildContext context, BookingRenewState state) {
    if (state.created != null && !_handlingCreated) {
      _handlingCreated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showSuccess(context, state);
      });
      return;
    }

    if (state.hasPrompt && !_dialogOpen && !_handlingCreated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latest = context.read<BookingRenewCubit>().state;
        if (latest.hasPrompt && !_dialogOpen && !_handlingCreated) {
          _showPrompt(context);
        }
      });
    }
  }

  Future<void> _showPrompt(BuildContext context) async {
    final cubit = context.read<BookingRenewCubit>();
    final booking = cubit.state.current;
    if (booking == null || _dialogOpen) return;

    _dialogOpen = true;
    try {
      await RenewBookingPromptCard.show(
        context,
        booking: booking,
        remainingCount: cubit.state.queue.length - 1,
        isBusy: cubit.state.isDismissing,
        onRenew: () {
          Navigator.of(context, rootNavigator: true).pop();
          cubit.openRenewFlow();
          _openRenewPage(context, cubit);
        },
        onCancel: () async {
          await cubit.dismissCurrent();
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  Future<void> _openRenewPage(
    BuildContext context,
    BookingRenewCubit cubit,
  ) {
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const BookingRenewPage(),
        ),
      ),
    );
  }

  Future<void> _showSuccess(
    BuildContext context,
    BookingRenewState state,
  ) async {
    final cubit = context.read<BookingRenewCubit>();
    try {
      await showBookingRenewSuccess(context, state);
    } finally {
      _handlingCreated = false;
      cubit.clearCreated();
    }
  }
}
