# Screen excerpt

SOURCE: `lib/features/sessions/presentation/pages/sessions_page.dart`

```dart
class SessionsPage extends StatelessWidget {
  const SessionsPage({
    super.key,
    this.showBackButton = false,
    this.usePlainBackground = false,
  });

  final bool showBackButton;
  final bool usePlainBackground;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionsBloc>(
      create: (_) => sl<SessionsBloc>()..add(SessionsStarted()),
      child: SessionsView(
        showBackButton: showBackButton,
        usePlainBackground: usePlainBackground,
      ),
    );
  }
}

class SessionsView extends StatelessWidget {
  // …

  @override
  Widget build(BuildContext context) {
    final body = BlocBuilder<SessionsBloc, SessionsState>(
      buildWhen: (previous, current) =>
          current is SessionsInitial ||
          current is SessionsLoading ||
          current is SessionsError ||
          current is SessionsLoaded,
      builder: (context, state) {
        if (state is SessionsInitial || state is SessionsLoading) {
          return const _LoadingSkeleton();
        }
        if (state is SessionsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<SessionsBloc>().add(SessionsStarted()),
          );
        }
        if (state is SessionsLoaded) {
          // … empty / loaded body — see source
        }
        return const SizedBox.shrink();
      },
    );
    // Scaffold wraps body — see source
  }
}
```

Alternate (constructor inject at page): `BookingPage` builds `BookingBloc(sl<BookingRepository>(), …)` then provides it — same rule: no remote I/O in the page.
