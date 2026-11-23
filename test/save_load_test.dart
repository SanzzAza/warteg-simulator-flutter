// Unit test serialisasi save/load (JSON via Hive) tanpa dependensi platform.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:warteg_simulator/data/models/employee.dart';
import 'package:warteg_simulator/data/models/customer_type.dart';
import 'package:warteg_simulator/data/models/game_state.dart';

void main() {
  test('state baru bisa di-serialize dan dimuat kembali persis', () {
    final asli = GameState.newGame()
      ..money = 1234567
      ..day = 7
      ..minuteOfDay = 720
      ..weather = Weather.hujan
      ..reputation = 4.25
      ..level = 3
      ..xp = 42
      ..employees = [
        Employee(id: 'e1', name: 'Pak Budi', role: EmployeeRole.juruMasak, skill: 3, xp: 55),
        Employee(id: 'e2', name: 'Mbak Rina', role: EmployeeRole.kasir, skill: 2),
      ]
      ..upgrades = {'etalase': 2, 'kompor': 1, 'cabang': 1}
      ..branchCount = 2
      ..dailyIncome = 250000
      ..dailyExpense = 90000
      ..dailyServed = 12
      ..totalServed = 120
      ..menuPrices['nasi_putih'] = 6000;
    asli.dishBatches.add(DishBatch(menuId: 'nasi_putih', qty: 3, freshness: 71.5));
    asli.cookingQueue.add(
      CookingJob(menuId: 'ayam_goreng', portions: 2, progress: 3, totalMinutes: 30),
    );
    asli.customers.add(CustomerSim(
      id: 99,
      type: CustomerType.ojol,
      stage: CustomerStage.antre,
      patience: 8.5,
      budget: 15000,
      satisfaction: 4.2,
      queueIndex: 2,
    ));
    asli.reports.add(DailyReport(
      day: 6,
      income: 300000,
      expense: 120000,
      served: 20,
      lost: 2,
      spoiled: 1,
    ));

    // Simulasi penyimpanan Hive: JSON string.
    final json = jsonEncode(asli.toMap());
    final hasil = GameState.fromMap(jsonDecode(json) as Map<String, dynamic>);

    expect(hasil.money, asli.money);
    expect(hasil.day, asli.day);
    expect(hasil.weather, Weather.hujan);
    expect(hasil.reputation, 4.25);
    expect(hasil.level, 3);
    expect(hasil.xp, 42);
    expect(hasil.employees, hasLength(2));
    expect(hasil.employees.first.role, EmployeeRole.juruMasak);
    expect(hasil.employees.first.skill, 3);
    expect(hasil.branchCount, 2);
    expect(hasil.seatCount, asli.seatCount); // ikut bertambah karena cabang
    expect(hasil.dishBatches.first.freshness, 71.5);
    expect(hasil.cookingQueue.first.portions, 2);
    expect(hasil.customers.first.type, CustomerType.ojol);
    expect(hasil.customers.first.queueIndex, 2);
    expect(hasil.reports.first.profit, 180000);
    expect(hasil.priceOf('nasi_putih'), 6000);
    expect(hasil.stockOf('beras'), asli.stockOf('beras'));
  });

  test('toMap menghasilkan struktur JSON yang aman (tanpa objek khusus)', () {
    final map = GameState.newGame().toMap();
    // Akan throw bila ada tipe non-JSON.
    expect(() => jsonEncode(map), returnsNormally);
  });

  test('state kosong / minimal tetap bisa dimuat (kompatibilitas)', () {
    final minimal = {
      'money': 5000,
      'day': 1,
      'minuteOfDay': 360,
      'weather': 0,
      'reputation': 3.0,
      'level': 1,
      'xp': 0,
      'ingredientBatches': <dynamic>[],
      'dishBatches': <dynamic>[],
      'cookingQueue': <dynamic>[],
      'menuPrices': <String, dynamic>{},
      'employees': <dynamic>[],
      'upgrades': <String, dynamic>{},
      'branchCount': 1,
      'customers': <dynamic>[],
      'nextCustomerId': 1,
      'dailyIncome': 0,
      'dailyExpense': 0,
      'dailyServed': 0,
      'dailyLost': 0,
      'dailySpoiled': 0,
      'totalServed': 0,
      'totalLost': 0,
      'totalSpoiled': 0,
      'totalIncome': 0,
      'reports': <dynamic>[],
      'settings': {'soundOn': true, 'speed': 1, 'paused': false},
    };
    final state = GameState.fromMap(minimal);
    expect(state.money, 5000);
    expect(state.displayCapacity, 6);
  });
}
