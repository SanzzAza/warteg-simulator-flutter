/// Model karyawan: juru masak, kasir, pelayan.
///
/// Skill (1-5) memengaruhi kecepatan & kualitas kerja:
/// - Juru masak: mempercepat proses memasak.
/// - Kasir: mempercepat transaksi (antrean lebih cepat).
/// - Pelayan: mempercepat penyajian & menaikkan kepuasan.
library;

enum EmployeeRole { juruMasak, kasir, pelayan }

extension EmployeeRoleX on EmployeeRole {
  String get label {
    switch (this) {
      case EmployeeRole.juruMasak:
        return 'Juru Masak';
      case EmployeeRole.kasir:
        return 'Kasir';
      case EmployeeRole.pelayan:
        return 'Pelayan';
    }
  }

  String get desc {
    switch (this) {
      case EmployeeRole.juruMasak:
        return 'Mempercepat memasak di dapur.';
      case EmployeeRole.kasir:
        return 'Mempercepat transaksi & antrean.';
      case EmployeeRole.pelayan:
        return 'Mempercepat penyajian & menaikkan kepuasan.';
    }
  }

  /// Gaji harian dasar (Rupiah).
  int get baseWage {
    switch (this) {
      case EmployeeRole.juruMasak:
        return 40000;
      case EmployeeRole.kasir:
        return 30000;
      case EmployeeRole.pelayan:
        return 25000;
    }
  }

  /// Biaya rekrut (sekali bayar).
  int get hireFee => baseWage * 2;
}

class Employee {
  final String id;
  final String name;
  final EmployeeRole role;

  /// Level skill 1-5.
  int skill;

  /// XP akumulasi untuk naik skill.
  int xp;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    this.skill = 1,
    this.xp = 0,
  });

  /// Gaji harian = gaji dasar + bonus skill.
  int get wagePerDay => role.baseWage + (skill - 1) * 5000;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role.index,
        'skill': skill,
        'xp': xp,
      };

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
        id: map['id'] as String,
        name: map['name'] as String,
        role: EmployeeRole.values[map['role'] as int],
        skill: (map['skill'] as num).toInt(),
        xp: (map['xp'] as num).toInt(),
      );
}

/// Kumpulan nama Indonesia untuk karyawan baru.
const List<String> kNamaKaryawan = [
  'Bu Sari', 'Pak Budi', 'Mbak Rina', 'Mas Andi', 'Bu Wati', 'Pak Slamet',
  'Mbak Dewi', 'Mas Joko', 'Bu Ani', 'Pak Rudi', 'Mbak Tini', 'Mas Dedi',
  'Bu Lilis', 'Pak Herman', 'Mbak Fitri', 'Mas Bayu',
];
