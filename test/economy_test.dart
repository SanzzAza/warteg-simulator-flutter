// Unit test logika ekonomi: belanja, memasak, penjualan, biaya harian.
import 'package:flutter_test/flutter_test.dart';
import 'package:warteg_simulator/data/models/employee.dart';
import 'package:warteg_simulator/data/models/game_state.dart';
import 'package:warteg_simulator/features/ekonomi/economy_service.dart';

void main() {
  const economy = EconomyService();

  group('Belanja bahan', () {
    test('modal awal Rp2.000.000 dan belanja mengurangi kas', () {
      final state = GameState.newGame();
      expect(state.money, 2000000);

      final awalTempe = state.stockOf('tempe');
      final ok = economy.beliBahan(state, 'tempe', 10);

      expect(ok, isTrue);
      expect(state.money, 2000000 - 3000 * 10);
      expect(state.stockOf('tempe'), awalTempe + 10);
      expect(state.dailyExpense, 30000);
    });

    test('belanja ditolak bila uang tidak cukup', () {
      final state = GameState.newGame()..money = 1000;
      final ok = economy.beliBahan(state, 'ayam', 5);
      expect(ok, isFalse);
      expect(state.money, 1000);
      expect(state.dailyExpense, 0);
    });

    test('batch baru memakai masa simpan bahan', () {
      final state = GameState.newGame();
      economy.beliBahan(state, 'kangkung', 4); // shelfLife 2 hari
      final batch = state.ingredientBatches
          .where((b) => b.ingredientId == 'kangkung')
          .last;
      expect(batch.expiryDay, state.day + 2);
    });
  });

  group('Memasak', () {
    test('memasak memakai bahan, butuh waktu, lalu masuk etalase', () {
      final state = GameState.newGame();
      final berasAwal = state.stockOf('beras');

      final ok = economy.mulaiMasak(state, 'nasi_putih', 5);
      expect(ok, isTrue);
      expect(state.stockOf('beras'), berasAwal - 5);
      expect(state.cookingQueue, hasLength(1));
      expect(state.dishBatches, isEmpty);

      // Selesaikan masak (5 porsi × 5 menit / speed 1 = 25 menit).
      economy.prosesMasak(state, 25);

      expect(state.cookingQueue, isEmpty);
      final nasi = state.dishBatches.firstWhere((d) => d.menuId == 'nasi_putih');
      expect(nasi.qty, 5);
      expect(nasi.freshness, 100);
    });

    test('memasak gagal bila bahan kurang', () {
      final state = GameState.newGame()..ingredientBatches.clear();
      final cek = economy.cekMemasak(state, 'ayam_goreng', 1);
      expect(cek.bisa, isFalse);
      expect(cek.alasan, contains('kurang'));
    });

    test('memasak gagal bila menu masih terkunci level', () {
      final state = GameState.newGame(); // level 1
      final cek = economy.cekMemasak(state, 'rendang', 1); // butuh level 4
      expect(cek.bisa, isFalse);
      expect(cek.alasan, contains('level'));
    });

    test('kapasitas etalase membatasi jumlah porsi', () {
      final state = GameState.newGame();
      // Kapasitas awal 6 porsi.
      final cek = economy.cekMemasak(state, 'nasi_putih', 10);
      expect(cek.bisa, isFalse);
      expect(cek.alasan, contains('Etalase penuh'));
    });

    test('upgrade kompor mempercepat waktu masak', () {
      final normal = GameState.newGame();
      final cepat = GameState.newGame()..upgrades['kompor'] = 4;

      expect(economy.mulaiMasak(normal, 'nasi_putih', 2), isTrue);
      expect(economy.mulaiMasak(cepat, 'nasi_putih', 2), isTrue);

      expect(
        cepat.cookingQueue.first.totalMinutes,
        lessThan(normal.cookingQueue.first.totalMinutes),
      );
    });
  });

  group('Penjualan & biaya', () {
    test('catatPenjualan menambah kas dan statistik', () {
      final state = GameState.newGame();
      economy.catatPenjualan(state, 23000);
      expect(state.money, 2023000);
      expect(state.dailyIncome, 23000);
      expect(state.totalIncome, 23000);
    });

    test('ambilPorsi mengurangi etalase dan mengembalikan kesegaran', () {
      final state = GameState.newGame();
      state.dishBatches.add(DishBatch(menuId: 'nasi_putih', qty: 3, freshness: 80));
      state.dishBatches.add(DishBatch(menuId: 'nasi_putih', qty: 2, freshness: 40));

      final kesegaran = economy.ambilPorsi(state, 'nasi_putih', 4);

      expect(kesegaran, hasLength(4));
      // Batch paling tidak segar diambil lebih dulu.
      expect(kesegaran.first, 40);
      expect(state.dishBatches.fold<int>(0, (a, b) => a + b.qty), 1);
    });

    test('ambilPorsi mengembalikan kosong bila stok kurang', () {
      final state = GameState.newGame();
      state.dishBatches.add(DishBatch(menuId: 'nasi_putih', qty: 1));
      expect(economy.ambilPorsi(state, 'nasi_putih', 2), isEmpty);
      expect(state.dishBatches.first.qty, 1);
    });

    test('biaya harian = sewa + listrik + gaji karyawan', () {
      final state = GameState.newGame();
      state.employees.add(Employee(
        id: 'emp_test',
        name: 'Bu Sari',
        role: EmployeeRole.kasir,
        skill: 2,
      ));
      final biaya = economy.bayarBiayaHarian(state);

      expect(biaya, state.dailyFixedCost + state.dailyWages);
      expect(state.money, 2000000 - biaya);
      expect(state.dailyExpense, biaya);
    });
  });
}
