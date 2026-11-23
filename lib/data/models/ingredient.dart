/// Model bahan mentah yang dibeli di pasar dan dipakai untuk memasak.
///
/// Stok disimpan sebagai [IngredientBatch] (dengan tanggal kedaluwarsa)
/// di dalam [GameState]. Harga [buyPrice] adalah harga per 1 porsi bahan.
library;

class Ingredient {
  final String id;
  final String name;

  /// Harga beli per porsi (Rupiah).
  final int buyPrice;

  /// Masa simpan dalam hari (setelah dibeli).
  final int shelfLifeDays;

  /// Satuan label untuk UI, mis. "porsi", "kg", "liter".
  final String unit;

  const Ingredient({
    required this.id,
    required this.name,
    required this.buyPrice,
    required this.shelfLifeDays,
    this.unit = 'porsi',
  });
}

/// Database bahan. Tambah bahan baru cukup tambahkan entri di sini.
const Map<String, Ingredient> kIngredients = {
  'beras': Ingredient(id: 'beras', name: 'Beras', buyPrice: 4000, shelfLifeDays: 30, unit: 'kg'),
  'tempe': Ingredient(id: 'tempe', name: 'Tempe', buyPrice: 3000, shelfLifeDays: 4),
  'tahu': Ingredient(id: 'tahu', name: 'Tahu', buyPrice: 2500, shelfLifeDays: 3),
  'telur': Ingredient(id: 'telur', name: 'Telur', buyPrice: 2000, shelfLifeDays: 7),
  'ayam': Ingredient(id: 'ayam', name: 'Ayam', buyPrice: 8000, shelfLifeDays: 3),
  'lele': Ingredient(id: 'lele', name: 'Ikan Lele', buyPrice: 6000, shelfLifeDays: 2),
  'daging': Ingredient(id: 'daging', name: 'Daging Sapi', buyPrice: 15000, shelfLifeDays: 3),
  'kangkung': Ingredient(id: 'kangkung', name: 'Kangkung', buyPrice: 2000, shelfLifeDays: 2),
  'sayur_campuran': Ingredient(id: 'sayur_campuran', name: 'Sayur Campuran', buyPrice: 2500, shelfLifeDays: 3),
  'jagung': Ingredient(id: 'jagung', name: 'Jagung', buyPrice: 1500, shelfLifeDays: 5),
  'cabai': Ingredient(id: 'cabai', name: 'Cabai', buyPrice: 1000, shelfLifeDays: 5),
  'bawang': Ingredient(id: 'bawang', name: 'Bawang', buyPrice: 1000, shelfLifeDays: 10),
  'minyak': Ingredient(id: 'minyak', name: 'Minyak Goreng', buyPrice: 500, shelfLifeDays: 30, unit: 'liter'),
  'gula': Ingredient(id: 'gula', name: 'Gula', buyPrice: 500, shelfLifeDays: 30),
  'teh': Ingredient(id: 'teh', name: 'Teh', buyPrice: 800, shelfLifeDays: 30),
  'kopi': Ingredient(id: 'kopi', name: 'Kopi', buyPrice: 1500, shelfLifeDays: 30),
  'jeruk': Ingredient(id: 'jeruk', name: 'Jeruk', buyPrice: 1200, shelfLifeDays: 4),
  'mie': Ingredient(id: 'mie', name: 'Mie', buyPrice: 2500, shelfLifeDays: 10),
  'tepung': Ingredient(id: 'tepung', name: 'Tepung', buyPrice: 800, shelfLifeDays: 30),
  'santan': Ingredient(id: 'santan', name: 'Santan', buyPrice: 2000, shelfLifeDays: 2),
};

/// Daftar bahan dalam urutan tetap untuk UI.
List<Ingredient> get daftarBahan => kIngredients.values.toList();
