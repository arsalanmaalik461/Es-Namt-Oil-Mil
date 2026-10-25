import 'package:flutter/material.dart';
import 'package:namt_oil_mil/navigation/page_transitions.dart';

/// Brand palette for "Namt Oil Mil".
///
/// Deep emerald (0xFF0E6B4A) + dark navy (0xFF1F2A44) + warm gold (0xFFC99A2B).
class AppColors {
  // --- Brand ---
  static const Color emerald = Color(0xFF0E6B4A);
  static const Color emeraldDark = Color(0xFF0A4F37);
  static const Color emeraldLight = Color(0xFFDCEFE4);
  static const Color navy = Color(0xFF1F2A44);
  static const Color gold = Color(0xFFC99A2B);
  static const Color goldLight = Color(0xFFFBF3DF);
  static const Color offWhite = Color(0xFFF7F5F0);

  // --- Dark surfaces ---
  static const Color charcoal = Color(0xFF121417);
  static const Color charcoalCard = Color(0xFF1B1E22);
  static const Color emeraldOnDark = Color(0xFF5FC795);
  static const Color goldOnDark = Color(0xFFE0B94F);

  // --- Ledger semantics ---
  /// Customer owes us (debit / udhaar) -> red.
  static const Color debit = Color(0xFFC62828);

  /// Advance / settled (credit) -> green.
  static const Color credit = Color(0xFF2E7D32);
  static const Color debitOnDark = Color(0xFFEF9A9A);
  static const Color creditOnDark = Color(0xFFA5D6A7);

  // --- Pastel surfaces (v2 "soft khata" look) ---
  /// Receivable ("lene hain") pastel backgrounds.
  static const Color pastelPink = Color(0xFFFDECEA);
  static const Color pastelPinkDeep = Color(0xFFF8CFC9);
  static const Color pastelPinkText = Color(0xFFD32F2F);

  /// Payable / settled ("dene hain") pastel backgrounds.
  static const Color pastelGreen = Color(0xFFE6F4EA);
  static const Color pastelGreenDeep = Color(0xFFC3E6CB);
  static const Color pastelGreenText = Color(0xFF1E7E34);

  /// Info banners.
  static const Color pastelBlue = Color(0xFFE3F2FD);
  static const Color pastelBlueDeep = Color(0xFFBBDEFB);
  static const Color pastelBlueText = Color(0xFF1565C0);

  /// Warm neutral.
  static const Color pastelAmber = Color(0xFFFFF8E1);
  static const Color pastelAmberText = Color(0xFFF57F17);

  /// Soft app background (v2).
  static const Color softBackground = Color(0xFFF5F7FA);

  /// Near-black CTA buttons (v2).
  static const Color inkButton = Color(0xFF1B1B1B);

  const AppColors._();
}

/// Material 3 themes for the app.
class AppTheme {
  static ThemeData get lightTheme {
    // fromSeed + copyWith (instead of the raw ColorScheme constructor) so
    // the theme keeps compiling across Flutter versions even if new
    // scheme fields are added.
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.emerald,
      onPrimary: Colors.white,
      primaryContainer: AppColors.emeraldLight,
      onPrimaryContainer: AppColors.emeraldDark,
      secondary: AppColors.navy,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFDCE1EC),
      onSecondaryContainer: AppColors.navy,
      tertiary: AppColors.gold,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.goldLight,
      onTertiaryContainer: const Color(0xFF6B5113),
      error: AppColors.debit,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF1B1B1B),
      surfaceContainerHighest: const Color(0xFFEDEBE4),
      surfaceContainer: const Color(0xFFF1EFE9),
      onSurfaceVariant: const Color(0xFF4F4A41),
      outline: const Color(0xFFBDB7A8),
      outlineVariant: const Color(0xFFDAD6C9),
      inverseSurface: const Color(0xFF2A2A2A),
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.emeraldOnDark,
      surfaceTint: AppColors.emerald,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: buildAppPageTransitionsTheme(),
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.softBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emerald,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.emerald,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle:
            TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.emeraldLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          // 11px so long labels ("Transactions") fit on ONE line in a
          // 72px-wide destination on 360px phones — no two-line wrap.
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.emerald,
            );
          }
          return const TextStyle(fontSize: 11, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.emerald);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.emeraldLight,
        selectedIconTheme: IconThemeData(color: AppColors.emerald),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.emerald,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B1B1B),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.emeraldLight,
        checkmarkColor: AppColors.emerald,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.emeraldOnDark,
      onPrimary: const Color(0xFF0B2E20),
      primaryContainer: const Color(0xFF0B3B29),
      onPrimaryContainer: const Color(0xFFDCEFE4),
      secondary: const Color(0xFF9AA7C7),
      onSecondary: const Color(0xFF141B2E),
      secondaryContainer: const Color(0xFF2A3450),
      onSecondaryContainer: const Color(0xFFDCE1EC),
      tertiary: AppColors.goldOnDark,
      onTertiary: const Color(0xFF3A2E08),
      tertiaryContainer: const Color(0xFF4A3B12),
      onTertiaryContainer: const Color(0xFFFBF3DF),
      error: AppColors.debitOnDark,
      onError: const Color(0xFF3A0B0B),
      surface: AppColors.charcoal,
      onSurface: const Color(0xFFEAEAEA),
      surfaceContainerHighest: const Color(0xFF2A2E33),
      surfaceContainer: AppColors.charcoalCard,
      onSurfaceVariant: const Color(0xFFB9B4A8),
      outline: const Color(0xFF5A564C),
      outlineVariant: const Color(0xFF3A3D42),
      inverseSurface: const Color(0xFFEAEAEA),
      onInverseSurface: const Color(0xFF1B1B1B),
      inversePrimary: AppColors.emerald,
      surfaceTint: AppColors.emeraldOnDark,
    );

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: buildAppPageTransitionsTheme(),
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.charcoal,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: Color(0xFF0B3B29),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: AppColors.charcoalCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emeraldOnDark,
          foregroundColor: const Color(0xFF0B2E20),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emeraldOnDark,
          foregroundColor: const Color(0xFF0B2E20),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emeraldOnDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.charcoalCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.emeraldOnDark,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle:
            TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.charcoalCard,
        indicatorColor: const Color(0xFF0B3B29),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          // 11px: see light theme — labels must fit one line at 360px.
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.emeraldOnDark,
            );
          }
          return const TextStyle(fontSize: 11, color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.emeraldOnDark);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.charcoalCard,
        indicatorColor: Color(0xFF0B3B29),
        selectedIconTheme: IconThemeData(color: AppColors.emeraldOnDark),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.emeraldOnDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.charcoalCard,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFFEAEAEA),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.charcoalCard,
        selectedColor: const Color(0xFF0B3B29),
        checkmarkColor: AppColors.emeraldOnDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        labelStyle: const TextStyle(fontSize: 13),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emeraldOnDark,
        foregroundColor: Color(0xFF0B2E20),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
