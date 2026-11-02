import 'package:flutter/material.dart';

@immutable
class FramePalette extends ThemeExtension<FramePalette> {
  const FramePalette({
    required this.paper,
    required this.paperDeep,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.danger,
  });

  final Color paper;
  final Color paperDeep;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color danger;

  static const light = FramePalette(
    paper: Color(0xFFF3F1EC),
    paperDeep: Color(0xFFE6E1D8),
    surface: Color(0xFFFFFCF7),
    ink: Color(0xFF1C1916),
    muted: Color(0xFF6F6A62),
    line: Color(0xFFE3DDD4),
    accent: Color(0xFFD4532B),
    accentSoft: Color(0xFFF6E4DA),
    danger: Color(0xFFB42318),
  );

  static const dark = FramePalette(
    paper: Color(0xFF0F0F0D),
    paperDeep: Color(0xFF1C1C18),
    surface: Color(0xFF171714),
    ink: Color(0xFFF6F3EC),
    muted: Color(0xFFA39E94),
    line: Color(0xFF2C2C28),
    accent: Color(0xFFFF7A4A),
    accentSoft: Color(0xFF3A241C),
    danger: Color(0xFFFF8A80),
  );

  @override
  FramePalette copyWith({
    Color? paper,
    Color? paperDeep,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? line,
    Color? accent,
    Color? accentSoft,
    Color? danger,
  }) {
    return FramePalette(
      paper: paper ?? this.paper,
      paperDeep: paperDeep ?? this.paperDeep,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      danger: danger ?? this.danger,
    );
  }

  @override
  FramePalette lerp(FramePalette? other, double t) {
    if (other == null) return this;
    return FramePalette(
      paper: Color.lerp(paper, other.paper, t)!,
      paperDeep: Color.lerp(paperDeep, other.paperDeep, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension FramePaletteContext on BuildContext {
  FramePalette get palette =>
      Theme.of(this).extension<FramePalette>() ?? FramePalette.light;
}

abstract final class FrameTheme {
  static ThemeData get light => _build(Brightness.light, FramePalette.light);
  static ThemeData get dark => _build(Brightness.dark, FramePalette.dark);

  static ThemeData _build(Brightness brightness, FramePalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      primary: palette.accent,
      onPrimary: Colors.white,
      surface: palette.paper,
      onSurface: palette.ink,
      error: palette.danger,
    );
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final text = base
        .apply(
          fontFamily: 'Outfit',
          bodyColor: palette.ink,
          displayColor: palette.ink,
        )
        .copyWith(
          displaySmall: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 34,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
            color: palette.ink,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: palette.ink,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.ink,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.35,
            color: palette.ink,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: palette.muted,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.paper,
      fontFamily: 'Outfit',
      textTheme: text,
      extensions: [palette],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: palette.paper,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accent),
    );
  }
}
