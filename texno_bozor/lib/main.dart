import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/router/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'data/local/app_database.dart';
import 'data/remote/api_client.dart';
import 'data/repositories/local/local_misc_repositories.dart';
import 'features/profile/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'data/services/ai_service.dart';

/// TEXNO BOZOR — offline-first elektronika marketplace ilovasi.
///
/// Ishga tushirish uchun server, VPS yoki PostgreSQL kerak emas: barcha
/// ma'lumot telefondagi SQLite bazasida saqlanadi. Internet faqat TEXNO AI
/// onlayn rejimi uchun (ixtiyoriy) kerak bo'ladi.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const _Bootstrap());
}

/// Bazani ochadi va saqlangan sozlamalarni yuklaydi, so'ng ilovani beradi.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<Startup> _future = Startup.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Startup>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _splashApp(SplashScreen(
            error: '${snapshot.error}',
            onRetry: () => setState(() => _future = Startup.load()),
          ));
        }

        final startup = snapshot.data;
        if (startup == null) return _splashApp(const SplashScreen());

        return ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(startup.database),
            aiConfigProvider.overrideWith((ref) => startup.ai),
            apiConfigProvider.overrideWith((ref) => startup.api),
          ],
          child: const TexnoBozorApp(),
        );
      },
    );
  }

  Widget _splashApp(Widget child) => MaterialApp(
        title: 'TEXNO BOZOR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: child,
      );
}

class TexnoBozorApp extends StatelessWidget {
  const TexnoBozorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEXNO BOZOR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AppShell(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

/// Ilova ishga tushishida yuklanadigan boshlang'ich holat.
class Startup {
  const Startup({
    required this.database,
    required this.ai,
    required this.api,
  });

  final AppDatabase database;
  final AiConfig ai;
  final ApiConfig api;

  static Future<Startup> load() async {
    final db = await AppDatabase.open();
    final settings = LocalUserRepository(db);

    Future<String> read(String key) async =>
        await settings.getSetting(key) ?? '';

    final aiKey = await read(SettingsScreen.keyAiApiKey);
    final aiUrl = await read(SettingsScreen.keyAiBaseUrl);
    final aiModel = await read(SettingsScreen.keyAiModel);
    final apiUrl = await read(SettingsScreen.keyApiBaseUrl);
    final apiToken = await read(SettingsScreen.keyApiToken);

    return Startup(
      database: db,
      ai: AiConfig(
        // Kalit ilova ichida (Sozlamalar) yoki build vaqtida beriladi —
        // hech qachon kodga yozilmaydi.
        apiKey: aiKey.isNotEmpty
            ? aiKey
            : const String.fromEnvironment('TEXNO_AI_API_KEY'),
        baseUrl: aiUrl.isNotEmpty ? aiUrl : 'https://api.openai.com/v1',
        model: aiModel.isNotEmpty ? aiModel : 'gpt-4o-mini',
      ),
      api: ApiConfig(
        baseUrl: apiUrl.isNotEmpty
            ? apiUrl
            : const String.fromEnvironment('API_BASE_URL'),
        token: apiToken.isNotEmpty
            ? apiToken
            : const String.fromEnvironment('API_TOKEN'),
      ),
    );
  }
}
