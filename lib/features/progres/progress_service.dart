/// Logika progres: XP, level, dan reputasi.
library;

import '../../core/app_config.dart';
import '../../data/models/game_state.dart';

class ProgressService {
  const ProgressService();

  /// Tambah XP; naik level otomatis bila cukup.
  void tambahXp(GameState state, int jumlah) {
    if (jumlah <= 0) return;
    state.xp += jumlah;
    while (state.level < kLevelMaks && state.xp >= xpUntukNaikLevel(state.level)) {
      state.xp -= xpUntukNaikLevel(state.level);
      state.level += 1;
    }
  }

  /// XP yang dibutuhkan untuk level berikutnya (0 bila sudah maks).
  int xpBerikutnya(GameState state) {
    if (state.level >= kLevelMaks) return 0;
    return xpUntukNaikLevel(state.level);
  }

  /// Progress XP 0..1 untuk progress bar HUD.
  double progressXp(GameState state) {
    final butuh = xpBerikutnya(state);
    if (butuh == 0) return 1;
    return (state.xp / butuh).clamp(0.0, 1.0);
  }

  /// Sesuaikan reputasi dengan nilai baru (clamp 1..5).
  void setReputasi(GameState state, double nilai) {
    state.reputation = nilai.clamp(1.0, 5.0);
  }
}
