/// Komponen dekorasi & interior warteg — semua digambar lewat kode
/// (placeholder yang mudah diganti sprite asli di assets/ nanti).
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../data/models/game_state.dart';
import '../paint_utils.dart';
import '../palette.dart';
import '../scene_layout.dart';

const List<String> _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Lantai keramik + dinding + spanduk "WARTEG".
class WarungInterior extends PositionComponent {
  WarungInterior({required this.readState}) : super(position: Vector2.zero(), priority: -100);

  final GameState Function() readState;

  @override
  void render(Canvas canvas) {
    final st = readState();
    _renderFloor(canvas);
    _renderWalls(canvas);
    _renderBanner(canvas, st);
    _renderMenuBoard(canvas);
  }

  void _renderFloor(Canvas canvas) {
    const rect = Rect.fromLTWH(0, 188, SceneLayout.width, SceneLayout.height - 118);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFD9A45B));

    // Kotak keramik (grid 64 px) dengan garis sambungan.
    final tilePaint = Paint()..color = const Color(0xFFE0B673);
    final linePaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1.5;
    for (var y = rect.top; y < rect.bottom; y += 64) {
      for (var x = 0.0; x < SceneLayout.width; x += 64) {
        final checker = ((x / 64).floor() + (y / 64).floor()) % 2 == 0;
        if (checker) {
          canvas.drawRect(Rect.fromLTWH(x, y, 64, 64), tilePaint);
        }
      }
      canvas.drawLine(Offset(0, y), Offset(SceneLayout.width, y), linePaint);
    }
    for (var x = 0.0; x < SceneLayout.width; x += 64) {
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), linePaint);
    }

    // Les kayu di tepi.
    canvas.drawRect(
      Rect.fromLTWH(0, rect.bottom, SceneLayout.width, 12),
      Paint()..color = WartegPalette.woodDark,
    );

    // Pintu masuk di depan (bawah tengah) + keset + tulisan BUKA.
    const pintu = Rect.fromLTWH(620, 690, 104, 88);
    canvas.drawRect(pintu, Paint()..color = const Color(0xFF8A5A28));
    canvas.drawRect(pintu.deflate(8), Paint()..color = const Color(0xFFC2884A));
    canvas.drawRect(
      Rect.fromLTWH(pintu.left + 12, pintu.top + 10, 34, 54),
      Paint()..color = const Color(0x66EAF6FF),
    );
    canvas.drawRect(
      Rect.fromLTWH(pintu.right - 46, pintu.top + 10, 34, 54),
      Paint()..color = const Color(0x66EAF6FF),
    );
    canvas.drawCircle(
      Offset(pintu.right - 18, pintu.top + 44),
      3,
      Paint()..color = WartegPalette.yellow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(592, 764, 160, 22), const Radius.circular(6)),
      Paint()..color = const Color(0xFF7A4A1D),
    );
    // Tulisan BUKA di keset depan pintu (tidak tertutup furnitur).
    drawText(
      canvas,
      'BUKA',
      const Offset(672, 767),
      fontSize: 13,
      align: TextAlign.center,
      color: WartegPalette.yellow,
      weight: FontWeight.w900,
      letterSpacing: 4,
    );

    // Tint atmosfer tergantung jam (pagi hangat, sore oranye, malam gelap).
    final tint = WartegPalette.dayTint(readState().minuteOfDay);
    if (tint.a > 0) {
      canvas.drawRect(
        const Rect.fromLTWH(0, 188, SceneLayout.width, SceneLayout.height - 118),
        Paint()..color = tint,
      );
    }
  }

  void _renderWalls(Canvas canvas) {
    // Dinding belakang krem dengan aksen bata di bawah.
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, SceneLayout.width, 188),
      Paint()..color = const Color(0xFFEFE0BE),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 176, SceneLayout.width, 16),
      Paint()..color = const Color(0xFFB98A4B),
    );

    // Panel dinding: garis vertikal tipis.
    final panel = Paint()..color = const Color(0x11000000);
    for (var x = 0.0; x < SceneLayout.width; x += 96) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, 176), panel);
    }

  }

  void _renderBanner(Canvas canvas, GameState st) {
    // Spanduk "WARTEG" merah bata dengan tulisan kuning.
    const banner = Rect.fromLTWH(432, 16, 416, 92);
    canvas.drawRect(
      banner.shift(const Offset(0, 5)),
      Paint()
        ..color = const Color(0x44000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRect(banner, Paint()..color = WartegPalette.brick);
    canvas.drawRect(
      banner.deflate(6),
      Paint()
        ..color = WartegPalette.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    drawText(
      canvas,
      'WARTEG',
      Offset(banner.center.dx, banner.top + 14),
      fontSize: 46,
      color: WartegPalette.yellow,
      weight: FontWeight.w900,
      align: TextAlign.center,
      letterSpacing: 6,
      shadow: true,
    );
    drawText(
      canvas,
      '"Sederhana Rasa Rumahan"',
      Offset(banner.center.dx, banner.bottom - 26),
      fontSize: 15,
      color: WartegPalette.cream,
      weight: FontWeight.w600,
      align: TextAlign.center,
    );

    // Kalender harian: "Senin, 12 Mei • Hari ke-3".
    final now = DateTime(2026, 1, 5).add(Duration(days: st.day - 1));
    final hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][now.weekday - 1];
    final teks = '$hari, ${now.day} ${_bulan[now.month - 1]} • Hari ke-${st.day}';
    const panel = Rect.fromLTWH(896, 34, 196, 56);
    drawPanel(canvas, panel, radius: 10, fill: WartegPalette.white);
    drawText(
      canvas,
      teks,
      Offset(panel.center.dx, panel.top + 10),
      fontSize: 13,
      align: TextAlign.center,
      color: WartegPalette.brownDark,
    );
    drawText(
      canvas,
      'Reputasi ${st.reputation.toStringAsFixed(1)}',
      Offset(panel.left + 12, panel.top + 31),
      fontSize: 12.5,
      color: WartegPalette.brick,
    );
    _bintang(canvas, Offset(panel.right - 58, panel.top + 39), st.reputation, 6.5);
  }

  void _renderMenuBoard(Canvas canvas) {
    // Papan menu tulis tangan di dinding kiri.
    const board = Rect.fromLTWH(250, 24, 168, 124);
    drawPanel(
      canvas,
      board,
      radius: 8,
      fill: const Color(0xFF2F3B2A),
      border: WartegPalette.woodDark,
      borderWidth: 6,
    );
    drawText(
      canvas,
      'MENU HARI INI',
      Offset(board.center.dx, board.top + 12),
      fontSize: 13,
      color: WartegPalette.yellow,
      align: TextAlign.center,
    );
    const isi = ['Nasi + Lauk', 'Sayur & Sambal', 'Es Teh Manis'];
    for (var i = 0; i < isi.length; i++) {
      drawText(
        canvas,
        '• ${isi[i]}',
        Offset(board.left + 12, board.top + 40 + i * 26),
        fontSize: 11.5,
        color: WartegPalette.cream,
        weight: FontWeight.w500,
      );
    }
    // Kipas angin di dinding (kanan bawah kalender).
    _fan(canvas, const Offset(1130, 128));
  }

  void _fan(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 30, Paint()..color = const Color(0xFF9FB3B8));
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = const Color(0xFF5E7278)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final blades = Paint()..color = const Color(0xFFE8F0EE);
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 2);
      canvas.drawOval(const Rect.fromLTWH(0, -12, 30, 24), blades);
      canvas.restore();
    }
    canvas.drawCircle(center, 7, Paint()..color = const Color(0xFF44585D));
  }

  /// Bintang reputasi digambar manual agar tidak bergantung glyph font.
  void _bintang(Canvas canvas, Offset center, double value, double radius) {
    const total = 5;
    for (var i = 0; i < total; i++) {
      final cx = center.dx + (i - 2) * (radius * 2.3);
      final penuh = (value - i).clamp(0.0, 1.0);
      final path = _pathBintang(Offset(cx, center.dy), radius);
      canvas.drawPath(
        path,
        Paint()..color = const Color(0x33A8702F),
      );
      if (penuh > 0) {
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(cx - radius, center.dy - radius, cx - radius + radius * 2 * penuh, center.dy + radius));
        canvas.drawPath(path, Paint()..color = const Color(0xFFE0A200));
        canvas.restore();
      }
    }
  }

  Path _pathBintang(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -1.5708 + i * 0.6283;
      final rr = i.isEven ? r : r * 0.45;
      final x = c.dx + rr * math.cos(a);
      final y = c.dy + rr * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }
}

