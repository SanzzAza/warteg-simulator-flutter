/// Definisi upgrade warung & ekspansi.
library;

class UpgradeDef {
  final String id;
  final String name;
  final String desc;

  /// Level maksimum (0 = belum dibeli).
  final int maxLevel;

  /// Biaya level pertama.
  final int baseCost;

  /// Pengali biaya antar level.
  final double costGrowth;

  /// Level pemain minimum untuk membeli.
  final int requiredLevel;

  const UpgradeDef({
    required this.id,
    required this.name,
    required this.desc,
    required this.maxLevel,
    required this.baseCost,
    required this.costGrowth,
    required this.requiredLevel,
  });
}

const List<UpgradeDef> kUpgrades = [
  UpgradeDef(id: 'etalase', name: 'Etalase Kaca', desc: 'Kapasitas pajangan +4/level, makanan lebih awet.', maxLevel: 5, baseCost: 150000, costGrowth: 1.8, requiredLevel: 1),
  UpgradeDef(id: 'kompor', name: 'Kompor Tambahan', desc: 'Kecepatan memasak +25%/level.', maxLevel: 5, baseCost: 120000, costGrowth: 1.8, requiredLevel: 1),
  UpgradeDef(id: 'kulkas', name: 'Kulkas', desc: 'Bahan & makanan lebih awet (decay -8%/level).', maxLevel: 5, baseCost: 150000, costGrowth: 1.8, requiredLevel: 2),
  UpgradeDef(id: 'meja_kursi', name: 'Meja & Kursi', desc: 'Kursi pelanggan +3/level.', maxLevel: 5, baseCost: 100000, costGrowth: 1.7, requiredLevel: 1),
  UpgradeDef(id: 'dekorasi', name: 'Dekorasi', desc: 'Tanaman, lukisan & lampu — reputasi naik lebih cepat.', maxLevel: 5, baseCost: 80000, costGrowth: 1.6, requiredLevel: 2),
  UpgradeDef(id: 'ac', name: 'Kipas / AC', desc: 'Pelanggan lebih nyaman (+kepuasan), listrik naik.', maxLevel: 3, baseCost: 250000, costGrowth: 2.0, requiredLevel: 3),
  UpgradeDef(id: 'cabang', name: 'Cabang Kedua', desc: 'Buka cabang di gang sebelah: +kursi, +pelanggan, +sewa.', maxLevel: 1, baseCost: 5000000, costGrowth: 1.0, requiredLevel: 5),
];

UpgradeDef? upgradeById(String id) {
  for (final u in kUpgrades) {
    if (u.id == id) return u;
  }
  return null;
}
