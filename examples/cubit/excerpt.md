# Cubit excerpt

SOURCE: `lib/features/admin/presentation/bloc/admin_dashboard_cubit.dart`  
DI: `lib/core/di/injection.dart`

```dart
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit({required AdminDashboardRepository repository})
      : _repository = repository,
        super(const AdminDashboardState.initial());

  final AdminDashboardRepository _repository;

  Future<void> load() async {
    final hasData = state.data != null;
    emit(
      state.copyWith(
        isInitialLoading: !hasData,
        isRefreshing: hasData,
        clearError: true,
      ),
    );

    try {
      final data = await _repository.loadDashboard();
      emit(
        state.copyWith(
          data: data,
          isInitialLoading: false,
          isRefreshing: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> refresh() => load();
}

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.data,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  const AdminDashboardState.initial()
      : data = null,
        isInitialLoading = true,
        isRefreshing = false,
        errorMessage = null;

  final AdminDashboardData? data;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  // copyWith + props — see source file
}
```

```dart
// lib/core/di/injection.dart
sl.registerLazySingleton<AdminDashboardRepository>(
  () => AdminDashboardRepository(sl()),
);
sl.registerFactory<AdminDashboardCubit>(
  () => AdminDashboardCubit(repository: sl()),
);
```
