/// Repository penyimpanan lokal berbasis Hive.
///
/// Dipilih Hive (bukan Isar) karena:
/// - Ringan, cepat, dan stabil di Android & Windows desktop.
/// - Tidak butuh code generation (build_runner) — state disimpan sebagai
///   JSON string dari [GameState.toMap], sehingga model tetap polos.
/// - API sederhana: satu box, satu key untuk autosave.
library;

import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/game_state.dart';

class SaveRepository {
  static const String boxName = 'warteg_save';
  static const String saveKey = 'game_state_json';

  Box<dynamic>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(boxName);
  }

  bool get hasSave => _box?.containsKey(saveKey) ?? false;

  Future<void> save(GameState state) async {
    final json = jsonEncode(state.toMap());
    await _box?.put(saveKey, json);
  }

  GameState? load() {
    final raw = _box?.get(saveKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      return GameState.fromMap(map);
    } catch (_) {
      return null; // Save rusak -> anggap tidak ada.
    }
  }

  Future<void> delete() async {
    await _box?.delete(saveKey);
  }
}
