import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Server xatoligi (foydalanuvchiga o'zbekcha xabar bilan).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}

/// REST API konfiguratsiyasi.
///
/// `baseUrl` bo'sh bo'lsa ilova to'liq offline (lokal SQLite) rejimda ishlaydi.
class ApiConfig {
  const ApiConfig({this.baseUrl = '', this.token = ''});

  /// Masalan: https://api.texnobozor.uz/v1
  final String baseUrl;

  /// Bearer token (ixtiyoriy).
  final String token;

  bool get isEnabled => baseUrl.trim().isNotEmpty;

  ApiConfig copyWith({String? baseUrl, String? token}) => ApiConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        token: token ?? this.token,
      );
}

/// Yagona tarmoq nuqtasi.
///
/// Faqat shu klass HTTP bilan gaplashadi. Repositorylar undan foydalanadi,
/// ekranlar esa tarmoq borligini ham bilmaydi.
class ApiClient {
  ApiClient(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  final ApiConfig config;
  final http.Client _client;

  static const Duration timeout = Duration(seconds: 15);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalized');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      for (final e in query.entries)
        if (e.value != null) e.key: '${e.value}',
    });
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (config.token.isNotEmpty) 'Authorization': 'Bearer ${config.token}',
      };

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, {Object? body}) => _send(() => _client.post(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body ?? const {}),
      ));

  Future<dynamic> put(String path, {Object? body}) => _send(() => _client.put(
        _uri(path),
        headers: _headers,
        body: jsonEncode(body ?? const {}),
      ));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _client.patch(
            _uri(path),
            headers: _headers,
            body: jsonEncode(body ?? const {}),
          ));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    if (!config.isEnabled) {
      throw const ApiException('Server manzili kiritilmagan');
    }

    late final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Server javob bermadi (vaqt tugadi)');
    } catch (_) {
      throw const ApiException('Internet yoki server bilan aloqa yo\u2018q');
    }

    final status = response.statusCode;
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        decoded = null;
      }
    }

    if (status >= 200 && status < 300) return decoded;

    if (decoded is Map && decoded['message'] is String) {
      throw ApiException('${decoded['message']}', statusCode: status);
    }
    if (status == 401 || status == 403) {
      throw ApiException(
          'Ruxsat yo\u2018q — token noto\u2018g\u2018ri yoki muddati tugagan',
          statusCode: status);
    }
    if (status == 404) {
      throw ApiException('Ma\u2018lumot topilmadi (404)', statusCode: status);
    }
    if (status >= 500) {
      throw ApiException('Serverda xatolik ($status)', statusCode: status);
    }
    throw ApiException('So\u2018rov bajarilmadi ($status)', statusCode: status);
  }

  /// Server ishlayotganini tekshirish.
  Future<bool> ping() async {
    try {
      await get('/health');
      return true;
    } on ApiException {
      return false;
    }
  }

  void close() => _client.close();

  /// Javobdan ro'yxat ajratib olish: `[...]` yoki `{"data": [...]}`.
  static List<Map<String, Object?>> listOf(dynamic data) {
    final raw = data is Map ? data['data'] ?? data['items'] : data;
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => e.cast<String, Object?>()).toList();
  }

  /// Javobdan obyekt ajratib olish: `{...}` yoki `{"data": {...}}`.
  static Map<String, Object?>? objectOf(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, Object?>();
    }
    if (data is Map) return data.cast<String, Object?>();
    return null;
  }
}
