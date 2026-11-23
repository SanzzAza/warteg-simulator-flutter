/// Meja & kursi pelanggan.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../paint_utils.dart';
import '../scene_layout.dart';

class TableComponent extends PositionComponent {
  TableComponent({required this.index, required this.seatCount, required this.occupied})
      : super(position: Vector2(SceneLayout.meja[index].dx, SceneLayout.meja[index].dy), priority: 5 + SceneLayout.meja[index].dy ~/ 4);

  final int index;

  /// Berapa kursi yang bisa dipakai meja ini (0..4).
  final int seatCount;

  /// Jumlah kursi yang sedang terisi (untuk kursi miring/terpakai).
  final bool Function(int seatIndex) occupied;

  @override
  void render(Canvas canvas) {
    // Meja kayu 110x110 dengan taplak kecil.
    const meja = Rect.fromLTWH(0, 0, 110, 110);
    drawShadow(canvas, const Offset(55, 78), 56, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(meja, const Radius.circular(10)),
      Paint()..color = const Color(0xFFB98544),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(meja.deflate(5), const Radius.circular(8)),
      Paint()..color = const Color(0xFFD9A55C),
    );
    // Motif garis meja.
    final garis = Paint()
      ..color = const Color(0x225A3A17)
      ..strokeWidth = 2;
    for (var y = 20.0; y < 100; y += 18) {
      canvas.drawLine(Offset(10, y), Offset(100, y), garis);
    }
    // Taplak oranye di tengah.
    canvas.drawCircle(
      const Offset(55, 55),
      22,
      Paint()..color = const Color(0x99F28A1B),
    );

    // Kursi plastik di sekeliling (sesuai seatCount).
    const posisi = [
      Offset(55, -62),
      Offset(172, 55),
      Offset(55, 172),
      Offset(-62, 55),
    ];
    for (var i = 0; i < seatCount && i < 4; i++) {
      final globalSeat = index * 4 + i;
      final dipakai = occupied(globalSeat);
      _kursi(canvas, posisi[i], dipakai);
    }
  }

  void _kursi(Canvas canvas, Offset center, bool dipakai) {
    // Kursi plastik: punggung melengkung + dudukan, orientasi mengikuti
    // posisi kursi terhadap meja.
    final warna = dipakai ? const Color(0xFFC6543F) : const Color(0xFFDA7452);
    final gelap = dipakai ? const Color(0xFF9E3B2C) : const Color(0xFFB8543A);

    // Arah menghadap meja.
    final keMeja = const Offset(55, 55) - center;
    final arah = keMeja.distance == 0 ? const Offset(0, -1) : keMeja / keMeja.distance;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.atan2(arah.dy, arah.dx) + math.pi / 2);

    // Dudukan.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-16, -8, 16, 14), const Radius.circular(6)),
      Paint()..color = warna,
    );
    // Punggung kursi (sisi jauh dari meja).
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTRB(-17, -20, 17, -6), const Radius.circular(7)),
      Paint()..color = gelap,
    );
    // Kaki kecil.
    canvas.drawRect(const Rect.fromLTRB(-13, 14, -8, 20), Paint()..color = gelap);
    canvas.drawRect(const Rect.fromLTRB(8, 14, 13, 20), Paint()..color = gelap);
    canvas.restore();
  }
}
