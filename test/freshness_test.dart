// Unit test kesegaran makanan & kedaluwarsa bahan.
import 'package:flutter_test/flutter_test.dart';
import 'package:warteg_simulator/data/models/game_state.dart';
import 'package:warteg_simulator/features/ekonomi/economy_service.dart';

void main() {
  const economy = EconomyService();

  test('kesegaran turun sesuai waktu berjalan', () {
    final state = GameState.newGame();
    state.dishBatches.add(DishBatch(menuId: 'tempe_goreng', qty: 2, freshness: 100));

    economy.prosesKesegaran(state, 1); // 1 jam

    // Decay dasar 20/jam tanpa upgrade.
    expect(state.dishBatches.first.freshness, closeTo(80, 0.001));
  });

  test('makanan basi terbuang dan tercatat sebagai kerugian', () {
    final state = GameState.newGame();
    state.dishBatches.add(DishBatch(menuId: 'tempe_goreng', qty: 3, freshness: 10));

    final dibuang = economy.prosesKesegaran(state, 1); // turun 20 -> -10

    expect(dibuang, 3);
    expect(state.dishBatches, isEmpty);
    expect(state.dailySpoiled, 3);
    expect(state.totalSpoiled, 3);
  });

  test('kulkas & etalase memperlambat penurunan kesegaran', () {
    final biasa = GameState.newGame();
    final dingin = GameState.newGame()
      ..upgrades['kulkas'] = 2
      ..upgrades['etalase'] = 2;

    expect(dingin.freshnessDecayPerHour, lessThan(biasa.freshnessDecayPerHour));

    biasa.dishBatches.add(DishBatch(menuId: 'tahu_goreng', qty: 1, freshness: 100));
    dingin.dishBatches.add(DishBatch(menuId: 'tahu_goreng', qty: 1, freshness: 100));
    economy.prosesKesegaran(biasa, 2);
    economy.prosesKesegaran(dingin, 2);

    expect(
      dingin.dishBatches.first.freshness,
      greaterThan(biasa.dishBatches.first.freshness),
    );
  });

  test('decay tidak pernah di bawah 4 poin per jam', () {
    final state = GameState.newGame()
      ..upgrades['kulkas'] = 5
      ..upgrades['etalase'] = 5;
    expect(state.freshnessDecayPerHour, greaterThanOrEqualTo(4));
  });

  test('bahan lewat tanggal kedaluwarsa dibuang', () {
    final state = GameState.newGame();
    state.ingredientBatches
      ..clear()
      ..add(IngredientBatch(ingredientId: 'ayam', qty: 5, expiryDay: 1))
      ..add(IngredientBatch(ingredientId: 'beras', qty: 5, expiryDay: 30));
    state.day = 3;

    final dibuang = economy.prosesBahanKedaluwarsa(state);

    expect(dibuang, 5);
    expect(state.stockOf('ayam'), 0);
    expect(state.stockOf('beras'), 5);
  });

  test('bahan dipakai dengan urutan FEFO (paling cepat kedaluwarsa)', () {
    final state = GameState.newGame();
    state.ingredientBatches
      ..clear()
      ..add(IngredientBatch(ingredientId: 'tempe', qty: 5, expiryDay: 10))
      ..add(IngredientBatch(ingredientId: 'tempe', qty: 5, expiryDay: 3));

    economy.pakaiBahan(state, 'tempe', 6);

    final sisa = state.ingredientBatches.where((b) => b.ingredientId == 'tempe').toList();
    // Batch expiry 3 habis dulu, sisa 4 di batch expiry 10.
    expect(sisa, hasLength(1));
    expect(sisa.first.expiryDay, 10);
    expect(sisa.first.qty, 4);
  });
}
