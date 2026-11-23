/// Logika ekonomi: belanja bahan, memasak, penjualan, biaya harian.
///
/// Semua fungsi menerima [GameState] eksplisit sehingga mudah diuji unit
/// test tanpa Flutter.
library;

import '../../data/models/game_state.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/menu_item.dart';

/// Hasil cek kemampuan memasak.
class CookCheck {
  final bool bisa;
  final String alasan;

  const CookCheck(this.bisa, this.alasan);
}

class EconomyService {
  const EconomyService();

  // ---------- Belanja bahan ----------

  /// Total harga belanja [qty] porsi bahan [ingredientId].
  int biayaBelanja(String ingredientId, int qty) {
    final ing = kIngredients[ingredientId];
    if (ing == null || qty <= 0) return 0;
    return ing.buyPrice * qty;
  }

  /// Beli bahan; mengembalikan false jika uang tidak cukup.
  /// Batch baru berlaku sampai `day + shelfLifeDays`.
  bool beliBahan(GameState state, String ingredientId, int qty) {
    final ing = kIngredients[ingredientId];
    if (ing == null || qty <= 0) return false;
    final cost = biayaBelanja(ingredientId, qty);
    if (state.money < cost) return false;

    state.money -= cost;
    state.dailyExpense += cost;
    state.ingredientBatches.add(
      IngredientBatch(
        ingredientId: ingredientId,
        qty: qty,
        expiryDay: state.day + ing.shelfLifeDays,
      ),
    );
    return true;
  }

  // ---------- Memasak ----------

  /// Cek apakah menu bisa dimasak: level terbuka, kapasitas etalase, bahan.
  CookCheck cekMemasak(GameState state, String menuId, int portions) {
    final menu = menuById(menuId);
    if (menu == null) return const CookCheck(false, 'Menu tidak dikenal.');
    if (state.level < menu.unlockLevel) {
      return CookCheck(false, 'Menu terkunci sampai level ${menu.unlockLevel}.');
    }
    if (portions <= 0) return const CookCheck(false, 'Jumlah porsi tidak valid.');
    if (state.dishCount + portions > state.displayCapacity) {
      return CookCheck(
        false,
        'Etalase penuh (kapasitas ${state.displayCapacity} porsi).',
      );
    }
    for (final entry in menu.recipe.entries) {
      if (state.stockOf(entry.key) < entry.value * portions) {
        final ing = kIngredients[entry.key];
        return CookCheck(false, 'Bahan ${ing?.name ?? entry.key} kurang.');
      }
    }
    return const CookCheck(true, '');
  }

  /// Kurangi bahan (batch paling cepat kedaluwarsa lebih dulu / FEFO).
  void pakaiBahan(GameState state, String ingredientId, int qty) {
    state.ingredientBatches.sort((a, b) => a.expiryDay.compareTo(b.expiryDay));
    var sisa = qty;
    for (final batch in state.ingredientBatches) {
      if (sisa <= 0) break;
      if (batch.ingredientId != ingredientId) continue;
      final pakai = batch.qty >= sisa ? sisa : batch.qty;
      batch.qty -= pakai;
      sisa -= pakai;
    }
    state.ingredientBatches.removeWhere((b) => b.qty <= 0);
  }

  /// Masukkan pesanan masak ke antrean. Mengembalikan false bila tidak bisa.
  bool mulaiMasak(GameState state, String menuId, int portions) {
    final cek = cekMemasak(state, menuId, portions);
    if (!cek.bisa) return false;
    final menu = menuById(menuId)!;

    // Bahan langsung dipakai saat mulai memasak.
    menu.recipe.forEach((bahanId, jumlah) {
      pakaiBahan(state, bahanId, jumlah * portions);
    });

    final totalMenit = menu.cookMinutes * portions / state.cookSpeedMultiplier;
    state.cookingQueue.add(
      CookingJob(menuId: menuId, portions: portions, totalMinutes: totalMenit),
    );
    return true;
  }

