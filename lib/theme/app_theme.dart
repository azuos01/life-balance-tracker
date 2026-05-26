import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brightness flag (set by SettingsProvider) ─────────────────────────────
  static bool _isDark = true;
  static void setDark(bool value) => _isDark = value;

  // ── Cores privadas — modo escuro ──────────────────────────────────────────
  static const Color _dkBackground    = Color(0xFF07071A);
  static const Color _dkSurface       = Color(0xFF12122A);
  static const Color _dkSurfaceLight  = Color(0xFF1C1C38);
  static const Color _dkSurfaceHigh   = Color(0xFF232342);
  static const Color _dkTextPrimary   = Color(0xFFF0F0FF);
  static const Color _dkTextSecondary = Color(0xFF8E8EBB);
  static const Color _dkDivider       = Color(0xFF1E1E3C);

  // ── Cores privadas — modo claro ───────────────────────────────────────────
  static const Color _ltBackground    = Color(0xFFF2F2FF);
  static const Color _ltSurface       = Color(0xFFFFFFFF);
  static const Color _ltSurfaceLight  = Color(0xFFEEEEFF);
  static const Color _ltSurfaceHigh   = Color(0xFFE4E4F8);
  static const Color _ltTextPrimary   = Color(0xFF1A1A3A);
  static const Color _ltTextSecondary = Color(0xFF5A5A8E);
  static const Color _ltDivider       = Color(0xFFDDDDF5);

  // ── Cores dinâmicas (usadas em todo o app via AppTheme.surface etc.) ───────
  static Color get background    => _isDark ? _dkBackground    : _ltBackground;
  static Color get surface       => _isDark ? _dkSurface       : _ltSurface;
  static Color get surfaceLight  => _isDark ? _dkSurfaceLight  : _ltSurfaceLight;
  static Color get surfaceHigh   => _isDark ? _dkSurfaceHigh   : _ltSurfaceHigh;
  static Color get textPrimary   => _isDark ? _dkTextPrimary   : _ltTextPrimary;
  static Color get textSecondary => _isDark ? _dkTextSecondary : _ltTextSecondary;
  static Color get divider       => _isDark ? _dkDivider       : _ltDivider;

  // ── Cores fixas (iguais em ambos os modos) ────────────────────────────────
  static const Color primary      = Color(0xFF7C6FFF);
  static const Color primaryLight = Color(0xFFACA3FF);
  static const Color primaryDark  = Color(0xFF5A4FCC);
  static const Color accent       = Color(0xFFFF6B8A);
  static const Color accentGold   = Color(0xFFFFD166);

  // ── Gradientes reutilizáveis ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C6FFF), Color(0xFF9D5FE8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B8A), Color(0xFFFF8E53)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD166), Color(0xFFFF9F1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF07071A), Color(0xFF0C0C25)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Sombras ───────────────────────────────────────────────────────────────
  static List<BoxShadow> glowShadow(Color color,
          {double blur = 20, double opacity = 0.3}) =>
      [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: blur,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 24,
      spreadRadius: -6,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Cores das 10 áreas ────────────────────────────────────────────────────
  static const List<Color> areaColors = [
    Color(0xFFFF5E7A), // Saúde Física       — vermelho vibrante
    Color(0xFF6E6EFF), // Saúde Mental       — índigo
    Color(0xFFFF7043), // Carreira           — laranja
    Color(0xFF34D399), // Finanças           — esmeralda
    Color(0xFFFF6BAC), // Relacionamentos    — rosa
    Color(0xFFA78BFA), // Família            — lavanda
    Color(0xFF22D3EE), // Intelectual        — ciano
    Color(0xFFFFD166), // Espiritualidade    — âmbar
    Color(0xFFFF9F1C), // Lazer              — âmbar escuro
    Color(0xFF10B981), // Contribuição       — verde
  ];

  static LinearGradient areaGradient(int index) {
    final c = areaColors[index % areaColors.length];
    return LinearGradient(
      colors: [c, c.withOpacity(0.6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ── Tema escuro ───────────────────────────────────────────────────────────
  static ThemeData dark() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: _dkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: _dkSurface,
        onPrimary: Colors.white,
        onSurface: _dkTextPrimary,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: _dkTextPrimary,
        displayColor: _dkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _dkTextPrimary),
        titleTextStyle: GoogleFonts.nunito(
          color: _dkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: _dkTextSecondary,
        indicatorColor: primary,
        labelStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      cardTheme: CardThemeData(
        color: _dkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _dkTextPrimary,
          side: const BorderSide(color: _dkDivider),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _dkSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _dkDivider.withOpacity(1.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: _dkTextSecondary),
        hintStyle: TextStyle(color: _dkTextSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: _dkSurfaceLight,
        thumbColor: primary,
        overlayColor: Color(0x257C6FFF),
        trackHeight: 4,
      ),
      dividerTheme:
          const DividerThemeData(color: _dkDivider, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _dkSurface,
        selectedItemColor: primary,
        unselectedItemColor: _dkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _dkSurfaceLight,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.nunito(
          color: _dkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _dkSurfaceHigh,
        contentTextStyle: GoogleFonts.nunito(color: _dkTextPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _dkSurfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : _dkTextSecondary),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withOpacity(0.4)
                : _dkSurfaceHigh),
      ),
    );
  }

  // ── Tema claro ────────────────────────────────────────────────────────────
  static ThemeData light() {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: _ltBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: _ltSurface,
        onPrimary: Colors.white,
        onSurface: _ltTextPrimary,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: _ltTextPrimary,
        displayColor: _ltTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _ltTextPrimary),
        titleTextStyle: GoogleFonts.nunito(
          color: _ltTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: _ltTextSecondary,
        indicatorColor: primary,
        labelStyle:
            GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 13),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      cardTheme: CardThemeData(
        color: _ltSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ltTextPrimary,
          side: const BorderSide(color: _ltDivider),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _ltSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _ltDivider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: _ltTextSecondary),
        hintStyle: TextStyle(color: _ltTextSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: _ltSurfaceHigh,
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.12),
        trackHeight: 4,
      ),
      dividerTheme:
          const DividerThemeData(color: _ltDivider, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _ltSurface,
        selectedItemColor: primary,
        unselectedItemColor: _ltTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle:
            GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _ltSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.nunito(
          color: _ltTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _ltSurfaceHigh,
        contentTextStyle: GoogleFonts.nunito(color: _ltTextPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _ltSurface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? primary : _ltTextSecondary),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? primary.withOpacity(0.3)
                : _ltSurfaceHigh),
      ),
    );
  }
}