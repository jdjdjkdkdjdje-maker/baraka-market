import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_widgets.dart';

/// Lokal login: ism + telefon raqam YOKI Google hisobi.
/// Keyinchalik OTP / haqiqiy Google OAuth bilan almashtiriladigan
/// arxitektura (AuthService interfeysi).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 2) {
      _showError('Ismingizni kiriting');
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 9) {
      _showError('Telefon raqamini to\u2018liq kiriting');
      return;
    }

    setState(() => _loading = true);
    final error = await ref
        .read(appStateProvider)
        .login(name: name, phone: phone);
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showError(error);
    } else {
      context.go('/home');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _googleSignIn() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _GoogleSignInSheet(
        onDone: (name, email) async {
          Navigator.pop(sheetContext);
          final error = await ref
              .read(appStateProvider)
              .login(name: name, phone: email);
          if (!mounted) return;
          if (error != null) {
            _showError(error);
          } else {
            context.go('/home');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: GradientLogo(size: 84)),
              const SizedBox(height: 22),
              const Center(
                child: Text(
                  'TEXNO BOZOR',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Xush kelibsiz! Davom etish uchun ma\u2018lumotlaringizni kiriting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textDim, fontSize: 13.5),
                ),
              ),
              const SizedBox(height: 32),

              // ----- Google bilan kirish
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _googleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF3C4043),
                    side: const BorderSide(color: Color(0xFFDADCE0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GoogleLogo(size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Google bilan kirish',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3C4043),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ----- Ajratuvchi
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'yoki',
                        style: TextStyle(
                          color: AppColors.textDim.withOpacity(0.8),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),

              const Text('Ismingiz',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Masalan: Aziz',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Telefon raqamingiz',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+998 90 123 45 67',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: GradientBox(
                  onTap: _loading ? null : _submit,
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Davom etish',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: AppColors.textDim),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ma\u2018lumotlar faqat telefoningizda saqlanadi. Keyinchalik OTP tasdiqlash qo\u2018shiladi.',
                      style:
                          TextStyle(fontSize: 11.5, color: AppColors.textDim),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Google uslubidagi hisob tanlash paneli (lokal rejim).
class _GoogleSignInSheet extends StatefulWidget {
  const _GoogleSignInSheet({required this.onDone});

  final void Function(String name, String email) onDone;

  @override
  State<_GoogleSignInSheet> createState() => _GoogleSignInSheetState();
}

class _GoogleSignInSheetState extends State<_GoogleSignInSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ismingizni kiriting')),
      );
      return;
    }
    if (!email.contains('@') || email.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To\u2018g\u2018ri Gmail manzilini kiriting')),
      );
      return;
    }
    widget.onDone(name, email);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GoogleLogo(size: 36),
          const SizedBox(height: 14),
          const Text(
            'Hisob tanlang',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'TEXNO BOZOR ga davom etish uchun',
            style: TextStyle(fontSize: 13, color: AppColors.textDim),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ismingiz',
              hintText: 'Masalan: Aziz',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Gmail manzilingiz',
              hintText: 'siz@gmail.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Davom etish'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hozircha lokal rejim: hisob ma\u2018lumotlari faqat telefoningizda saqlanadi. Server ulangach haqiqiy Google OAuth ishlatiladi.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10.5, color: AppColors.textDim, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Google "G" logotipi — CustomPainter bilan chiziladi (assetsiz).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.23;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..color = color;

    final deg = math.pi / 180;
    canvas.drawArc(rect, 225 * deg, 90 * deg, false, arc(_red));
    canvas.drawArc(rect, 135 * deg, 90 * deg, false, arc(_yellow));
    canvas.drawArc(rect, 45 * deg, 90 * deg, false, arc(_green));
    canvas.drawArc(rect, -45 * deg, 90 * deg, false, arc(_blue));

    // Ko'k gorizontal chiziq ("G" ning tayoqchasi)
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        size.width,
        center.dy + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