/// Etalase kaca berisi lauk — jumlah porsi mengikuti state.
class DisplayCase extends PositionComponent {
  DisplayCase({required this.readState}) : super(position: Vector2.zero(), priority: -40);

  final GameState Function() readState;

  @override
  void render(Canvas canvas) {
    final st = readState();
    const r = SceneLayout.etalase;

    // Meja etalase.
    drawShadow(canvas, Offset(r.center.dx, r.bottom + 8), r.width * 0.52, 14);
    canvas.drawRect(
      r.translate(0, 8),
      Paint()..color = const Color(0xFF9A6A34),
    );
    canvas.drawRect(r, Paint()..color = const Color(0x99EAF6FF));
    canvas.drawRect(
      r,
      Paint()
        ..color = const Color(0xFFF7FBFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Kayu rangka etalase.
    final frame = Paint()..color = const Color(0xFF7A4A1D);
    canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 8), frame);
    canvas.drawRect(Rect.fromLTWH(r.left, r.bottom - 8, r.width, 8), frame);
    for (var i = 0; i <= 4; i++) {
      canvas.drawRect(Rect.fromLTWH(r.left + i * r.width / 4 - 2, r.top, 4, r.height), frame);
    }

    // Petak kaca kosong (selalu 8 slot) supaya etalase terlihat berisi rak.
    final slotW = (r.width - 24) / 8;
    for (var i = 0; i < 8; i++) {
      final petak = Rect.fromLTWH(r.left + 12 + i * slotW, r.top + 18, slotW - 6, r.height - 34);
      canvas.drawRRect(
        RRect.fromRectAndRadius(petak, const Radius.circular(4)),
        Paint()..color = const Color(0x33FFFFFF),
      );
    }

    // Isi: wadah lauk dengan porsi & indikator kesegaran.
    final isi = st.dishBatches.where((d) => d.qty > 0).toList();
    for (var i = 0; i < isi.length && i < 8; i++) {
      final batch = isi[i];
      final slot = Rect.fromLTWH(
        r.left + 12 + i * (r.width - 24) / 8,
        r.top + 18,
        (r.width - 24) / 8 - 6,
        r.height - 34,
      );
      final warnaMenu = _warnaMenu(batch.menuId);
      // Piring + lauk.
      canvas.drawOval(
        Rect.fromCenter(center: slot.center, width: slot.width, height: slot.height * 0.6),
        Paint()..color = const Color(0xFFFDFDF8),
      );
      canvas.drawOval(
        Rect.fromCenter(center: slot.center, width: slot.width * 0.7, height: slot.height * 0.38),
        Paint()..color = warnaMenu,
      );
      // Indikator kesegaran (merah bila hampir basi).
      final segar = batch.freshness > 55
          ? const Color(0xFF7CB342)
          : batch.freshness > 25
              ? const Color(0xFFF9A825)
              : const Color(0xFFC62828);
      canvas.drawCircle(
        Offset(slot.left + 6, slot.top + 16),
        5,
        Paint()..color = segar,
      );
      drawText(
        canvas,
        '${batch.qty}',
        Offset(slot.right - 2, slot.top + 4),
        fontSize: 12,
        align: TextAlign.right,
        color: WartegPalette.brownDark,
      );
    }

    // Label harga kecil di depan etalase.
    drawText(
      canvas,
      'Etalase • ${st.dishCount}/${st.displayCapacity} porsi',
      Offset(r.center.dx, r.bottom + 18),
      fontSize: 14,
      align: TextAlign.center,
      color: WartegPalette.brownDark,
    );
  }

