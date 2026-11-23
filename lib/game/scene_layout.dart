/// Tata letak adegan warteg dalam koordinat dunia (1280 x 800).
///
/// Semua posisi di sini dalam "pixel dunia"; kamera Flame memakai resolusi
/// tetap sehingga tampilan menyesuaikan sendiri di layar HP maupun desktop.
library;

import 'dart:ui';

class SceneLayout {
  SceneLayout._();

  static const double width = 1280;
  static const double height = 800;

  /// Titik spawn pelanggan (di luar pintu, bawah tengah).
  static const Offset pintuLuar = Offset(640, 870);

  /// Titik di dalam pintu.
  static const Offset pintuDalam = Offset(640, 748);

  /// Posisi kasir (di depan meja kasir).
  static const Offset depanKasir = Offset(1152, 424);

  /// Ember etalase (untuk label & pelanggan melihat lauk).
  static const Rect etalase = Rect.fromLTWH(322, 236, 520, 126);

  /// Area dapur.
  static const Rect dapur = Rect.fromLTWH(34, 206, 250, 322);

  /// Meja pelanggan (atas kiri tiap meja, ukuran meja 110x110).
  static const List<Offset> meja = [
    Offset(198, 474),
    Offset(452, 474),
    Offset(706, 474),
    Offset(960, 474),
    Offset(198, 614),
    Offset(452, 614),
    Offset(960, 614),
    Offset(1090, 614),
  ];

  /// Posisi kursi ke-[seatIndex] (mengelilingi meja).
  static Offset kursi(int seatIndex) {
    const perMeja = 4;
    if (seatIndex < 0) return pintuDalam;
    final mejaIdx = seatIndex ~/ perMeja;
    final slot = seatIndex % perMeja;
    final m = meja[mejaIdx.clamp(0, meja.length - 1)];
    const center = Offset(55, 55);
    switch (slot) {
      case 0:
        return m + center + const Offset(0, -62);
      case 1:
        return m + center + const Offset(62, 0);
      case 2:
        return m + center + const Offset(0, 62);
      default:
        return m + center + const Offset(-62, 0);
    }
  }

  /// Posisi baris antrean ke-[i] (0 = paling depan dekat kasir).
  /// Dua lajur di depan meja kasir, mengalir ke bawah.
  static Offset antre(int i) {
    final idx = i.clamp(0, 11);
    final lajur = idx ~/ 4;
    final urut = idx % 4;
    return Offset(1152 - lajur * 64, 424 + urut * 44);
  }

  /// Posisi duduk kasir di belakang meja.
  static const Offset kasirDuduk = Offset(1064, 300);
}
