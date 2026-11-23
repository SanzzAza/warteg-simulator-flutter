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
  bool _bgmSiap = false;
  bool aktif = true;

  /// Muat semua efek suara ke cache (dipanggil sekali di main).
  Future<void> inisialisasi() async {
    try {
      await FlameAudio.audioCache.loadAll([
        for (final nama in _file.values) 'audio/$nama',
        'audio/bgm_warung.wav',
      ]);
      _siap = true;
      _bgmSiap = true;
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

  /// Musik latar loop. Aman dipanggil berulang (tidak menumpuk).
  Future<void> mulaiMusik() async {
    if (!_siap || !_bgmSiap) return;
    if (FlameAudio.bgm.isPlaying) return;
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.bgm.play('audio/bgm_warung.wav', volume: 0.32);
    } catch (e) {
      debugPrint('BGM gagal diputar: $e');
    }
  }

  /// Hentikan musik (mis. saat app ke background / pemain matikan suara).
  Future<void> hentikanMusik() async {
    try {
      if (FlameAudio.bgm.isPlaying) await FlameAudio.bgm.pause();
    } catch (_) {
      // abaikan: audio opsional
    }
  }

  Future<void> lanjutkanMusik() async {
    if (!aktif) return;
    try {
      if (FlameAudio.bgm.isPlaying) return;
      await FlameAudio.bgm.resume();
    } catch (_) {
      await mulaiMusik();
    }
  }

  void klik() => mainkan('klik');
  void koin() => mainkan('koin');
  void beli() => mainkan('beli');
  void salah() => mainkan('salah');
  void masak() => mainkan('masak');
}
