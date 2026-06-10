import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:prince_academy/features/auth/data/repositories/auth_repo_impl.dart';
import 'package:prince_academy/features/admin/data/repositories/coach_repository.dart';
import 'package:prince_academy/features/home/data/repositories/home_coach_repository.dart';
import '../../features/auth/data/datasources/auth_remote_ds.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.I;

Future<void> setupDI() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  sl.registerLazySingleton<CoachRepository>(() => CoachRepository(sl()));
  sl.registerLazySingleton<HomeCoachRepository>(() => HomeCoachRepository(sl()));

  sl.registerLazySingleton<AuthRemoteDs>(() => AuthRemoteDs(sl()));

  sl.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(sl()));

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
}

