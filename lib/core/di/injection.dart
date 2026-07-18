import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/core/cache/local_cache_store.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:prince_academy/features/auth/data/repositories/auth_repo_impl.dart';
import 'package:prince_academy/features/admin/data/datasources/admin_session_preferences.dart';
import 'package:prince_academy/features/admin/data/repositories/admin_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/branch_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/admin/data/repositories/finance_repository.dart';
import 'package:prince_academy/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/coach/coach_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/finance_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/session_detail_bloc.dart';
import 'package:prince_academy/features/admin/presentation/bloc/tracking/tracking_bloc.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import 'package:prince_academy/features/booking/data/datasources/booking_remote_ds.dart';
import 'package:prince_academy/features/booking/data/repositories/booking_repository.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_detail_bloc.dart';
import 'package:prince_academy/features/booking/presentation/bloc/booking_history_bloc.dart';
import 'package:prince_academy/core/services/user_qr_service.dart';
import '../../features/auth/data/datasources/auth_remote_ds.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'package:prince_academy/features/home/presentation/bloc/home_bloc.dart';
import 'package:prince_academy/features/sessions/data/repositories/sessions_repository.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:prince_academy/features/sessions/presentation/bloc/user_session_detail_bloc.dart';
import 'package:prince_academy/features/notifications/data/repositories/notification_repository.dart';
import 'package:prince_academy/features/notifications/presentation/bloc/notification_bloc.dart';

final sl = GetIt.I;

Future<void> setupDI() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerSingleton<LocalCacheStore>(LocalCacheStore.instance);

  final sessionPreferences = await AdminSessionPreferences.create();
  sl.registerSingleton<AdminSessionPreferences>(sessionPreferences);

  sl.registerLazySingleton<BranchRepository>(
    () => BranchRepository(sl(), cache: sl()),
  );
  sl.registerLazySingleton<CoachRepository>(() => CoachRepository(sl()));
  sl.registerLazySingleton<AdminRepository>(() => AdminRepository(sl()));
  sl.registerLazySingleton<FinanceRepository>(() => FinanceRepository(sl()));
  sl.registerFactory<AdminBloc>(() => AdminBloc(repository: sl()));
  sl.registerFactory<FinanceCubit>(() => FinanceCubit(repository: sl()));
  sl.registerFactory<CoachBloc>(() => CoachBloc(repository: sl()));
  sl.registerLazySingleton<HomeCoachRepository>(
    () => HomeCoachRepository(sl(), cache: sl()),
  );

  sl.registerLazySingleton<BookingRemoteDs>(() => BookingRemoteDs(sl()));
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepository(sl(), cache: sl()),
  );
  sl.registerLazySingleton<UserQrService>(() => UserQrService(sl()));

  sl.registerLazySingleton<AuthRemoteDs>(
    () => AuthRemoteDs(sl(), cache: sl()),
  );

  sl.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(sl()));

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
  sl.registerFactory<BookingBloc>(() => BookingBloc(sl()));
  sl.registerFactory<BookingHistoryBloc>(() => BookingHistoryBloc(sl()));
  sl.registerFactory<BookingDetailBloc>(() => BookingDetailBloc(sl()));
  sl.registerFactory<TrackingBloc>(() => TrackingBloc(
        repository: sl(),
        branchRepository: sl(),
      ));
  sl.registerFactory<SessionDetailBloc>(
      () => SessionDetailBloc(repository: sl()));

  sl.registerLazySingleton<SessionsRepository>(
    () => SessionsRepository(sl(), cache: sl()),
  );
  sl.registerFactory<SessionsBloc>(() => SessionsBloc(repository: sl()));
  sl.registerFactory<UserSessionDetailBloc>(
    () => UserSessionDetailBloc(repository: sl()),
  );
  sl.registerFactory<HomeBloc>(() => HomeBloc(
        sessionsRepository: sl(),
        bookingRepository: sl(),
        branchRepository: sl(),
      ));

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(sl()),
  );
  // App-scoped while authenticated (provided in PrinceAcademyApp).
  sl.registerFactory<NotificationBloc>(() => NotificationBloc(sl()));
}
