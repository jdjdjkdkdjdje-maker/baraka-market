import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

  // .env fayli mavjud bo'lmasa ham ilova ishlayveradi (offline-first).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('TEXNO BOZOR: .env topilmadi — standart sozlamalar ishlatiladi.');
  }

  runApp(const ProviderScope(child: TexnoBozorApp()));
}

class TexnoBozorApp extends ConsumerWidget {
  const TexnoBozorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'TEXNO BOZOR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
