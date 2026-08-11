import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_models.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/connectivity_service.dart';

const List<String> _suggestions = [
  'RTX 5070 uchun qanday protsessor mos?',
  '10 mln so\u2018mgacha smartfon tavsiya qil',
  'Gaming kompyuter yig\u2018ishga yordam ber',
  'iPhone 15 va Galaxy S24 ni taqqosla',
  'Noutbuk tanlashda nimalarga e\u2018tibor berish kerak?',
];

/// TEXNO AI — internet orqali ishlaydigan yagona modul.
/// Internetsiz: "Internetga ulanishingiz kerak." xabari chiqadi.
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _sending) return;

    _controller.clear();
    setState(() {
      _messages.add(AiMessage(role: 'user', text: message));
      _sending = true;
    });
    _scrollToBottom();

    try {
      // 1) Internet tekshiruvi.
      final online = await ConnectivityService().isOnline;
      if (!online) {
        throw const AiNetworkException('Internetga ulanishingiz kerak.');
      }

      // 2) AI faqat lokal bazadagi mahsulotlarni ko'radi.
      final matched =
          await ref.read(productRepositoryProvider).search(message);
      final contextProducts = matched.isNotEmpty
          ? matched.take(6).toList()
          : (await ref.read(productRepositoryProvider).getAll())
              .take(6)
              .toList();
      final productContext =
          ref.read(aiServiceProvider).buildProductContext(contextProducts);

      // 3) Tarix (oxirgi 8 xabar).
      final history = _messages
          .where((m) => m != _messages.last)
          .toList()
          .reversed
          .take(8)
          .toList()
          .reversed
          .map((m) => {'role': m.role, 'content': m.text})
          .toList();

      final answer = await ref.read(aiServiceProvider).ask(
            userMessage: message,
            productContext: productContext,
            history: history,
          );

      if (!mounted) return;
      setState(() => _messages.add(AiMessage(role: 'assistant', text: answer)));
    } on AiNoKeyException catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(AiMessage(role: 'assistant', text: '$e')));
    } on AiNetworkException catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(AiMessage(role: 'assistant', text: '$e')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(AiMessage(
          role: 'assistant',
          text: 'Kutilmagan xatolik yuz berdi. Qayta urinib ko\u2018ring.')));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(connectivityProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('TEXNO AI'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: online
                  ? AppColors.success.withOpacity(0.14)
                  : AppColors.danger.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 14,
                  color: online ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  online ? 'Onlayn' : 'Oflayn',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: online ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!online)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.danger.withOpacity(0.12),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 18, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Internetga ulanishingiz kerak. TEXNO AI faqat internet orqali ishlaydi — qolgan funksiyalar internetsiz ham davom etadi.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChat(onSuggestion: _send)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) =>
                        _Bubble(message: _messages[i]),
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypingIndicator(),
              ),
            ),

          // Tavsiyalar
          if (_messages.isEmpty)
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ActionChip(
                  label: Text(_suggestions[i]),
                  onPressed: () => _send(_suggestions[i]),
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Kiritish maydoni
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: const InputDecoration(
                      hintText: 'Savolingizni yozing...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GradientBox(
                  borderRadius: 12,
                  onTap: _sending ? null : () => _send(_controller.text),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.gradient
                      .map((c) => c.withOpacity(0.15))
                      .toList(),
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  size: 46, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'TEXNO AI ga xush kelibsiz!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Texnika tanlash, taqqoslash, xususiyatlarni tushuntirish va kompyuter yig\u2018ish bo\u2018yicha yordam beraman. Javoblarim faqat ilovadagi real mahsulotlarga asoslanadi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textDim, height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions
                  .take(3)
                  .map((s) => ActionChip(
                        label: Text(s),
                        onPressed: () => onSuggestion(s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: AppColors.gradient)
              : null,
          color: isUser ? null : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Icon(Icons.smart_toy_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isUser ? Colors.white : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            SizedBox(width: 10),
            Text(
              'TEXNO AI o\u2018ylamoqda...',
              style: TextStyle(fontSize: 12, color: AppColors.textDim),
            ),
          ],
        ),
      ),
    );
  }
}
