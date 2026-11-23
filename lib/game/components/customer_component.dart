/// Sprite pelanggan yang digambar lewat kode + indikator emosi + balon pesanan.
///
/// Komponen ini dipakai ulang lewat [CustomerPool] untuk menghemat alokasi.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../data/models/customer_type.dart';
import '../../data/models/game_state.dart';
import '../../data/models/menu_item.dart';
import '../paint_utils.dart';
import '../palette.dart';
import '../scene_layout.dart';

class CustomerComponent extends PositionComponent {
  CustomerComponent({super.priority = 10}) : super(position: Vector2.zero());

  /// Data simulasi pelanggan ini (null = komponen menganggur di pool).
  CustomerSim? sim;

  double _walkPhase = 0;

  /// Dipakai pool untuk menandai aktif/tidak.
  bool get aktif => sim != null;

  /// Penanda agar teks "+Rp" hanya muncul sekali per pelanggan.
  bool sudahTampilBayar = false;

  // Cache teks balon: dihitung ulang hanya saat isi pesanan berubah.
  String _teksBalon = 'Pesan…';
  int _cacheOrderLen = -1;
  int _cacheTotal = -1;

  void siapkan(CustomerSim data, Offset posisi) {
    sim = data;
    position.setValues(posisi.dx, posisi.dy);
    _walkPhase = 0;
    sudahTampilBayar = false;
    _cacheOrderLen = -1;
    _cacheTotal = -1;
    priority = 30 + posisi.dy.round() ~/ 4;
  }

  void lepas() {
    sim = null;
  }

  /// Target posisi sesuai tahap; animasi kecil menuju target.
  Offset _targetPosisi() {
    final c = sim!;
    switch (c.stage) {
      case CustomerStage.datang:
        return SceneLayout.pintuDalam;
      case CustomerStage.antre:
        return SceneLayout.antre(c.queueIndex < 0 ? 0 : c.queueIndex);
      case CustomerStage.pesan:
        return SceneLayout.depanKasir;
      case CustomerStage.makan:
        if (c.seatIndex >= 0) return SceneLayout.kursi(c.seatIndex);
        // Makan berdiri di dekat etalase.
        return Offset(360 + (c.id % 5) * 40, 400);
      case CustomerStage.pulang:
        // Keluar lewat pintu bawah lalu hilang di luar layar.
        return SceneLayout.pintuLuar + const Offset(0, 220);
    }
  }

