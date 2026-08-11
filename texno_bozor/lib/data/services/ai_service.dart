import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/format.dart';
import '../database/app_database.dart';

/// TEXNO AI xatolik turlari.
class AiNoKeyException implements Exception {
  @override
  String toString() =>
      'AI API kaliti topilmadi. Uni Profil > Sozlamalar bo\u2018limida kiriting.';
}

class AiNetworkException implements Exception {
  const AiNetworkException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// TEXNO AI xizmati.
///
/// - API kaliti hech qachon kodga hardcode qilinmaydi:
///   1) ilova ichidan kiritilgan kalit (Secure Storage),
///   2) .env fayldagi TEXNO_AI_API_KEY,
///   3) build vaqtida --dart-define=TEXNO_AI_API_KEY=...
/// - OpenAI-uyg'un istalgan endpoint bilan ishlaydi (TEXNO_AI_BASE_URL).
/// - AI faqat lokal bazadagi mahsulotlar haqida gapiradi (grounding).
class AiService {
  AiService(this.secureStorage);

  static const _storageKey = 'texno_ai_api_key';
  static const _storageBaseUrl = 'texno_ai_base_url';
  static const _storageModel = 'texno_ai_model';

  final FlutterSecureStorage secureStorage;
  Dio? _dio;

  Dio get _client => _dio ??= Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

  Future<String?> getApiKey() async {
    final fromStorage = await secureStorage.read(key: _storageKey);
    if (fromStorage != null && fromStorage.isNotEmpty) return fromStorage;

    final fromEnv = dotenv.maybeGet('TEXNO_AI_API_KEY');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    const fromDefine = String.fromEnvironment('TEXNO_AI_API_KEY');
    return fromDefine.isEmpty ? null : fromDefine;
  }

  Future<String> getBaseUrl() async {
    final fromStorage = await secureStorage.read(key: _storageBaseUrl);
    if (fromStorage != null && fromStorage.isNotEmpty) return fromStorage;
    final fromEnv = dotenv.maybeGet('TEXNO_AI_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    const fromDefine = String.fromEnvironment(
      'TEXNO_AI_BASE_URL',
      defaultValue: 'https://api.openai.com/v1',
    );
    return fromDefine;
  }

  Future<String> getModel() async {
    final fromStorage = await secureStorage.read(key: _storageModel);
    if (fromStorage != null && fromStorage.isNotEmpty) return fromStorage;
    final fromEnv = dotenv.maybeGet('TEXNO_AI_MODEL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    const fromDefine = String.fromEnvironment(
      'TEXNO_AI_MODEL',
      defaultValue: 'gpt-4o-mini',
    );
    return fromDefine;
  }

  Future<void> saveSettings({
    String? apiKey,
    String? baseUrl,
    String? model,
  }) async {
    if (apiKey != null) await secureStorage.write(key: _storageKey, value: apiKey);
    if (baseUrl != null) {
      await secureStorage.write(key: _storageBaseUrl, value: baseUrl);
    }
    if (model != null) await secureStorage.write(key: _storageModel, value: model);
  }

  /// AI uchun mahsulot konteksti: faqat LOKAL bazadagi mahsulotlar.
  String buildProductContext(List<Product> products) {
    if (products.isEmpty) {
      return 'Mos mahsulotlar topilmadi. Foydalanuvchiga shuni ayting va boshqa savol bering.';
    }
    final lines = products.map((p) {
      final discount = p.oldPrice != null
          ? ' (eski narxi ${formatSum(p.oldPrice!)})'
          : '';
      return '- ${p.name} | brend: ${p.brand} | narx: ${formatSum(p.price)}$discount | reyting: ${p.rating.toStringAsFixed(1)} | xususiyatlar: ${p.specsJson}';
    });
    return lines.join('\n');
  }

  static const _systemIntro =
      'Sen TEXNO BOZOR elektronika bozori ilovasining TEXNO AI yordamchisan. '
      'Vazifang: texnika tanlashda yordam berish, mahsulotlarni taqqoslash, '
      'xususiyatlarni tushuntirish, kompyuter yig\'ishda maslahat berish. '
      'QAT\'IY QOIDALAR: '
      '1) Faqat quyida MAHSULOTLAR ro\'yxatida berilgan mahsulotlar haqida gapir. '
      '2) Ro\'yxatda yo\'q mahsulot, narx yoki brendni HECH QACHON o\'ylab topma. '
      '3) Narxlarni faqat ro\'yxatdagi qiymatlar bilan ayt. '
      '4) Javobni o\'zbek tilida, qisqa, aniq va do\'stona yoz. '
      '5) Kerak bo\'lsa ro\'yxatdan 1-3 ta eng mos variantni tavsiya qil va sababini tushuntir.';

  Future<String> ask({
    required String userMessage,
    required String productContext,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) throw AiNoKeyException();

    final baseUrl = (await getBaseUrl()).replaceAll(RegExp(r'/+$'), '');
    final model = await getModel();

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': '$_systemIntro\n\nMAHSULOTLAR (lokal bazadan):\n$productContext',
      },
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await _client.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': model,
          'messages': messages,
          'temperature': 0.4,
          'max_tokens': 700,
        },
      );

      final data = response.data;
      if (data is Map && data['choices'] is List && (data['choices'] as List).isNotEmpty) {
        final message = (data['choices'] as List).first['message'];
        final content = message is Map ? message['content'] : null;
        if (content is String && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
      throw const AiNetworkException('AI javobini o\u2018qib bo\u2018lmadi.');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const AiNetworkException(
          'AI API kaliti noto\u2018g\u2018ri yoki muddati tugagan. Sozlamalardan tekshiring.',
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const AiNetworkException('Internetga ulanishingiz kerak.');
      }
      debugPrint('TEXNO AI xato: $e');
      throw AiNetworkException(
        'AI bilan bog\u2018lanishda xatolik (kod: ${status ?? '-'}). Qayta urinib ko\u2018ring.',
      );
    }
  }
}
