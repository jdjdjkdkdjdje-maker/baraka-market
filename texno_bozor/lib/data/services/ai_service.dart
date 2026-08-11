import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

/// TEXNO AI javobi.
class AiReply {
  const AiReply({
    required this.text,
    this.productIds = const [],
    this.online = false,
  });

  final String text;

  /// Javobda tavsiya qilingan mahsulotlar.
  final List<String> productIds;

  /// Javob internetdagi AI'dan keldimi yoki lokal yordamchidanmi.
  final bool online;
}

/// TEXNO AI sozlamalari.
class AiConfig {
  const AiConfig({
    this.apiKey = '',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-4o-mini',
  });

  final String apiKey;
  final String baseUrl;
  final String model;

  bool get isEnabled => apiKey.trim().isNotEmpty;

  AiConfig copyWith({String? apiKey, String? baseUrl, String? model}) =>
      AiConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
      );
}

/// TEXNO AI — mahsulot tanlashda yordam beruvchi maslahatchi.
///
/// Ikki rejimda ishlaydi:
///  1. **Onlayn** — API kalit kiritilgan bo'lsa, OpenAI-uyg'un API'ga so'rov
///     yuboriladi. Kontekst sifatida faqat lokal bazadagi mahsulotlar
///     beriladi, shuning uchun AI mavjud bo'lmagan tovarni tavsiya qilmaydi.
///  2. **Oflayn** — internet yoki kalit bo'lmasa, qurilma ichidagi qoidalarga
///     asoslangan yordamchi ishlaydi: byudjet, kategoriya va maqsadni
///     tushunib, bazadan mos mahsulotlarni tanlaydi.
class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration timeout = Duration(seconds: 30);

  static const String systemPrompt = '''
Sen "TEXNO BOZOR" ilovasining yordamchisisan. Foydalanuvchiga elektronika
tanlashda yordam berasan. Faqat o'zbek tilida, qisqa va aniq javob ber.
Sizga do'kondagi mahsulotlar ro'yxati beriladi — faqat shu ro'yxatdagi
mahsulotlarni tavsiya qil. Javob oxirida tavsiya qilgan mahsulotlaringning
ID larini shu ko'rinishda yoz: [IDS: id1, id2].
''';

  /// Onlayn yoki oflayn javob qaytaradi (hech qachon exception tashlamaydi).
  Future<AiReply> ask({
    required String question,
    required List<Product> catalog,
    required List<ChatMessage> history,
    AiConfig config = const AiConfig(),
  }) async {
    if (config.isEnabled) {
      try {
        return await _askOnline(
          question: question,
          catalog: catalog,
          history: history,
          config: config,
        );
      } catch (_) {
        // Internet yo'q yoki API xato qaytardi — oflayn yordamchiga o'tamiz.
      }
    }
    return offlineAnswer(question: question, catalog: catalog);
  }

  Future<AiReply> _askOnline({
    required String question,
    required List<Product> catalog,
    required List<ChatMessage> history,
    required AiConfig config,
  }) async {
    // Katalogni qisqartirib beramiz (token tejash uchun eng mos 60 ta).
    final shortlist = _shortlist(question, catalog, limit: 60);
    final catalogText = shortlist
        .map((p) => '${p.id} | ${p.name} | ${p.brand} | ${p.price} so\u2018m'
            '${p.inStock ? '' : ' | omborda yo\u2018q'}')
        .join('\n');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'system',
        'content': 'Do\u2018kondagi mahsulotlar:\n$catalogText',
      },
      for (final m in history.take(10))
        {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      {'role': 'user', 'content': question},
    ];

    final url = '${config.baseUrl.replaceAll(RegExp(r'/+$'), '')}'
        '/chat/completions';
    final response = await _client
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer ${config.apiKey}',
          },
          body: jsonEncode({
            'model': config.model,
            'messages': messages,
            'temperature': 0.4,
            'max_tokens': 600,
          }),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('AI xatolik: ${response.statusCode}');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    final content =
        json['choices']?[0]?['message']?['content']?.toString().trim() ?? '';
    if (content.isEmpty) throw Exception('AI bo\u2018sh javob qaytardi');

    return AiReply(
      text: _stripIds(content),
      productIds: _extractIds(content, catalog),
      online: true,
    );
  }

  static String _stripIds(String text) =>
      text.replaceAll(RegExp(r'\[IDS:[^\]]*\]'), '').trim();

  static List<String> _extractIds(String text, List<Product> catalog) {
    final match = RegExp(r'\[IDS:([^\]]*)\]').firstMatch(text);
    final valid = {for (final p in catalog) p.id};
    if (match != null) {
      return match
          .group(1)!
          .split(',')
          .map((e) => e.trim())
          .where(valid.contains)
          .take(6)
          .toList();
    }
    // ID lar berilmagan bo'lsa — matnda mahsulot nomlarini qidiramiz.
    final lower = text.toLowerCase();
    return catalog
        .where((p) => lower.contains(p.name.toLowerCase()))
        .map((p) => p.id)
        .take(6)
        .toList();
  }

  // -------------------------------------------------------------------------
  // OFLAYN YORDAMCHI (internetsiz ishlaydi)
  // -------------------------------------------------------------------------

  /// Kategoriya kalit so'zlari: savoldan nima izlayotganini aniqlash uchun.
  static const Map<String, List<String>> categoryKeywords = {
    'laptops': ['noutbuk', 'laptop', 'notebook', 'macbook', 'kompyuter olib'],
    'phones': ['telefon', 'smartfon', 'iphone', 'samsung galaxy', 'redmi'],
    'tablets': ['planshet', 'ipad', 'tablet'],
    'watches': ['soat', 'watch', 'brasl', 'fitnes'],
    'headphones': ['quloqchin', 'naushnik', 'airpods', 'audio', 'eshit'],
    'monitors': ['monitor', 'ekran'],
    'gpu': ['videokarta', 'gpu', 'rtx', 'radeon', 'grafik'],
    'cpu': ['protsessor', 'cpu', 'ryzen', 'intel core'],
    'ram': ['operativ', 'ram', 'ddr4', 'ddr5', 'xotira moduli'],
    'ssd': ['ssd', 'nvme', 'disk tez'],
    'hdd': ['qattiq disk', 'hdd'],
    'motherboard': ['motherboard', 'ona plata', 'materinka'],
    'psu': ['quvvat bloki', 'psu', 'blok pitaniya'],
    'case': ['korpus', 'case'],
    'cooler': ['sovutgich', 'kuler', 'cooler'],
    'desktops': ['sistemnik', 'sistema blok', 'yig\u2018ilgan kompyuter'],
    'tv': ['televizor', 'tv'],
    'printers': ['printer', 'chop'],
    'routers': ['router', 'wifi', 'internet uzat'],
    'cameras': ['kamera', 'fotoapparat', 'gopro'],
    'consoles': ['konsol', 'playstation', 'ps5', 'xbox', 'nintendo'],
    'gaming': ['gaming', 'geympad', 'rul'],
    'powerbank': ['powerbank', 'quvvat banki', 'zaryad banki'],
    'chargers': ['zaryadlagich', 'adapter', 'quvvatlagich'],
    'cables': ['kabel', 'shnur', 'provod'],
    'smarthome': ['aqlli uy', 'robot', 'smart home', 'chang yut'],
    'keyboards': ['klaviatura', 'keyboard'],
    'mice': ['sichqoncha', 'mishka', 'mouse'],
  };

  /// Qurilma ichidagi qoidalarga asoslangan javob.
  static AiReply offlineAnswer({
    required String question,
    required List<Product> catalog,
  }) {
    final q = question.toLowerCase().trim();

    if (q.isEmpty) {
      return const AiReply(
        text: 'Savolingizni yozing — masalan: "500 ming so\u2018mgacha '
            'quloqchin kerak" yoki "o\u2018yin uchun noutbuk tanlab bering".',
      );
    }

    // Salomlashish.
    if (RegExp(r'\b(salom|assalom|hayrli|hello|hi)\b').hasMatch(q)) {
      return const AiReply(
        text: 'Assalomu alaykum! Men TEXNO AI — mahsulot tanlashda yordam '
            'beraman. Byudjetingiz va maqsadingizni yozing, men mos '
            'variantlarni topib beraman.',
      );
    }

    final budget = parseBudget(q);
    final categoryId = detectCategory(q);
    final matches = _shortlist(q, catalog, limit: 200);

    var filtered = matches.where((p) {
      if (categoryId != null && p.categoryId != categoryId) return false;
      if (budget != null && p.price > budget) return false;
      return true;
    }).toList();

    // Byudjetga hech nima to'g'ri kelmasa — eng arzonlarini ko'rsatamiz.
    if (filtered.isEmpty && budget != null) {
      final byCategory = catalog
          .where((p) => categoryId == null || p.categoryId == categoryId)
          .toList()
        ..sort((a, b) => a.price.compareTo(b.price));
      if (byCategory.isNotEmpty) {
        final cheapest = byCategory.take(3).toList();
        return AiReply(
          text: '${formatPrice(budget)} byudjetga mos variant topilmadi. '
              'Eng arzon variantlar: ${cheapest.first.name} — '
              '${formatPrice(cheapest.first.price)}. Byudjetni biroz '
              'oshirsangiz tanlov kengayadi.',
          productIds: cheapest.map((p) => p.id).toList(),
        );
      }
    }

    if (filtered.isEmpty) {
      return const AiReply(
        text: 'Afsuski mos mahsulot topilmadi. Boshqacha yozib ko\u2018ring: '
            'masalan "gaming noutbuk 15 mln gacha".',
      );
    }

    // Reyting va ommaboplik bo'yicha eng yaxshi 3 tasi.
    filtered.sort((a, b) {
      final score = (b.rating * 10 + b.popularity / 10)
          .compareTo(a.rating * 10 + a.popularity / 10);
      return score;
    });
    final top = filtered.take(3).toList();

    final buffer = StringBuffer();
    if (budget != null) {
      buffer.writeln(
          '${formatPrice(budget)} gacha ${top.length} ta mos variant topdim:');
    } else {
      buffer.writeln('Sizga mos ${top.length} ta variantni tanladim:');
    }
    for (var i = 0; i < top.length; i++) {
      final p = top[i];
      buffer.writeln('${i + 1}. ${p.name} — ${formatPrice(p.price)}'
          '${p.hasDiscount ? ' (${p.discountPercent}% chegirma)' : ''}, '
          'reyting ${p.rating.toStringAsFixed(1)}');
    }
    buffer.write('\nBatafsil ma\u2018lumot uchun mahsulot ustiga bosing.');

    return AiReply(
      text: buffer.toString().trim(),
      productIds: top.map((p) => p.id).toList(),
    );
  }

  /// Savoldagi byudjetni aniqlaydi: "5 mln", "500 ming", "3000000".
  static int? parseBudget(String text) {
    final q = text.toLowerCase().replaceAll(RegExp(r'[\u00A0\s]+'), ' ');

    final mln = RegExp(r'(\d+(?:[.,]\d+)?)\s*(mln|million|milion|m\b)')
        .firstMatch(q);
    if (mln != null) {
      final value = double.tryParse(mln.group(1)!.replaceAll(',', '.'));
      if (value != null) return (value * 1000000).round();
    }

    final ming = RegExp(r'(\d+(?:[.,]\d+)?)\s*(ming|k\b|tys)').firstMatch(q);
    if (ming != null) {
      final value = double.tryParse(ming.group(1)!.replaceAll(',', '.'));
      if (value != null) return (value * 1000).round();
    }

    final plain = RegExp(r'\b(\d{6,9})\b').firstMatch(q);
    if (plain != null) return int.tryParse(plain.group(1)!);

    return null;
  }

  /// Savoldan kategoriya aniqlash.
  static String? detectCategory(String text) {
    final q = text.toLowerCase();
    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (q.contains(keyword)) return entry.key;
      }
    }
    return null;
  }

  /// Savolga eng mos mahsulotlarni tartiblab qaytaradi.
  static List<Product> _shortlist(
    String question,
    List<Product> catalog, {
    int limit = 60,
  }) {
    final q = question.toLowerCase();
    final tokens =
        q.split(RegExp(r'[^\wа-яёʻʼ‘’]+')).where((t) => t.length > 2).toList();
    final categoryId = detectCategory(q);

    final scored = catalog.map((p) {
      var score = p.popularity ~/ 10 + (p.rating * 2).round();
      if (categoryId != null && p.categoryId == categoryId) score += 50;
      final haystack =
          '${p.name} ${p.brand} ${p.specs.values.join(' ')}'.toLowerCase();
      for (final t in tokens) {
        if (haystack.contains(t)) score += 15;
      }
      if (!p.inStock) score -= 30;
      return (product: p, score: score);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(limit).map((e) => e.product).toList();
  }

  void close() => _client.close();
}

/// Narxni matn ichida ko'rsatish (AI javoblari uchun kichik yordamchi).
String formatPrice(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '$buffer so\u2018m';
}
