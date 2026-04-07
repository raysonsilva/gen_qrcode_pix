import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Tokens estáticos (accent verde — igual em ambos os modos) ─────────────────
class AppColors {
  AppColors._();

  // Accent verde PIX (igual em light e dark)
  static const primary = Color(0xFF00C896);
  static const primaryDim = Color(0xFF00A87E);
  static const onPrimary = Color(0xFFFFFFFF);

  // ── Light ──────────────────────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFEFF2F6);
  static const lightOutline = Color(0xFFDDE2EA);
  static const lightOnSurface = Color(0xFF1A1F2E);
  static const lightOnSurfaceVariant = Color(0xFF6B7A99);
  static const lightError = Color(0xFFE53935);
  static const lightErrorContainer = Color(0xFFFFEBEE);

  // ── Dark ───────────────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF0D1B2A);
  static const darkSurface = Color(0xFF1A2B3C);
  static const darkSurfaceVariant = Color(0xFF243447);
  static const darkOutline = Color(0xFF2E4057);
  static const darkOnSurface = Color(0xFFE8EDF5);
  static const darkOnSurfaceVariant = Color(0xFF7A90B0);
  static const darkError = Color(0xFFEF5350);
  static const darkErrorContainer = Color(0xFF3B1A1A);
}

// ── Helpers para acessar tokens via contexto ──────────────────────────────────
extension AppColorsX on ColorScheme {
  Color get appBackground => brightness == Brightness.light
      ? AppColors.lightBackground
      : AppColors.darkBackground;
}

class AppTheme {
  AppTheme._();

  static const double radiusCard = 16;
  static const double radiusInput = 12;
  static const double radiusButton = 12;

  // ── Light ──────────────────────────────────────────────────────────────────
  static ThemeData light() => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    outline: AppColors.lightOutline,
    onSurface: AppColors.lightOnSurface,
    onSurfaceVariant: AppColors.lightOnSurfaceVariant,
    error: AppColors.lightError,
    errorContainer: AppColors.lightErrorContainer,
    primaryContainer: const Color(0xFFD0F5EC),
    onPrimaryContainer: const Color(0xFF003D2B),
    statusBarIconBrightness: Brightness.dark,
    navBarIconBrightness: Brightness.dark,
  );

  // ── Dark ───────────────────────────────────────────────────────────────────
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    outline: AppColors.darkOutline,
    onSurface: AppColors.darkOnSurface,
    onSurfaceVariant: AppColors.darkOnSurfaceVariant,
    error: AppColors.darkError,
    errorContainer: AppColors.darkErrorContainer,
    primaryContainer: const Color(0xFF004D3A),
    onPrimaryContainer: const Color(0xFFB2F5E0),
    statusBarIconBrightness: Brightness.light,
    navBarIconBrightness: Brightness.light,
  );

  // ── Builder interno ────────────────────────────────────────────────────────
  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceVariant,
    required Color outline,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color error,
    required Color errorContainer,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Brightness statusBarIconBrightness,
    required Brightness navBarIconBrightness,
  }) {
    final cs = ColorScheme(
      brightness: brightness,
      // primary
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      // secondary
      secondary: AppColors.primaryDim,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: primaryContainer,
      onSecondaryContainer: onSurface,
      // tertiary
      tertiary: AppColors.primary,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: primaryContainer,
      onTertiaryContainer: onSurface,
      // error
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: error,
      // surface
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerHighest: surfaceVariant,
      // outline
      outline: outline,
      outlineVariant: outline,
      // misc
      shadow: const Color(0x1A000000),
      scrim: const Color(0x52000000),
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: AppColors.primaryDim,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: background,
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: const Color(0x14000000),
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        actionsIconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarIconBrightness,
          systemNavigationBarColor: surface,
          systemNavigationBarIconBrightness: navBarIconBrightness,
        ),
      ),
      // Card
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: outline),
        ),
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        labelStyle: TextStyle(color: onSurfaceVariant),
        hintStyle: TextStyle(color: onSurfaceVariant),
        prefixIconColor: onSurfaceVariant,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      // Divider
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(color: surface, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: onSurfaceVariant, fontSize: 14),
      ),
      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),
      // PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        textStyle: TextStyle(color: onSurface, fontSize: 14),
      ),
      // Icon
      iconTheme: IconThemeData(color: onSurface),
    );
  }
}
