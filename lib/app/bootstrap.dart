import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/cache/local_cache_store.dart';
import '../core/config/supabase_config.dart';
import '../core/di/injection.dart';

Future<void> bootstrap() async {
  await Hive.initFlutter();
  await LocalCacheStore.init();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await setupDI();
}
