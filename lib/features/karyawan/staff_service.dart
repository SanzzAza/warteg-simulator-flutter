/// Logika rekrutmen & pemecatan karyawan.
library;

import 'dart:math';

import '../../core/app_config.dart';
import '../../data/models/employee.dart';
import '../../data/models/game_state.dart';

class StaffService {
  const StaffService();

  int batasKaryawan(GameState state) =>
      state.branchCount > 1 ? kMaksKaryawanCabang : kMaksKaryawan;

  bool bisaRekrut(GameState state) => state.employees.length < batasKaryawan(state);

  /// Rekrut karyawan acak dengan skill awal 1-3. Mengembalikan karyawan baru,
  /// atau null bila gagal (uang kurang / penuh).
  Employee? rekrut(GameState state, EmployeeRole role, Random random) {
    if (!bisaRekrut(state)) return null;
    final biaya = role.hireFee;
    if (state.money < biaya) return null;

    // Skill awal dipengaruhi reputasi: warung terkenal menarik kandidat bagus.
    final bonus = ((state.reputation - 3) * 0.6).round();
    final skill = (1 + random.nextInt(3) + bonus).clamp(1, 5);

    // Pilih nama yang belum dipakai.
    final dipakai = state.employees.map((e) => e.name).toSet();
    final kandidat = kNamaKaryawan.where((n) => !dipakai.contains(n)).toList();
    final nama = kandidat.isEmpty
        ? kNamaKaryawan[random.nextInt(kNamaKaryawan.length)]
        : kandidat[random.nextInt(kandidat.length)];

    final karyawan = Employee(
      id: 'emp_${DateTime.now().microsecondsSinceEpoch}',
      name: nama,
      role: role,
      skill: skill,
    );

    state.money -= biaya;
    state.dailyExpense += biaya;
    state.employees.add(karyawan);
    return karyawan;
  }

  /// Pecat karyawan; pesangon = 50% gaji harian. Mengembalikan nominalnya.
  int pecat(GameState state, Employee employee) {
    final pesangon = (employee.wagePerDay * 0.5).round();
    state.employees.removeWhere((e) => e.id == employee.id);
    state.money -= pesangon;
    state.dailyExpense += pesangon;
    return pesangon;
  }
}
