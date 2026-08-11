import 'package:dio/dio.dart';

import 'backend_config.dart';

/// API xatoligi (foydalanuvchiga o'zbekcha xabar bilan).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNetwork => statusCode == null;

  @override
  String toString() => message;
}

/// REST API klienti.
///
/// Faqat shu klass tarmoq bilan gaplashadi. Repositorylar undan foydalanadi,
/// ekranlar esa umuman bilmaydi — shu sababli implementatsiyani almashtirish
/// oson (Repository pattern).
class ApiClient {
  ApiClient(this.config, {Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _normalize(config.baseUrl),
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (config.token.isNotEmpty) 'Authorization': 'Bearer ${config.token}',
      },
      // Statuslarni o'zimiz tekshiramiz.
      validateStatus: (_) => true,
    );
  }

  final BackendConfig config;
  final Dio _dio;

  static String _normalize(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _dio.post<dynamic>(path, data: body));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  Future<dynamic> delete(String path) =>
      _send(() => _dio.delete<dynamic>(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    if (config.baseUrl.trim().isEmpty) {
      throw const ApiException('Server manzili (API base URL) kiritilmagan');
    }
    late final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw ApiException(_dioMessage(e));
    } catch (_) {
      throw const ApiException('Serverga ulanib bo\u2018lmadi');
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return response.data;

    throw ApiException(_statusMessage(status, response.data),
        statusCode: status);
  }

  static String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server javob bermadi (vaqt tugadi)';
      case DioExceptionType.connectionError:
        return 'Internet yoki server bilan aloqa yo\u2018q';
      case DioExceptionType.badCertificate:
        return 'Server sertifikati ishonchsiz';
      case DioExceptionType.cancel:
        return 'So\u2018rov bekor qilindi';
      default:
        return 'Serverga ulanib bo\u2018lmadi';
    }
  }

  static String _statusMessage(int status, dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (status == 401 || status == 403) {
      return 'Ruxsat yo\u2018q — token noto\u2018g\u2018ri yoki muddati tugagan';
    }
    if (status == 404) return 'Ma\u2018lumot topilmadi (404)';
    if (status >= 500) return 'Serverda xatolik ($status)';
    return 'So\u2018rov bajarilmadi ($status)';
  }

  /// Server ishlayotganini tekshirish: GET /health
  Future<bool> ping() async {
    try {
      await get('/health');
      return true;
    } on ApiException {
      return false;
    }
  }
}
