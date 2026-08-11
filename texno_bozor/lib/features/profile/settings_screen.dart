import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/remote/api_client.dart';
import '../../data/services/ai_service.dart';

/// SOZLAMALAR — TEXNO AI kaliti va ma'lumot manbai (lokal / server).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const String keyAiApiKey = 'ai_api_key';
  static const String keyAiBaseUrl = 'ai_base_url';
  static const String keyAiModel = 'ai_model';
  static const String keyApiBaseUrl = 'api_base_url';
  static const String keyApiToken = 'api_token';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _aiKeyController = TextEditingController();
  final _aiUrlController = TextEditingController();
  final _aiModelController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _apiTokenController = TextEditingController();

  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final ai = ref.read(aiConfigProvider);
    final api = ref.read(apiConfigProvider);
    _aiKeyController.text = ai.apiKey;
    _aiUrlController.text = ai.baseUrl;
    _aiModelController.text = ai.model;
    _apiUrlController.text = api.baseUrl;
    _apiTokenController.text = api.token;
  }

  @override
  void dispose() {
    _aiKeyController.dispose();
    _aiUrlController.dispose();
    _aiModelController.dispose();
    _apiUrlController.dispose();
    _apiTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.watch(apiConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _card(
            title: 'TEXNO AI',
            subtitle:
                'API kalit kiritilsa AI internetdan javob beradi. Bo\u2018sh '
                'qoldirsangiz ham ishlaydi — qurilma ichidagi yordamchi '
                'rejimida.',
            children: [
              TextField(
                controller: _aiKeyController,
                obscureText: _obscureKey,
                decoration: InputDecoration(
                  labelText: 'API kalit',
                  hintText: 'sk-...',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureKey = !_obscureKey),
                    icon: Icon(
                      _obscureKey
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aiUrlController,
                decoration: const InputDecoration(
                  labelText: 'API manzili',
                  hintText: 'https://api.openai.com/v1',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aiModelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'gpt-4o-mini',
                  prefixIcon: Icon(Icons.smart_toy_outlined),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _saveAi,
                child: const Text('AI sozlamalarini saqlash'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            title: 'Ma\u2018lumot manbai',
            subtitle: api.isEnabled
                ? 'Hozir server rejimi yoqilgan. Internet bo\u2018lmasa '
                    'ilova avtomatik lokal bazadan o\u2018qiydi.'
                : 'Hozir ilova to\u2018liq oflayn ishlayapti — barcha '
                    'ma\u2018lumot telefon ichida. REST API tayyor '
                    'bo\u2018lganda shu yerga server manzilini kiriting.',
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (api.isEnabled ? AppColors.accent : AppColors.success)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      api.isEnabled
                          ? Icons.cloud_rounded
                          : Icons.phone_android_rounded,
                      size: 18,
                      color: api.isEnabled
                          ? AppColors.accent
                          : AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      api.isEnabled
                          ? 'Rejim: Server (REST API)'
                          : 'Rejim: Lokal (offline)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: api.isEnabled
                            ? AppColors.accent
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiUrlController,
                decoration: const InputDecoration(
                  labelText: 'Server manzili',
                  hintText: 'https://api.texnobozor.uz/v1',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiTokenController,
                decoration: const InputDecoration(
                  labelText: 'Token (ixtiyoriy)',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _disableRemote,
                      child: const Text('Oflayn'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveApi,
                      child: const Text('Serverni ulash'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            title: 'Ma\u2018lumotlar',
            subtitle: 'Qurilmadagi ma\u2018lumotlarni boshqarish.',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_rounded,
                    color: AppColors.textSecondary),
                title: const Text('Qidiruv tarixini tozalash',
                    style: TextStyle(fontSize: 14)),
                onTap: () async {
                  await ref.read(historyRepositoryProvider).clearSearches();
                  ref.invalidate(recentSearchesProvider);
                  if (mounted) showAppSnack(context, 'Tarix tozalandi');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_sweep_rounded,
                    color: AppColors.danger),
                title: const Text('Savatni bo\u2018shatish',
                    style: TextStyle(fontSize: 14)),
                onTap: () async {
                  await ref.read(cartProvider.notifier).clear();
                  if (mounted) showAppSnack(context, 'Savat tozalandi');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Future<void> _saveAi() async {
    final config = AiConfig(
      apiKey: _aiKeyController.text.trim(),
      baseUrl: _aiUrlController.text.trim().isEmpty
          ? 'https://api.openai.com/v1'
          : _aiUrlController.text.trim(),
      model: _aiModelController.text.trim().isEmpty
          ? 'gpt-4o-mini'
          : _aiModelController.text.trim(),
    );
    ref.read(aiConfigProvider.notifier).state = config;

    final users = ref.read(userRepositoryProvider);
    await users.setSetting(SettingsScreen.keyAiApiKey, config.apiKey);
    await users.setSetting(SettingsScreen.keyAiBaseUrl, config.baseUrl);
    await users.setSetting(SettingsScreen.keyAiModel, config.model);

    if (mounted) {
      showAppSnack(
        context,
        config.isEnabled
            ? 'TEXNO AI onlayn rejimga o\u2018tdi'
            : 'AI oflayn rejimda ishlaydi',
      );
    }
  }

  Future<void> _saveApi() async {
    final config = ApiConfig(
      baseUrl: _apiUrlController.text.trim(),
      token: _apiTokenController.text.trim(),
    );
    ref.read(apiConfigProvider.notifier).state = config;

    final users = ref.read(userRepositoryProvider);
    await users.setSetting(SettingsScreen.keyApiBaseUrl, config.baseUrl);
    await users.setSetting(SettingsScreen.keyApiToken, config.token);

    _invalidateData();
    if (mounted) {
      showAppSnack(
        context,
        config.isEnabled
            ? 'Server ulandi — ma\u2018lumot REST API dan olinadi'
            : 'Manzil bo\u2018sh: lokal rejim',
      );
    }
  }

  Future<void> _disableRemote() async {
    _apiUrlController.clear();
    _apiTokenController.clear();
    ref.read(apiConfigProvider.notifier).state = const ApiConfig();

    final users = ref.read(userRepositoryProvider);
    await users.setSetting(SettingsScreen.keyApiBaseUrl, '');
    await users.setSetting(SettingsScreen.keyApiToken, '');

    _invalidateData();
    if (mounted) showAppSnack(context, 'Oflayn rejim yoqildi');
  }

  void _invalidateData() {
    ref.invalidate(allProductsProvider);
    ref.invalidate(popularProductsProvider);
    ref.invalidate(newProductsProvider);
    ref.invalidate(discountedProductsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(filteredProductsProvider);
    ref.read(cartProvider.notifier).refresh();
    ref.read(ordersProvider.notifier).refresh();
  }
}