  Color _warnaMenu(String id) {
    // Selaras dengan warna menu di konfigurasi.
    final menu = _warnaCache[id];
    return menu ?? const Color(0xFFC99A5B);
  }

  static const Map<String, Color> _warnaCache = {
    'nasi_putih': Color(0xFFF5F0E1),
    'orek_tempe': Color(0xFF8D5A2B),
    'tempe_goreng': Color(0xFFD9A441),
    'tahu_goreng': Color(0xFFF2C14E),
    'telur_balado': Color(0xFFC62828),
    'ayam_goreng': Color(0xFFB26A00),
    'sayur_lodeh': Color(0xFF9E9D24),
    'tumis_kangkung': Color(0xFF2E7D32),
    'sambal_terasi': Color(0xFFE53935),
    'es_teh': Color(0xFFA1887F),
    'teh_hangat': Color(0xFF6D4C41),
    'kopi_tubruk': Color(0xFF3E2723),
    'sayur_asem': Color(0xFF7CB342),
    'lele_goreng': Color(0xFF5D4037),
    'rendang': Color(0xFF4E342E),
    'bakwan_jagung': Color(0xFFFFB300),
    'lalapan': Color(0xFF66BB6A),
    'kerupuk': Color(0xFFFFECB3),
    'es_jeruk': Color(0xFFFF9800),
    'mie_goreng': Color(0xFFFF7043),
  };
}

