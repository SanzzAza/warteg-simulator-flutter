/// Tipe pelanggan NPC dengan selera, anggaran, dan kesabaran berbeda.
library;

import 'menu_item.dart';

enum CustomerType { anakKos, pekerja, ojol, ibuRT, mahasiswa, bapakBapak, anakSekolah }

extension CustomerTypeX on CustomerType {
  String get label {
    switch (this) {
      case CustomerType.anakKos:
        return 'Anak Kos';
      case CustomerType.pekerja:
        return 'Pekerja';
      case CustomerType.ojol:
        return 'Driver Ojol';
      case CustomerType.ibuRT:
        return 'Ibu Rumah Tangga';
      case CustomerType.mahasiswa:
        return 'Mahasiswa';
      case CustomerType.bapakBapak:
        return 'Bapak-Bapak';
      case CustomerType.anakSekolah:
        return 'Anak Sekolah';
    }
  }

  /// Warna badan untuk menggambar sprite (ARGB).
  int get colorArgb {
    switch (this) {
      case CustomerType.anakKos:
        return 0xFF42A5F5;
      case CustomerType.pekerja:
        return 0xFF5C6BC0;
      case CustomerType.ojol:
        return 0xFF26A69A;
      case CustomerType.ibuRT:
        return 0xFFEC407A;
      case CustomerType.mahasiswa:
        return 0xFFAB47BC;
      case CustomerType.bapakBapak:
        return 0xFF8D6E63;
      case CustomerType.anakSekolah:
        return 0xFFFFCA28;
    }
  }
}

/// Profil perilaku satu tipe pelanggan.
class CustomerProfile {
  final int budgetMin;
  final int budgetMax;

  /// Kesabaran menunggu dalam menit game.
  final int patienceMinutes;

  /// Kategori menu yang disukai (urutan = prioritas).
  final List<MenuCategory> favoriteCategories;

  /// Kecepatan jalan sprite (pengali).
  final double speed;

  const CustomerProfile({
    required this.budgetMin,
    required this.budgetMax,
    required this.patienceMinutes,
    required this.favoriteCategories,
    required this.speed,
  });
}

const Map<CustomerType, CustomerProfile> kCustomerProfiles = {
  CustomerType.anakKos: CustomerProfile(budgetMin: 8000, budgetMax: 15000, patienceMinutes: 25, favoriteCategories: [MenuCategory.lauk, MenuCategory.nasi, MenuCategory.minuman], speed: 1.0),
  CustomerType.pekerja: CustomerProfile(budgetMin: 15000, budgetMax: 30000, patienceMinutes: 12, favoriteCategories: [MenuCategory.nasi, MenuCategory.lauk, MenuCategory.minuman], speed: 1.2),
  CustomerType.ojol: CustomerProfile(budgetMin: 10000, budgetMax: 20000, patienceMinutes: 10, favoriteCategories: [MenuCategory.nasi, MenuCategory.lauk], speed: 1.4),
  CustomerType.ibuRT: CustomerProfile(budgetMin: 12000, budgetMax: 25000, patienceMinutes: 30, favoriteCategories: [MenuCategory.sayur, MenuCategory.lauk, MenuCategory.pelengkap], speed: 0.9),
  CustomerType.mahasiswa: CustomerProfile(budgetMin: 8000, budgetMax: 18000, patienceMinutes: 20, favoriteCategories: [MenuCategory.nasi, MenuCategory.minuman, MenuCategory.lauk], speed: 1.0),
  CustomerType.bapakBapak: CustomerProfile(budgetMin: 15000, budgetMax: 35000, patienceMinutes: 25, favoriteCategories: [MenuCategory.lauk, MenuCategory.minuman, MenuCategory.pelengkap], speed: 0.9),
  CustomerType.anakSekolah: CustomerProfile(budgetMin: 5000, budgetMax: 10000, patienceMinutes: 15, favoriteCategories: [MenuCategory.minuman, MenuCategory.pelengkap, MenuCategory.lauk], speed: 1.1),
};

/// Bobot kemunculan tiap tipe (anak kos & ojol lebih sering).
const Map<CustomerType, int> kCustomerWeights = {
  CustomerType.anakKos: 20,
  CustomerType.pekerja: 16,
  CustomerType.ojol: 18,
  CustomerType.ibuRT: 12,
  CustomerType.mahasiswa: 14,
  CustomerType.bapakBapak: 10,
  CustomerType.anakSekolah: 10,
};
