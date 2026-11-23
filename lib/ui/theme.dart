/// Tema Material 3 bernuansa hangat (krem, oranye, cokelat, merah bata).
library;

import 'package:material_ui/material_ui.dart';

import '../game/palette.dart';

/// Keluarga font yang dibundel di assets/fonts (lihat pubspec.yaml).
const String kFontFamily = 'Roboto';

/// Gaya teks tombol harus menyebut font family secara eksplisit: ButtonStyle
/// mengganti DefaultTextStyle, bukan mewarisinya.
TextStyle gayaTombol({double? size, FontWeight weight = FontWeight.w700}) =>
    TextStyle(fontFamily: kFontFamily, fontSize: size, fontWeight: weight);

class WartegColors {
  WartegColors._();

  static const Color cream = WartegPalette.cream;
  static const Color creamDark = WartegPalette.creamDark;
  static const Color wood = WartegPalette.wood;
  static const Color woodDark = WartegPalette.woodDark;
  static const Color brick = WartegPalette.brick;
  static const Color brickDark = WartegPalette.brickDark;
  static const Color orange = WartegPalette.orange;
  static const Color orangeSoft = WartegPalette.orangeSoft;
  static const Color yellow = WartegPalette.yellow;
  static const Color green = WartegPalette.green;
  static const Color brown = WartegPalette.brown;
  static const Color brownDark = WartegPalette.brownDark;
  static const Color ink = Color(0xFF3B2414);
}

ThemeData buildWartegTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: WartegColors.orange,
    brightness: Brightness.light,
  ).copyWith(
    primary: WartegColors.brick,
    onPrimary: WartegColors.cream,
    secondary: WartegColors.orange,
    onSecondary: WartegColors.brownDark,
    surface: WartegColors.cream,
    onSurface: WartegColors.ink,
    tertiary: WartegColors.yellow,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: WartegColors.creamDark,
    fontFamily: kFontFamily,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: WartegColors.brick,
      foregroundColor: WartegColors.cream,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: kFontFamily,
        color: WartegColors.cream,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: WartegColors.cream,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x33A8702F)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WartegColors.brick,
        foregroundColor: WartegColors.cream,
        minimumSize: const Size(0, 44),
        textStyle: const TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WartegColors.brickDark,
        side: const BorderSide(color: WartegColors.wood),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: WartegColors.brickDark),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: WartegColors.cream,
      selectedColor: WartegColors.orangeSoft,
      labelStyle: const TextStyle(fontFamily: kFontFamily, color: WartegColors.ink, fontWeight: FontWeight.w600),
      side: const BorderSide(color: Color(0x33A8702F)),
    ),
    dividerColor: const Color(0x33A8702F),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: WartegColors.brownDark,
      contentTextStyle: const TextStyle(fontFamily: kFontFamily, color: WartegColors.cream),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: WartegColors.orange,
      thumbColor: WartegColors.brick,
      inactiveTrackColor: const Color(0x33A8702F),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: WartegColors.brickDark,
      unselectedLabelColor: Color(0x993B2414),
      indicatorColor: WartegColors.orange,
      labelStyle: TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w800, fontSize: 13),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: WartegColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontFamily: kFontFamily,
        color: WartegColors.brickDark,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// Gaya judul kecil di dalam panel.
const TextStyle kWartegLabel = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: Color(0xAA3B2414),
  letterSpacing: 0.4,
);

const TextStyle kWartegValue = TextStyle(
  fontFamily: kFontFamily,
  fontSize: 16,
  fontWeight: FontWeight.w800,
  color: WartegColors.ink,
);

/// Dekorasi garis pembatas bertema.
Widget garisWarteg() => const Divider(height: 18, thickness: 1);
