/// Model menu makanan/minuman warteg.
///
/// [recipe] memetakan id bahan -> jumlah porsi bahan per 1 porsi masakan.
/// [basePrice] adalah harga jual awal; pemain bebas mengubahnya lewat
/// [GameState.menuPrices] dan itu memengaruhi minat pelanggan.
library;

import 'ingredient.dart';

enum MenuCategory { nasi, lauk, sayur, minuman, pelengkap }

extension MenuCategoryX on MenuCategory {
  String get label {
    switch (this) {
      case MenuCategory.nasi:
        return 'Nasi';
      case MenuCategory.lauk:
        return 'Lauk';
      case MenuCategory.sayur:
        return 'Sayur';
      case MenuCategory.minuman:
        return 'Minuman';
      case MenuCategory.pelengkap:
        return 'Pelengkap';
    }
  }
}

class MenuItem {
  final String id;
  final String name;
  final MenuCategory category;

  /// Bahan yang dibutuhkan per porsi (id bahan -> jumlah).
  final Map<String, int> recipe;

  /// Harga jual awal (Rupiah).
  final int basePrice;

  /// Waktu masak per porsi dalam menit game.
  final int cookMinutes;

  /// Level pemain minimum untuk membuka menu ini.
  final int unlockLevel;

  /// Warna untuk menggambar makanan di etalase (ARGB).
  final int colorArgb;

  /// Minuman panas — lebih diminati saat hujan.
  final bool hotDrink;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.recipe,
    required this.basePrice,
    required this.cookMinutes,
    required this.unlockLevel,
    required this.colorArgb,
    this.hotDrink = false,
  });

  /// Modal bahan per porsi (untuk info margin di UI).
  int get modalBahan {
    int total = 0;
    recipe.forEach((bahanId, jumlah) {
      total += (kIngredients[bahanId]?.buyPrice ?? 0) * jumlah;
    });
    return total;
  }
}

