/// Pembungkus efek suara berbasis `flame_audio`.
///
/// Semua suara aman-gagal: bila aset tidak tersedia atau audio gagal
/// dimuat, game tetap berjalan tanpa error.
library;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioSvc {
  AudioSvc._();

  static final AudioSvc instance = AudioSvc._();

  bool _siap = false;
  bool aktif = true;

  /// Muat semua efek suara ke cache (dipanggil sekali di main).
  Future<void> inisialisasi() async {
    try {
      await FlameAudio.audioCache.loadAll([
        for (final nama in _file.values) 'audio/$nama',
      ]);
      _siap = true;
    } catch (e) {
      debugPrint('Audio tidak tersedia: $e');
      _siap = false;
    }
  }

  static const Map<String, String> _file = {
    'klik': 'klik.wav',
    'koin': 'koin.wav',
    'beli': 'beli.wav',
    'salah': 'salah.wav',
    'masak': 'masak.wav',
  };

  /// Mainkan efek suara berdasarkan nama logis.
  void mainkan(String nama) {
    if (!aktif || !_siap) return;
    final file = _file[nama];
    if (file == null) return;
    try {
      FlameAudio.play('audio/$file', volume: 0.6);
    } catch (e) {
      debugPrint('Gagal memutar $nama: $e');
    }
  }

  void klik() => mainkan('klik');
  void koin() => mainkan('koin');
  void beli() => mainkan('beli');
  void salah() => mainkan('salah');
  void masak() => mainkan('masak');
}
