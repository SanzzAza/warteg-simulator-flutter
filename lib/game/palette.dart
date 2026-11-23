/// Palet warna hangat khas warteg. Dipakai konsisten oleh scene Flame & UI.
library;

import 'dart:ui';

class WartegPalette {
  WartegPalette._();

  static const Color cream = Color(0xFFFFF3D6);
  static const Color creamDark = Color(0xFFF2DFB4);
  static const Color sand = Color(0xFFE8C98B);
  static const Color wood = Color(0xFFA8702F);
  static const Color woodDark = Color(0xFF7A4A1D);
  static const Color brown = Color(0xFF6D4A2C);
  static const Color brownDark = Color(0xFF472D1A);
  static const Color brick = Color(0xFFB23A2E);
  static const Color brickDark = Color(0xFF8C2A21);
  static const Color orange = Color(0xFFF28A1B);
  static const Color orangeSoft = Color(0xFFFFB456);
  static const Color yellow = Color(0xFFFFD24C);
  static const Color green = Color(0xFF6E8B3D);
  static const Color greenDark = Color(0xFF4C6327);
  static const Color skin = Color(0xFFE2B07A);
  static const Color skinDark = Color(0xFFC48B52);
  static const Color white = Color(0xFFFFFDF5);
  static const Color shadow = Color(0x332B1B0E);

  /// Warna jam berdasarkan menit dalam hari (untuk tint atmosfer).
  static Color dayTint(int minuteOfDay) {
    if (minuteOfDay < 9 * 60) return const Color(0x14FFB74D); // pagi hangat
    if (minuteOfDay < 15 * 60) return const Color(0x00FFFFFF); // siang terang
    if (minuteOfDay < 18 * 60) return const Color(0x1ACC6B22); // sore oranye
    return const Color(0x4014142A); // malam (biru gelap transparan)
  }
}
