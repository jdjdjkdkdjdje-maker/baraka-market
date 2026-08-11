import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_widgets.dart';

/// Lokal login: ism + telefon raqam. Keyinchalik OTP-auth bilan
/// almashtiriladigan arxitektura (AuthService interfeysi).
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
              const SizedBox(height: 36),
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
