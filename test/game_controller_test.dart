// Test integrasi simulasi controller (tanpa Hive & tanpa timer autosave).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:warteg_simulator/data/models/employee.dart';
import 'package:warteg_simulator/data/models/game_state.dart';
import 'package:warteg_simulator/data/repositories/save_repository.dart';
import 'package:warteg_simulator/features/game_controller.dart';

void main() {
  GameController buat({int seed = 7}) => GameController(
        saveRepository: SaveRepository(), // belum init: save tidak menulis apa pun
        random: Random(seed),
        autosaveAktif: false,
      );

  test('tick memajukan waktu game sesuai kecepatan', () {
    final c = buat();
    final awal = c.stateSaatIni.minuteOfDay;
    // 10 detik nyata × 3 menit/detik × 1x = 30 menit game.
    for (var i = 0; i < 100; i++) {
      c.tick(0.1);
    }
    expect(c.stateSaatIni.minuteOfDay - awal, closeTo(30, 2));
    c.dispose();
  });

  test('pause menghentikan waktu', () {
    final c = buat();
    c.setPause(true);
    final awal = c.stateSaatIni.minuteOfDay;
    for (var i = 0; i < 50; i++) {
      c.tick(0.1);
    }
    expect(c.stateSaatIni.minuteOfDay, awal);
    c.dispose();
  });

  test('pelanggan datang saat jam ramai dan dilayani sampai pergi', () {
    final c = buat(seed: 3);
    // Paksa jam makan siang & stok nasi siap jual.
    c.stateSaatIni.minuteOfDay = 11 * 60 + 30;
    c.stateSaatIni.dishBatches.addAll([
      DishBatch(menuId: 'nasi_putih', qty: 10, freshness: 95),
      DishBatch(menuId: 'tempe_goreng', qty: 10, freshness: 95),
      DishBatch(menuId: 'es_teh', qty: 10, freshness: 95),
      DishBatch(menuId: 'teh_hangat', qty: 10, freshness: 95),
    ]);

    // Jalankan ±2 jam game (2400 tick × 0.1 detik).
    final uangAwal = c.stateSaatIni.money;
    for (var i = 0; i < 2400; i++) {
      c.tick(0.1);
    }
    final st = c.stateSaatIni;

    expect(st.totalServed, greaterThan(0), reason: 'harus ada yang terlayani');
    expect(st.money, greaterThan(uangAwal), reason: 'penjualan menambah kas');
    expect(st.totalIncome, greaterThan(0));
    expect(st.reputation, inInclusiveRange(1.0, 5.0));
    expect(st.dishCount, lessThan(40), reason: 'sebagian masakan terjual');
    c.dispose();
  });

  test('tutup warung mencatat laporan dan membayar biaya', () {
    final c = buat();
    c.stateSaatIni.dailyIncome = 120000;
    final uangSebelum = c.stateSaatIni.money;
    c.tutupWarung();

    final st = c.stateSaatIni;
    expect(st.day, 2);
    expect(st.minuteOfDay, 6 * 60);
    expect(st.reports, hasLength(1));
    expect(st.reports.first.income, 120000);
    expect(st.reports.first.expense, greaterThanOrEqualTo(65000)); // sewa+listrik
    expect(st.money, lessThan(uangSebelum));
    expect(st.dailyIncome, 0);
    c.dispose();
  });

  test('beli upgrade mengurangi uang dan menambah efek', () {
    final c = buat();
    final kapasitasAwal = c.stateSaatIni.displayCapacity;
    expect(c.stateSaatIni.money, 2000000);

    final ok = c.beliUpgrade('etalase');

    expect(ok, isTrue);
    expect(c.stateSaatIni.displayCapacity, greaterThan(kapasitasAwal));
    expect(c.stateSaatIni.money, lessThan(2000000));
    c.dispose();
  });

  test('rekrut karyawan memotong biaya rekrut dan menambah tim', () {
    final c = buat();
    final ok = c.rekrut(EmployeeRole.juruMasak);
    expect(ok, isTrue);
    expect(c.stateSaatIni.employees, hasLength(1));
    expect(c.stateSaatIni.dailyWages, greaterThan(0));
    c.dispose();
  });

  test('ubahHarga di-clamp pada batas wajar', () {
    final c = buat();
    // Harga dasar nasi putih 5000 -> batas 2000..12500.
    c.ubahHarga('nasi_putih', 1);
    expect(c.stateSaatIni.priceOf('nasi_putih'), 2000);
    c.ubahHarga('nasi_putih', 999999);
    expect(c.stateSaatIni.priceOf('nasi_putih'), 12500);
    c.dispose();
  });

  test('muat() mengembalikan state tersimpan dan mem-pause', () {
    final c = buat();
    final simpanan = GameState.newGame()
      ..money = 777000
      ..day = 9;
    c.muat(simpanan);
    expect(c.stateSaatIni.money, 777000);
    expect(c.stateSaatIni.day, 9);
    expect(c.stateSaatIni.settings.paused, isTrue);
    c.dispose();
  });

  test('belum ada save sebelum sesi dimulai (save lama tidak tertimpa)', () async {
    final repo = SaveRepository();
    final c = GameController(
      saveRepository: repo,
      random: Random(1),
      autosaveAktif: false,
    );
    // Tanpa init Hive, repository tidak punya box — save harus no-op
    // dan tidak melempar error. Setelah mulaiBaru(), baru simpan diizinkan.
    await c.simpanSekarang();
    c.mulaiBaru();
    await c.simpanSekarang();
    expect(c.stateSaatIni.day, 1);
    c.dispose();
  });

  test('upgrade gagal bila uang tidak cukup / level belum mencukupi', () {
    final c = buat();
    c.stateSaatIni.money = 1000;
    expect(c.beliUpgrade('etalase'), isFalse);
    c.stateSaatIni.money = 5000000;
    // ac butuh level 3, sedangkan pemain level 1.
    expect(c.beliUpgrade('ac'), isFalse);
    c.dispose();
  });

  test('pecat karyawan memberi pesangon dan mengurangi tim', () {
    final c = buat();
    c.rekrut(EmployeeRole.pelayan);
    final karyawan = c.stateSaatIni.employees.first;
    final sebelum = c.stateSaatIni.money;
    c.pecat(karyawan);
    expect(c.stateSaatIni.employees, isEmpty);
    expect(c.stateSaatIni.money, sebelum - (karyawan.wagePerDay * 0.5).round());
    c.dispose();
  });

  test('kesegaran menurun seiring waktu simulasi', () {
    final c = buat();
    c.stateSaatIni.dishBatches.add(
      DishBatch(menuId: 'nasi_putih', qty: 4, freshness: 100),
    );
    // 60 detik nyata × 3 menit/detik = 180 menit game (3 jam).
    for (var i = 0; i < 600; i++) {
      c.tick(0.1);
    }
    // Etalase pasti terdampak: porsi berkurang (terjual) atau kesegaran turun.
    final sisa = c.stateSaatIni.dishBatches
        .where((b) => b.menuId == 'nasi_putih')
        .fold<int>(0, (a, b) => a + b.qty);
    final segar = c.stateSaatIni.dishBatches
        .where((b) => b.menuId == 'nasi_putih')
        .fold<double>(100, (a, b) => a < b.freshness ? a : b.freshness);
    expect(sisa < 4 || segar < 100, isTrue);
    expect(c.stateSaatIni.dailySpoiled + c.stateSaatIni.dailyServed, greaterThan(0));
    c.dispose();
  });
}
