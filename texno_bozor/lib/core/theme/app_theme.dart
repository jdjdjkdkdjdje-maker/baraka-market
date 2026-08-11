import 'package:flutter/material.dart';

/// TEXNO BOZOR ranglari — premium, zamonaviy "dark tech" uslub.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF0B1120);
  static const Color surface = Color(0xFF101A2E);
  static const Color card = Color(0xFF16223C);
  static const Color cardLight = Color(0xFF1D2B4A);
  static const Color border = Color(0xFF253453);
  static const Color primary = Color(0xFF22D3EE);
  static const Color primaryDark = Color(0xFF0E7490);
  static const Color accent = Color(0xFF818CF8);
  static const Color text = Color(0xFFF1F5F9);
  static const Color textDim = Color(0xFF8FA3BF);
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const List<Color> gradient = [Color(0xFF06B6D4), Color(0xFF6366F1)];
  static const List<Color> gradientWarm = [Color(0xFFF59E0B), Color(0xFFEF4444)];
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Color(0xFF04222B),
      secondary: AppColors.accent,
      onSecondary: Color(0xFF141534),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: Color(0xFF3B0A0A),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: null, // Tizim shrifti (Roboto) — tez va toza
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.18),
        height: 66,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF04222B),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          textStyle: const TextStyle(
              fontSize: 15.5, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardLight,
        contentTextStyle: const TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerColor: AppColors.border,
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.primary.withOpacity(0.22),
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Gradient fonli container — tugma, banner va kartalarda qo'llanadi.
class GradientBox extends StatelessWidget {
  const GradientBox({
    super.key,
    required this.child,
    this.colors = AppColors.gradient,
    this.borderRadius = 14,
    this.onTap,
  });

  final Widget child;
  final List<Color> colors;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: child,
        ),
      ),
    );
  }
}
