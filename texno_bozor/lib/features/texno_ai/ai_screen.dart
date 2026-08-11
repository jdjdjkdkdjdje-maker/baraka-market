import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';

/// TEXNO AI — mahsulot tanlash bo'yicha yordamchi.
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static const List<String> _prompts = [
    'O\u2018yin uchun 15 mln so\u2018mgacha noutbuk',
    '500 ming so\u2018mgacha quloqchin',
    'Video montaj uchun kompyuter yig\u2018ib ber',
    'Eng yaxshi arzon smartfon qaysi?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();

    await ref.read(chatProvider.notifier).send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider).value ?? const <ChatMessage>[];
    final thinking = ref.watch(chatProvider.notifier).isThinking;
    final online = ref.watch(aiConfigProvider).isEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TEXNO AI', style: TextStyle(fontSize: 17)),
                Text(
                  online ? 'Onlayn rejim' : 'Oflayn rejim',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: online ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: 'Suhbatni tozalash',
              onPressed: () => ref.read(chatProvider.notifier).clear(),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          IconButton(
            tooltip: 'AI sozlamalari',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _welcome()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length + (thinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= messages.length) return _typing();
                      return _bubble(messages[index]);
                    },
                  ),
          ),
          _composer(thinking),
        ],
      ),
    );
  }

  Widget _welcome() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: AppColors.aiGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Salom! Men TEXNO AI',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'Byudjetingiz va maqsadingizni yozing — do\u2018kondagi '
          'mahsulotlardan eng mosini tanlab beraman.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Namuna savollar',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        for (final prompt in _prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _send(prompt),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          prompt,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                      ),
                      const Icon(Icons.north_east_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.82,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          if (message.productIds.isNotEmpty) _products(message.productIds),
        ],
      ),
    );
  }

  Widget _products(List<String> ids) {
    return FutureBuilder<List<Product>>(
      future: ref.read(productRepositoryProvider).getByIds(ids),
      builder: (context, snapshot) {
        final products = snapshot.data ?? const <Product>[];
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              for (final product in products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context)
                          .pushNamed('/product', arguments: product.id),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 54,
                              height: 54,
                              child: AppImage(source: product.image, radius: 8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        Format.price(product.price),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      RatingStars(
                                          rating: product.rating, size: 11),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ref
                                    .read(cartProvider.notifier)
                                    .add(product.id);
                                if (context.mounted) {
                                  showAppSnack(
                                      context, 'Savatga qo\u2018shildi');
                                }
                              },
                              icon: const Icon(Icons.add_shopping_cart_rounded,
                                  size: 19),
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _typing() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'O\u2018ylayapman...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer(bool thinking) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Savolingizni yozing...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: thinking ? AppColors.surfaceHigh : AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: thinking ? null : () => _send(),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: thinking ? AppColors.textMuted : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
