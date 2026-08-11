import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Ilova ochilishida ko'rinadigan ekran (baza tayyorlanayotganda).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.bolt_rounded,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 22),
              const Text(
                'TEXNO BOZOR',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Elektronika marketplace',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 36),
              if (error == null)
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else ...[
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Ma\u2018lumotlar bazasini ochib bo\u2018lmadi:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                if (onRetry != null)
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Qayta urinish'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