/// Meja kasir, kasir, galon, dan papan harga.
class CashierStation extends PositionComponent {
  CashierStation({required this.readState}) : super(position: Vector2.zero(), priority: -30);

  final GameState Function() readState;

  @override
  void render(Canvas canvas) {
    final st = readState();

    // Meja kasir.
    const meja = Rect.fromLTWH(1006, 336, 210, 76);
    drawShadow(canvas, Offset(meja.center.dx, meja.bottom + 6), 110, 12);
    canvas.drawRect(meja, Paint()..color = const Color(0xFFB07A3C));
    canvas.drawRect(
      Rect.fromLTWH(meja.left, meja.top, meja.width, 12),
      Paint()..color = const Color(0xFF8A5A28),
    );
    // Mesin kasir kecil.
    drawPanel(
      canvas,
      const Rect.fromLTWH(1032, 302, 74, 46),
      radius: 6,
      fill: const Color(0xFF3B3B3B),
      border: const Color(0xFF202020),
      borderWidth: 3,
    );
    drawText(canvas, 'Rp', const Offset(1069, 310), fontSize: 18,
        color: const Color(0xFF9BE28B), align: TextAlign.center);

    // Kasir duduk (bila ada karyawan kasir, tampil beda warna).
    final kasir = st.employees.where((e) => e.role.index == 1).toList();
    _kasirFigure(canvas, SceneLayout.kasirDuduk,
        kasir.isNotEmpty ? const Color(0xFF8E24AA) : const Color(0xFF6D4C41),
        kasir.isNotEmpty);

    // Galon air di kanan.
    _galon(canvas, const Offset(1216, 316));

    // Papan harga di atas meja.
    drawPanel(
      canvas,
      const Rect.fromLTWH(1086, 268, 104, 28),
      radius: 5,
      fill: WartegPalette.cream,
      border: WartegPalette.brown,
      borderWidth: 2,
      withShadow: false,
    );
    drawText(canvas, 'KASIR', const Offset(1138, 272), fontSize: 15,
        align: TextAlign.center, color: WartegPalette.brick);
  }

  void _kasirFigure(Canvas canvas, Offset pos, Color baju, bool hidup) {
    drawShadow(canvas, pos + const Offset(0, 34), 20, 7);
    // Badan.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: 40, height: 40),
        const Radius.circular(12),
      ),
      Paint()..color = baju,
    );
    // Kepala.
    canvas.drawCircle(pos + const Offset(0, -30), 15, Paint()..color = WartegPalette.skin);
    // Rambut.
    canvas.drawArc(
      Rect.fromCircle(center: pos + const Offset(0, -34), radius: 15),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF33221A),
    );
    if (!hidup) {
      drawText(canvas, 'pemilik', pos + const Offset(0, 22), fontSize: 11,
          align: TextAlign.center, color: WartegPalette.brownDark);
    }
  }

  void _galon(Canvas canvas, Offset pos) {
    drawShadow(canvas, pos + const Offset(0, 42), 18, 6);
    canvas.drawRect(
      Rect.fromCenter(center: pos + const Offset(0, 20), width: 30, height: 34),
      Paint()..color = const Color(0xFFBFDDEB),
    );
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 32, height: 36),
      Paint()..color = const Color(0xFF9CC8DD),
    );
    canvas.drawRect(
      Rect.fromCenter(center: pos + const Offset(0, -18), width: 12, height: 8),
      Paint()..color = const Color(0xFF6FA9C2),
    );
  }
}

/// Dapur: kompor, wajan, panci, rak piring.
class KitchenArea extends PositionComponent {
  KitchenArea({required this.readState}) : super(position: Vector2.zero(), priority: -50);

  final GameState Function() readState;