  @override
  void update(double dt) {
    if (sim == null) return;
    final target = _targetPosisi();
    final ke = target - Offset(position.x, position.y);
    final jarak = ke.distance;
    final profil = kCustomerProfiles[sim!.type];
    final kecepatan = 150.0 * (profil?.speed ?? 1.0) * dt;
    if (jarak > 2) {
      final langkah = jarak < kecepatan ? jarak : kecepatan;
      final arah = ke / jarak;
      position.x += arah.dx * langkah;
      position.y += arah.dy * langkah;
      _walkPhase += dt * 10;
      // Urut render mengikuti Y agar tumpang tindih terlihat benar.
      priority = 30 + position.y.round() ~/ 4;
    } else {
      _walkPhase = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    final c = sim;
    if (c == null) return;

    final berjalan = _walkPhase > 0;
    final bounce = berjalan ? math.sin(_walkPhase) * 2.5 : 0.0;
    final bodyColor = Color(c.type.colorArgb);

    // Bayangan.
    drawShadow(canvas, const Offset(0, 26), 16, 5);

    // Kaki.
    final kaki = Paint()..color = const Color(0xFF3E2C1E);
    final ayunan = berjalan ? math.sin(_walkPhase) * 5 : 0.0;
    canvas.drawRect(Rect.fromLTWH(-9 + ayunan, 10, 7, 16), kaki);
    canvas.drawRect(Rect.fromLTWH(2 - ayunan, 10, 7, 16), kaki);

    // Badan (jaket/kaos warna tipe pelanggan).
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-15, -18 + bounce, 30, 34),
        const Radius.circular(10),
      ),
      Paint()..color = bodyColor,
    );

    // Tangan.
    canvas.drawCircle(Offset(-17, -6 + bounce), 5, Paint()..color = WartegPalette.skin);
    canvas.drawCircle(Offset(17, -6 + bounce), 5, Paint()..color = WartegPalette.skin);

    // Kepala.
    final kepala = Offset(0, -30 + bounce);
    canvas.drawCircle(kepala, 13, Paint()..color = WartegPalette.skin);
    // Rambut/peci.
    canvas.drawArc(
      Rect.fromCircle(center: kepala, radius: 13),
      math.pi * 1.02,
      math.pi * 0.96,
      true,
      Paint()..color = c.type == CustomerType.anakSekolah
          ? const Color(0xFF263238)
          : const Color(0xFF33221A),
    );
    // Mata.
    canvas.drawCircle(kepala + const Offset(-4, 1), 1.6, Paint()..color = const Color(0xFF2B1B10));
    canvas.drawCircle(kepala + const Offset(4, 1), 1.6, Paint()..color = const Color(0xFF2B1B10));
    // Mulut sesuai emosi.
    final mulut = Paint()
      ..color = const Color(0xFF7A2E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    if (c.mood == 2) {
      canvas.drawArc(Rect.fromCircle(center: kepala + const Offset(0, 4), radius: 4), 0.2, 2.7, false, mulut);
    } else if (c.mood == 0) {
      canvas.drawArc(Rect.fromCircle(center: kepala + const Offset(0, 9), radius: 4), 3.4, 2.7, false, mulut);
    } else {
      canvas.drawLine(kepala + const Offset(-3, 6), kepala + const Offset(3, 6), mulut);
    }

    _renderEmosi(canvas, c);
    if (c.stage == CustomerStage.pesan || c.stage == CustomerStage.makan) {
      _renderBalon(canvas, c);
    }
  }

  /// Indikator emosi kecil di atas kepala: 😊 / 😐 / 😠 versi gambar kode.
  void _renderEmosi(Canvas canvas, CustomerSim c) {
    const pos = Offset(20, -46);
    final warna = c.mood == 2
        ? const Color(0xFF7CB342)
        : c.mood == 0
            ? const Color(0xFFE53935)
            : const Color(0xFFF9A825);
    canvas.drawCircle(pos, 9, Paint()..color = WartegPalette.white);
    canvas.drawCircle(
      pos,
      9,
      Paint()
        ..color = warna
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final p = Paint()
      ..color = warna
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    if (c.mood == 2) {
      canvas.drawArc(Rect.fromCircle(center: pos + const Offset(0, 1), radius: 4.5), 0.3, 2.5, false, p);
    } else if (c.mood == 0) {
      canvas.drawArc(Rect.fromCircle(center: pos + const Offset(0, 5), radius: 4.5), 3.4, 2.5, false, p);
    } else {
      canvas.drawLine(pos + const Offset(-4, 2), pos + const Offset(4, 2), p);
    }
  }

  /// Balon pesanan / status.
  void _renderBalon(Canvas canvas, CustomerSim c) {
    if (c.order.length != _cacheOrderLen || c.totalBayar != _cacheTotal) {
      _cacheOrderLen = c.order.length;
      _cacheTotal = c.totalBayar;
      _teksBalon = c.order.isEmpty
          ? 'Pesan…'
          : c.order.keys.map((id) => menuById(id)?.name ?? id).take(2).join(', ');
    }
    final teks = _teksBalon;
    final lebar = (teks.length * 7.2 + 22).clamp(60.0, 170.0);
    final balon = Rect.fromLTWH(-lebar / 2, -84, lebar, 24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(balon, const Radius.circular(10)),
      Paint()..color = WartegPalette.white,
    );
    final ekor = Path()
      ..moveTo(-6, -60)
      ..lineTo(6, -60)
      ..lineTo(0, -52)
      ..close();
    canvas.drawPath(ekor, Paint()..color = WartegPalette.white);
    drawText(
      canvas,
      teks,
      const Offset(0, -80),
      fontSize: 11,
      align: TextAlign.center,
      color: WartegPalette.brownDark,
      maxWidth: lebar - 12,
      weight: FontWeight.w600,
    );
  }
}
