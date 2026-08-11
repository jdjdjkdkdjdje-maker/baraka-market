import 'dart:convert';

/// Texnik xususiyatlar JSON satrini xavfsiz parse qilish.
Map<String, String> parseSpecs(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
  } catch (_) {}
  return {};
}

String encodeSpecs(Map<String, String> specs) => jsonEncode(specs);

int? specInt(Map<String, String> specs, String key) {
  final raw = specs[key];
  if (raw == null) return null;
  return int.tryParse(raw.replaceAll(RegExp(r'[^0-9-]'), ''));
}