  /// Majukan antrean masak sebanyak [menitGame]. Hasil masakan masuk etalase.
  void prosesMasak(GameState state, double menitGame) {
    if (state.cookingQueue.isEmpty) return;
    final job = state.cookingQueue.first;
    job.progress += menitGame;
    if (job.progress >= job.totalMinutes) {
      _selesaikanMasak(state, job);
      state.cookingQueue.removeAt(0);
    }
  }

  void _selesaikanMasak(GameState state, CookingJob job) {
    final sisaKapasitas = state.displayCapacity - state.dishCount;
    final porsiMasuk = job.portions.clamp(0, sisaKapasitas < 0 ? 0 : sisaKapasitas);
    if (porsiMasuk <= 0) return;

    // Gabung ke batch sejenis yang masih segar, atau buat batch baru.
    for (final batch in state.dishBatches) {
      if (batch.menuId == job.menuId && batch.freshness > 60) {
        batch.qty += porsiMasuk;
        return;
      }
    }
    state.dishBatches.add(
      DishBatch(menuId: job.menuId, qty: porsiMasuk, freshness: 100),
    );
  }

  // ---------- Kesegaran ----------

  /// Turunkan kesegaran masakan. Porsi dengan kesegaran <= 0 dibuang.
  /// Mengembalikan jumlah porsi yang dibuang.
  int prosesKesegaran(GameState state, double jamGame) {
    if (jamGame <= 0) return 0;
    final decay = state.freshnessDecayPerHour * jamGame;
    var dibuang = 0;
    for (final batch in state.dishBatches) {
      batch.freshness -= decay;
    }
    final basi = state.dishBatches.where((b) => b.freshness <= 0).toList();
    for (final batch in basi) {
      dibuang += batch.qty;
      state.dishBatches.remove(batch);
    }
    state.dailySpoiled += dibuang;
    state.totalSpoiled += dibuang;
    return dibuang;
  }

  /// Buang bahan yang sudah lewat tanggal kedaluwarsa.
  int prosesBahanKedaluwarsa(GameState state) {
    var dibuang = 0;
    final rusak = state.ingredientBatches.where((b) => b.expiryDay < state.day).toList();
    for (final batch in rusak) {
      dibuang += batch.qty;
      state.ingredientBatches.remove(batch);
    }
    return dibuang;
  }

  /// Ambil [qty] porsi menu dari etalase. Mengembalikan kesegaran tiap porsi
  /// yang diambil (list kosong bila stok tidak cukup).
  List<double> ambilPorsi(GameState state, String menuId, int qty) {
    final tersedia = state.dishBatches
        .where((b) => b.menuId == menuId)
        .fold<int>(0, (a, b) => a + b.qty);
    if (tersedia < qty) return const [];

    final hasil = <double>[];
    var sisa = qty;
    // Ambil dari batch paling tidak segar dulu agar tidak terbuang.
    final urut = state.dishBatches.where((b) => b.menuId == menuId).toList()
      ..sort((a, b) => a.freshness.compareTo(b.freshness));
    for (final batch in urut) {
      if (sisa <= 0) break;
      final ambil = batch.qty >= sisa ? sisa : batch.qty;
      for (var i = 0; i < ambil; i++) {
        hasil.add(batch.freshness);
      }
      batch.qty -= ambil;
      sisa -= ambil;
    }
    state.dishBatches.removeWhere((b) => b.qty <= 0);
    return hasil;
  }

  /// Catat penjualan ke kas & statistik.
  void catatPenjualan(GameState state, int amount) {
    state.money += amount;
    state.dailyIncome += amount;
    state.totalIncome += amount;
  }

  /// Bayar biaya tetap + gaji saat tutup warung. Mengembalikan totalnya.
  int bayarBiayaHarian(GameState state) {
    final total = state.dailyFixedCost + state.dailyWages;
    state.money -= total;
    state.dailyExpense += total;
    return total;
  }
}
