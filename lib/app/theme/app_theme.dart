import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const navy = Color(0xFF0B1F4D);
    const cobalt = Color(0xFF1464F4);
    const cyan = Color(0xFF56C6FF);
    const gold = Color(0xFFFFC857);
    const mist = Color(0xFFF4F8FF);

    final textTheme = GoogleFonts.plusJakartaSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: navy,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: navy,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: navy,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: mist,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cobalt,
        primary: cobalt,
        secondary: cyan,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        selectedColor: cobalt.withValues(alpha: 0.15),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0x251464F4)),
          foregroundColor: navy,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppColors(
          navy: navy,
          cobalt: cobalt,
          cyan: cyan,
          gold: gold,
          mist: mist,
        ),
      ],
    );
  }
}

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.navy,
    required this.cobalt,
    required this.cyan,
    required this.gold,
    required this.mist,
  });

  final Color navy;
  final Color cobalt;
  final Color cyan;
  final Color gold;
  final Color mist;

  @override
  ThemeExtension<AppColors> copyWith({
    Color? navy,
    Color? cobalt,
    Color? cyan,
    Color? gold,
    Color? mist,
  }) {
    return AppColors(
      navy: navy ?? this.navy,
      cobalt: cobalt ?? this.cobalt,
      cyan: cyan ?? this.cyan,
      gold: gold ?? this.gold,
      mist: mist ?? this.mist,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(
    covariant ThemeExtension<AppColors>? other,
    double t,
  ) {
    if (other is! AppColors) {
      return this;
    }

    return AppColors(
      navy: Color.lerp(navy, other.navy, t) ?? navy,
      cobalt: Color.lerp(cobalt, other.cobalt, t) ?? cobalt,
      cyan: Color.lerp(cyan, other.cyan, t) ?? cyan,
      gold: Color.lerp(gold, other.gold, t) ?? gold,
      mist: Color.lerp(mist, other.mist, t) ?? mist,
    );
  }
}