/// Database menu warteg (20 item). Tambah menu baru cukup di sini.
const List<MenuItem> kMenu = [
  MenuItem(id: 'nasi_putih', name: 'Nasi Putih', category: MenuCategory.nasi, recipe: {'beras': 1}, basePrice: 5000, cookMinutes: 5, unlockLevel: 1, colorArgb: 0xFFF5F0E1),
  MenuItem(id: 'orek_tempe', name: 'Orek Tempe', category: MenuCategory.lauk, recipe: {'tempe': 1, 'cabai': 1, 'bawang': 1, 'gula': 1}, basePrice: 8000, cookMinutes: 10, unlockLevel: 1, colorArgb: 0xFF8D5A2B),
  MenuItem(id: 'tempe_goreng', name: 'Tempe Goreng', category: MenuCategory.lauk, recipe: {'tempe': 1, 'tepung': 1, 'minyak': 1}, basePrice: 6000, cookMinutes: 8, unlockLevel: 1, colorArgb: 0xFFD9A441),
  MenuItem(id: 'tahu_goreng', name: 'Tahu Goreng', category: MenuCategory.lauk, recipe: {'tahu': 1, 'tepung': 1, 'minyak': 1}, basePrice: 6000, cookMinutes: 8, unlockLevel: 1, colorArgb: 0xFFF2C14E),
  MenuItem(id: 'telur_balado', name: 'Telur Balado', category: MenuCategory.lauk, recipe: {'telur': 1, 'cabai': 2, 'bawang': 1}, basePrice: 9000, cookMinutes: 10, unlockLevel: 2, colorArgb: 0xFFC62828),
  MenuItem(id: 'ayam_goreng', name: 'Ayam Goreng', category: MenuCategory.lauk, recipe: {'ayam': 1, 'minyak': 1, 'bawang': 1}, basePrice: 15000, cookMinutes: 15, unlockLevel: 1, colorArgb: 0xFFB26A00),
  MenuItem(id: 'sayur_lodeh', name: 'Sayur Lodeh', category: MenuCategory.sayur, recipe: {'sayur_campuran': 1, 'santan': 1, 'cabai': 1}, basePrice: 9000, cookMinutes: 12, unlockLevel: 2, colorArgb: 0xFF9E9D24),
  MenuItem(id: 'tumis_kangkung', name: 'Tumis Kangkung', category: MenuCategory.sayur, recipe: {'kangkung': 1, 'bawang': 1, 'cabai': 1}, basePrice: 8000, cookMinutes: 8, unlockLevel: 1, colorArgb: 0xFF2E7D32),
  MenuItem(id: 'sambal_terasi', name: 'Sambal Terasi', category: MenuCategory.pelengkap, recipe: {'cabai': 2, 'bawang': 1}, basePrice: 3000, cookMinutes: 5, unlockLevel: 1, colorArgb: 0xFFE53935),
  MenuItem(id: 'es_teh', name: 'Es Teh Manis', category: MenuCategory.minuman, recipe: {'teh': 1, 'gula': 1}, basePrice: 4000, cookMinutes: 3, unlockLevel: 1, colorArgb: 0xFFA1887F),
  MenuItem(id: 'teh_hangat', name: 'Teh Hangat', category: MenuCategory.minuman, recipe: {'teh': 1, 'gula': 1}, basePrice: 4000, cookMinutes: 3, unlockLevel: 1, colorArgb: 0xFF6D4C41, hotDrink: true),
  MenuItem(id: 'kopi_tubruk', name: 'Kopi Tubruk', category: MenuCategory.minuman, recipe: {'kopi': 1, 'gula': 1}, basePrice: 6000, cookMinutes: 4, unlockLevel: 2, colorArgb: 0xFF3E2723, hotDrink: true),
  MenuItem(id: 'sayur_asem', name: 'Sayur Asem', category: MenuCategory.sayur, recipe: {'sayur_campuran': 1, 'bawang': 1}, basePrice: 9000, cookMinutes: 12, unlockLevel: 3, colorArgb: 0xFF7CB342),
  MenuItem(id: 'lele_goreng', name: 'Lele Goreng', category: MenuCategory.lauk, recipe: {'lele': 1, 'minyak': 1, 'tepung': 1}, basePrice: 12000, cookMinutes: 12, unlockLevel: 2, colorArgb: 0xFF5D4037),
  MenuItem(id: 'rendang', name: 'Rendang Sapi', category: MenuCategory.lauk, recipe: {'daging': 1, 'santan': 1, 'cabai': 1}, basePrice: 20000, cookMinutes: 20, unlockLevel: 4, colorArgb: 0xFF4E342E),
  MenuItem(id: 'bakwan_jagung', name: 'Bakwan Jagung', category: MenuCategory.lauk, recipe: {'jagung': 1, 'tepung': 1, 'minyak': 1}, basePrice: 7000, cookMinutes: 8, unlockLevel: 2, colorArgb: 0xFFFFB300),
  MenuItem(id: 'lalapan', name: 'Lalapan', category: MenuCategory.pelengkap, recipe: {'kangkung': 1, 'cabai': 1}, basePrice: 4000, cookMinutes: 3, unlockLevel: 1, colorArgb: 0xFF66BB6A),
  MenuItem(id: 'kerupuk', name: 'Kerupuk', category: MenuCategory.pelengkap, recipe: {'tepung': 1, 'minyak': 1}, basePrice: 3000, cookMinutes: 5, unlockLevel: 1, colorArgb: 0xFFFFECB3),
  MenuItem(id: 'es_jeruk', name: 'Es Jeruk', category: MenuCategory.minuman, recipe: {'jeruk': 1, 'gula': 1}, basePrice: 5000, cookMinutes: 3, unlockLevel: 2, colorArgb: 0xFFFF9800),
  MenuItem(id: 'mie_goreng', name: 'Mie Goreng', category: MenuCategory.lauk, recipe: {'mie': 1, 'telur': 1, 'cabai': 1, 'minyak': 1}, basePrice: 12000, cookMinutes: 12, unlockLevel: 3, colorArgb: 0xFFFF7043),
];

/// Cari menu berdasarkan id (null jika tidak ada).
MenuItem? menuById(String id) {
  for (final m in kMenu) {
    if (m.id == id) return m;
  }
  return null;
}
