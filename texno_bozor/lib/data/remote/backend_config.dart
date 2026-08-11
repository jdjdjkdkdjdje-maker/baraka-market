import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ma'lumotlar manbai rejimi.
///
/// Ilova sukut bo'yicha `local` rejimda ishlaydi — internet, server va
/// PostgreSQL kerak emas. Keyinchalik REST API tayyor bo'lganda foydalanuvchi
/// (yoki build konfiguratsiyasi) `remote` rejimni yoqadi va o'sha repository
/// interfeyslarining API implementatsiyasi ishga tushadi. Ekranlar va biznes
/// logika o'zgarmaydi.
enum BackendMode {
  /// Faqat qurilma ichidagi SQLite (Drift) — offline-first.
  local('Lokal (offline)'),

  /// REST API + PostgreSQL. Ma'lumot lokal bazaga keshlanadi,
  /// internet yo'q bo'lsa keshdan o'qiladi.
  remote('Server (REST API)');

  const BackendMode(this.label);
  final String label;

  static BackendMode fromName(String? name) => BackendMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => BackendMode.local,
      );
}

/// Backend (REST API) konfiguratsiyasi.
class BackendConfig {
  const BackendConfig({
    this.mode = BackendMode.local,
    this.baseUrl = '',
    this.token = '',
  });

  final BackendMode mode;

  /// Masalan: https://api.texnobozor.uz/v1
  final String baseUrl;

  /// Bearer token (ixtiyoriy).
  final String token;

  /// REST rejim haqiqatan ishga tushishi mumkinmi?
  bool get isRemote => mode == BackendMode.remote && baseUrl.trim().isNotEmpty;

  BackendConfig copyWith({
    BackendMode? mode,
    String? baseUrl,
    String? token,
  }) {
    return BackendConfig(
      mode: mode ?? this.mode,
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BackendConfig &&
      other.mode == mode &&
      other.baseUrl == baseUrl &&
      other.token == token;

  @override
  int get hashCode => Object.hash(mode, baseUrl, token);
}

/// Konfiguratsiyani xavfsiz saqlash (Secure Storage) + .env / --dart-define.
class BackendConfigStore {
  BackendConfigStore(this._storage);

  static const _kMode = 'backend_mode';
  static const _kBaseUrl = 'backend_base_url';
  static const _kToken = 'backend_token';

  final FlutterSecureStorage _storage;

  String _fallback(String key, String define) {
    final fromEnv = dotenv.maybeGet(key);
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return define;
  }

  Future<BackendConfig> load() async {
    try {
      final mode = await _storage.read(key: _kMode);
      final baseUrl = await _storage.read(key: _kBaseUrl);
      final token = await _storage.read(key: _kToken);

      const defineUrl = String.fromEnvironment('API_BASE_URL');
      const defineToken = String.fromEnvironment('API_TOKEN');
      const defineMode = String.fromEnvironment('API_MODE');

      final resolvedUrl =
          (baseUrl != null && baseUrl.isNotEmpty)
              ? baseUrl
              : _fallback('API_BASE_URL', defineUrl);
      final resolvedToken =
          (token != null && token.isNotEmpty)
              ? token
              : _fallback('API_TOKEN', defineToken);
      final resolvedMode = mode ?? _fallback('API_MODE', defineMode);

      return BackendConfig(
        mode: BackendMode.fromName(resolvedMode),
        baseUrl: resolvedUrl,
        token: resolvedToken,
      );
    } catch (_) {
      // Secure storage ishlamasa ham ilova lokal rejimda ishlayveradi.
      return const BackendConfig();
    }
  }

  Future<void> save(BackendConfig config) async {
    await _storage.write(key: _kMode, value: config.mode.name);
    await _storage.write(key: _kBaseUrl, value: config.baseUrl);
    await _storage.write(key: _kToken, value: config.token);
  }
}
