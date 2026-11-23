/// Utilitas format tampilan (Rupiah, jam, bintang).
library;

/// Format angka menjadi Rupiah, contoh: 1250000 -> "Rp1.250.000".
String rupiah(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}Rp$buffer';
}

/// Ubah menit-dalam-hari (0-1439) menjadi "HH:MM".
String jamDariMenit(int minuteOfDay) {
  final h = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final m = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Representasi bintang reputasi, contoh: 4.3 -> "★★★★☆".
String bintang(double value) {
  final full = value.floor();
  final half = (value - full) >= 0.5;
  final buffer = StringBuffer();
  for (int i = 0; i < full; i++) {
    buffer.write('★');
  }
  if (half && full < 5) buffer.write('½');
  while (buffer.length < 5) {
    buffer.write('☆');
  }
  return buffer.toString();
}
