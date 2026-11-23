/// Teks melayang (+Rp12.000 / 😠) di atas pelanggan — juga di-pool.
library;

import 'dart:ui';

import 'package:flame/components.dart';

import '../paint_utils.dart';

class FloatingText extends PositionComponent {
  FloatingText() : super(position: Vector2.zero(), priority: 1000);

  String _teks = '';
  Color _warna = const Color(0xFF2E7D32);
  double _umur = 0;
  static const double _durasi = 1.6;

  bool get aktif => _umur > 0 && _umur < _durasi;

  void tampilkan(String teks, Offset pos, Color warna) {
    _teks = teks;
    _warna = warna;
    _umur = 0.0001;
    position.setValues(pos.dx, pos.dy);
  }

  void lepas() => _umur = 0;

  @override
  void update(double dt) {
    if (_umur == 0) return;
    _umur += dt;
    position.y -= 34 * dt;
  }

  @override
  void render(Canvas canvas) {
    if (_umur == 0 || _umur >= _durasi) return;
    final alpha = (1 - _umur / _durasi).clamp(0.0, 1.0);
    drawText(
      canvas,
      _teks,
      Offset.zero,
      fontSize: 18,
      align: TextAlign.center,
      color: _warna.withValues(alpha: alpha),
      weight: FontWeight.w800,
      shadow: true,
    );
  }
}

/// Kumpulan teks melayang yang dipakai ulang.
class FloatingTextPool {
  FloatingTextPool({required this.parent, this.size = 12});

  final Component parent;
  final int size;
  final List<FloatingText> _pool = [];
  int _berikut = 0;

  void warmUp() {
    for (var i = 0; i < size; i++) {
      final ft = FloatingText();
      _pool.add(ft);
      parent.add(ft);
    }
  }

  void tampilkan(String teks, Offset pos, Color warna) {
    final ft = _pool[_berikut % _pool.length];
    _berikut++;
    ft.tampilkan(teks, pos, warna);
  }
}
