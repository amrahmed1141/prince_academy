import 'package:flutter/material.dart';

import '../core/cache/image_cache.dart';
import 'app/app.dart';
import 'app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppImageCache.ensureBudget();
  await bootstrap();
  runApp(const PrinceAcademyApp());
}

