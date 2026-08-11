import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_widgets.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/backend_config.dart';

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
  final _serverUrlController = TextEditingController();
  final _serverTokenController = TextEditingController();
  bool _keyLoaded = false;
  bool _hasKey = false;
  bool _serverLoaded = false;
  bool _checkingServer = false;
  String? _serverStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadBackend() async {
    final config = ref.read(backendConfigProvider);
    if (!mounted) return;
    _serverUrlController.text = config.baseUrl;
    _serverTokenController.text = config.token;
    setState(() => _serverLoaded = true);
  }

  Future<void> _saveBackend(BackendMode mode) async {
    final config = BackendConfig(
      mode: mode,
      baseUrl: _serverUrlController.text.trim(),
      token: _serverTokenController.text.trim(),
    );
    await ref.read(backendConfigProvider.notifier).update(config);
    if (!mounted) return;
    setState(() => _serverStatus = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == BackendMode.local
              ? 'Lokal (offline) rejim yoqildi'
              : 'Server rejimi saqlandi',
        ),
      ),
    );
  }

  Future<void> _testServer() async {
    final url = _serverUrlController.text.trim();
    if (url.isEmpty) {
      setState(() => _serverStatus = 'Avval server manzilini kiriting');
      return;
    }
    setState(() {
      _checkingServer = true;
      _serverStatus = null;
    });
    final client = ApiClient(BackendConfig(
      mode: BackendMode.remote,
      baseUrl: url,
      token: _serverTokenController.text.trim(),
    ));
    final ok = await client.ping();
    if (!mounted) return;
    setState(() {
      _checkingServer = false;
      _serverStatus = ok
          ? 'Server javob berdi \u2713 (GET /health)'
          : 'Serverga ulanib bo\u2018lmadi';
    });
  }

  Future<void> _load() async {
    await _loadBackend();
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
    _serverUrlController.dispose();
    _serverTokenController.dispose();
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
    final mode = ref.watch(backendConfigProvider).mode;

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
          const Divider(height: 1),
          const SizedBox(height: 18),

          // ------------------------------------------------ MA'LUMOT MANBAI
          const Text(
            'Ma\u2018lumot manbai',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ilova sukut bo\u2018yicha telefon ichidagi bazada ishlaydi (internet kerak emas). '
            'Kelajakda REST API + PostgreSQL server tayyor bo\u2018lsa, uni shu yerda yoqasiz \u2014 '
            'ilovaning qolgan qismi o\u2018zgarmaydi.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textDim, height: 1.5),
          ),
          const SizedBox(height: 12),
          if (_serverLoaded)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<BackendMode>(
                  segments: const [
                    ButtonSegment(
                      value: BackendMode.local,
                      icon: Icon(Icons.phone_android_rounded, size: 18),
                      label: Text('Lokal'),
                    ),
                    ButtonSegment(
                      value: BackendMode.remote,
                      icon: Icon(Icons.cloud_outlined, size: 18),
                      label: Text('Server'),
                    ),
                  ],
                  selected: {mode},
                  onSelectionChanged: (selection) =>
                      _saveBackend(selection.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serverUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Server manzili (REST API base URL)',
                    hintText: 'https://api.texnobozor.uz/v1',
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serverTokenController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Token (ixtiyoriy)',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                ),
                if (_serverStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _serverStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _serverStatus!.contains('\u2713')
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _checkingServer ? null : _testServer,
                        icon: _checkingServer
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering_rounded),
                        label: const Text('Tekshirish'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _saveBackend(mode),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Saqlash'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  mode == BackendMode.local
                      ? 'Joriy rejim: ${BackendMode.local.label} \u2014 barcha ma\u2018lumot telefonda.'
                      : 'Joriy rejim: ${BackendMode.remote.label} \u2014 server ma\u2018lumoti lokal bazaga keshlanadi, internet yo\u2018qolsa ilova keshdan ishlaydi.',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textDim, height: 1.5),
                ),
              ],
            ),

          const SizedBox(height: 26),
          const Divider(height: 1),
          const SizedBox(height: 18),
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
