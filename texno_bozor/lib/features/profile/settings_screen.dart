import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_widgets.dart';

/// Sozlamalar: TEXNO AI kaliti, tarix, ilova haqida.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  bool _keyLoaded = false;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ai = ref.read(aiServiceProvider);
    final key = await ai.getApiKey();
    final baseUrl = await ai.getBaseUrl();
    final model = await ai.getModel();
    if (!mounted) return;
    _baseUrlController.text = baseUrl;
    _modelController.text = model;
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      _keyLoaded = true;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveAi() async {
    await ref.read(aiServiceProvider).saveSettings(
          apiKey: _apiKeyController.text.trim().isEmpty
              ? null
              : _apiKeyController.text.trim(),
          baseUrl: _baseUrlController.text.trim().isEmpty
              ? null
              : _baseUrlController.text.trim(),
          model: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
        );
    _apiKeyController.clear();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI sozlamalari saqlandi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TEXNO AI sozlamalari',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _keyLoaded
                ? (_hasKey
                    ? 'API kalit o\u2018rnatilgan \u2713'
                    : 'API kalit hali o\u2018rnatilmagan')
                : 'Yuklanmoqda...',
            style: TextStyle(
              fontSize: 12.5,
              color: _hasKey ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'AI API kaliti (yangi)',
              hintText: 'sk-...',
              prefixIcon: Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'API manzili (base URL)',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              prefixIcon: Icon(Icons.smart_toy_outlined),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kalit xavfsiz saqlashda (Secure Storage) ushlanadi va hech qayerga yuborilmaydi. .env fayl orqali ham sozlash mumkin.',
            style: TextStyle(fontSize: 11, color: AppColors.textDim, height: 1.5),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _saveAi,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Saqlash'),
          ),
          const SizedBox(height: 26),
          const Text(
            'Ma\u2018lumotlar',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(historyRepositoryProvider).clearSearchHistory();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Qidiruv tarixi tozalandi')),
              );
            },
            icon: const Icon(Icons.history_toggle_off_rounded),
            label: const Text('Qidiruv tarixini tozalash'),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    GradientLogo(size: 34),
                    SizedBox(width: 10),
                    Text(
                      AppConstants.appName,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Offline-first elektronika marketplace. Barcha ma\u2018lumotlar telefoningizda saqlanadi: katalog, savat, buyurtmalar, sevimlilar va PC yig\u2018ilmalar. Internet faqat TEXNO AI uchun kerak.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDim, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versiya: ${AppConstants.appVersion}  \u2022  Qo\u2018llab-quvvatlash: ${AppConstants.supportPhone}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