  @override
  void render(Canvas canvas) {
    final st = readState();
    const area = SceneLayout.dapur;

    // Lantai dapur keramik putih.
    canvas.drawRect(area, Paint()..color = const Color(0xFFE9E4D6));
    canvas.drawRect(
      area,
      Paint()
        ..color = const Color(0xFFBCAF8F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Meja masak panjang.
    const meja = Rect.fromLTWH(58, 268, 200, 92);
    drawShadow(canvas, Offset(meja.center.dx, meja.bottom + 6), 104, 12);
    canvas.drawRect(meja, Paint()..color = const Color(0xFFC8A26E));
    canvas.drawRect(
      Rect.fromLTWH(meja.left, meja.top, meja.width, 10),
      Paint()..color = const Color(0xFF9E7A46),
    );

    // Kompor + wajan (jumlah api mengikuti level kompor).
    final komporLevel = st.upgradeLevel('kompor');
    for (var i = 0; i < 1 + komporLevel; i++) {
      final x = 74.0 + i * 44;
      canvas.drawRect(Rect.fromLTWH(x, 282, 34, 24), Paint()..color = const Color(0xFF4A4A4A));
      canvas.drawCircle(Offset(x + 17, 282), 15, Paint()..color = const Color(0xFF5A5A5A));
      // Api.
      final api = Paint()
        ..color = const Color(0xFFFFA726)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x + 17, 284), 9, api);
      final nyala = Paint()..color = const Color(0xFFFFE082);
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 17, 286), width: 10, height: 6), nyala);
    }

    // Panci besar.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(180, 274, 60, 40), const Radius.circular(10)),
      Paint()..color = const Color(0xFF8D8D8D),
    );
    canvas.drawRect(const Rect.fromLTWH(176, 270, 68, 8), Paint()..color = const Color(0xFFB0B0B0));

    // Uap mengepul bila ada antrean masak.
    if (st.cookingQueue.isNotEmpty) {
      final job = st.cookingQueue.first;
      final progres = (job.progress / job.totalMinutes).clamp(0.0, 1.0);
      final time = DateTime.now().millisecondsSinceEpoch / 500.0;
      for (var i = 0; i < 3; i++) {
        final off = math.sin(time + i) * 8;
        canvas.drawCircle(
          Offset(210 + off, 250 - i * 18),
          8 - i * 2,
          Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 - i * 0.08),
        );
      }
      // Progress bar masak di atas kompor.
      drawPanel(canvas, const Rect.fromLTWH(58, 240, 200, 14), radius: 6,
          fill: WartegPalette.creamDark, borderWidth: 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(60, 242, 196 * progres, 10),
          const Radius.circular(5),
        ),
        Paint()..color = WartegPalette.orange,
      );
      drawText(canvas, 'lagi masak…', const Offset(160, 220), fontSize: 12,
          align: TextAlign.center, color: WartegPalette.brownDark);
    }
  }
}

/// Daun/tanaman & elemen dekorasi tambahan (dipengaruhi upgrade dekorasi).
class DecorationsLayer extends PositionComponent {
  DecorationsLayer({required this.readState}) : super(position: Vector2.zero(), priority: 120);

  final GameState Function() readState;

  @override
  void render(Canvas canvas) {
    final st = readState();
    final level = st.upgradeLevel('dekorasi');
    if (level > 0) {
      _pot(canvas, const Offset(80, 640), 1 + level * 0.2);
      _pot(canvas, const Offset(1200, 470), 1 + level * 0.2);
    }
    if (st.upgradeLevel('ac') > 0) {
      _ac(canvas, const Offset(430, 574));
      if (st.upgradeLevel('ac') > 1) _ac(canvas, const Offset(684, 574));
    }
    // Spanduk kecil "Bisa Pesan Antar" bila level >= 3 (di dinding belakang).
    if (st.level >= 3) {
      drawPanel(
        canvas,
        const Rect.fromLTWH(548, 116, 184, 28),
        radius: 8,
        fill: WartegPalette.yellow,
        border: WartegPalette.brick,
        borderWidth: 2,
        withShadow: false,
      );
      drawText(canvas, 'BISA PESAN ANTAR', const Offset(640, 122), fontSize: 13,
          align: TextAlign.center, color: WartegPalette.brickDark);
    }
  }

  void _pot(Canvas canvas, Offset pos, double skala) {
    drawShadow(canvas, pos + const Offset(0, 28), 16, 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos + const Offset(0, 20), width: 34, height: 26),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFB0572F),
    );
    final daun = Paint()..color = const Color(0xFF5E8C3A);
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + (i - 2) * 0.5;
      canvas.drawOval(
        Rect.fromCenter(
          center: pos + Offset(math.cos(angle) * 14 * skala, -6 + math.sin(angle) * 18 * skala),
          width: 12 * skala,
          height: 24 * skala,
        ),
        daun,
      );
    }
  }

  void _ac(Canvas canvas, Offset pos) {
    drawPanel(canvas, Rect.fromCenter(center: pos, width: 96, height: 30), radius: 8,
        fill: const Color(0xFFF4F4EF), border: const Color(0xFFB9B4A5), borderWidth: 2);
    final garis = Paint()
      ..color = const Color(0xFFC9C3B2)
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(Offset(pos.dx - 34, pos.dy - 4 + i * 5), Offset(pos.dx + 34, pos.dy - 4 + i * 5), garis);
    }
  }
}
