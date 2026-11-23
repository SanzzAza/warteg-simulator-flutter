/// Helper kecil untuk menggambar teks & bentuk di Canvas Flame.
library;

import 'package:flutter/painting.dart';

/// Gambar teks satu baris. [align] mengatur titik acuan posisi.
void drawText(
  Canvas canvas,
  String text,
  Offset pos, {
  double fontSize = 16,
  Color color = const Color(0xFF3B2414),
  FontWeight weight = FontWeight.w700,
  TextAlign align = TextAlign.left,
  double? maxWidth,
  double letterSpacing = 0,
  bool shadow = false,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Roboto',
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        shadows: shadow
            ? const [Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))]
            : null,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth ?? 600);

  final dx = switch (align) {
    TextAlign.center => pos.dx - painter.width / 2,
    TextAlign.right => pos.dx - painter.width,
    _ => pos.dx,
  };
  painter.paint(canvas, Offset(dx, pos.dy));
}

/// Kotak membulat dengan bayangan lembut.
void drawPanel(
  Canvas canvas,
  Rect rect, {
  Color fill = const Color(0xFFFFF3D6),
  Color border = const Color(0xFF7A4A1D),
  double radius = 16,
  double borderWidth = 2,
  bool withShadow = true,
}) {
  final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  if (withShadow) {
    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
  canvas.drawPath(path, Paint()..color = fill);
  if (borderWidth > 0) {
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }
}

/// Bayangan elips di bawah objek (untuk kesan berdiri).
void drawShadow(Canvas canvas, Offset center, double rx, double ry) {
  canvas.drawOval(
    Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
    Paint()
      ..color = const Color(0x2E2B1B0E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
}
