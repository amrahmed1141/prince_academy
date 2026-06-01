import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prince_academy/features/auth/domain/repositories/auth_repo.dart';
import 'package:prince_academy/features/auth/data/repositories/auth_repo_impl.dart';
import '../../features/auth/data/datasources/auth_remote_ds.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.I;

Future<void> setupDI() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  sl.registerLazySingleton<AuthRemoteDs>(() => AuthRemoteDs(sl()));

  sl.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(sl()));

  sl.registerFactory<AuthBloc>(() => AuthBloc(sl()));
}
