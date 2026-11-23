/// Konstanta balancing & konfigurasi global game.
///
/// Semua angka "tuning" dikumpulkan di sini agar mudah diubah tanpa
/// menyentuh logika (lihat README.md bagian Asumsi & Balancing).
library;

/// Modal awal pemain.
const int kModalAwal = 2000000;

/// Jam buka & tutup (dalam menit sejak 00:00).
const int kJamBuka = 6 * 60; // 06:00
const int kJamTutup = 22 * 60; // 22:00

/// Kecepatan waktu: 1 detik nyata = [kMenitPerDetik] menit game (pada 1x).
///
/// 3 menit/detik => satu hari penuh (06.00-22.00) ≈ 5 menit 20 detik.
const double kMenitPerDetik = 3.0;

/// Pilihan kecepatan waktu yang tersedia di HUD.
const List<int> kPilihanKecepatan = [1, 2, 3];

/// Biaya tetap harian.
const int kSewaPerHari = 50000;
const int kListrikPerHari = 15000;
const int kListrikPerLevelAc = 8000;
const int kSewaCabangPerHari = 30000;

/// Jam makan siang (paling ramai).
const int kMulaiSiang = 11 * 60;
const int kSelesaiSiang = 13 * 60;
const double kFaktorRamaiSiang = 2.2;

/// Jam makan malam (sedikit ramai).
const int kMulaiMalam = 18 * 60;
const int kSelesaiMalam = 20 * 60;
const double kFaktorRamaiMalam = 1.4;

/// Peluang dasar satu pelanggan datang per menit game (sebelum pengali).
const double kPeluangDatangPerMenit = 0.025;

/// Batas pelanggan aktif di warung (antre + makan).
const int kBatasPelangganAktif = 14;

/// Jarak waktu (menit game) antar tahap transisi pelanggan.
const double kMenitDatang = 2.5;
const double kMenitPesan = 1.5;
const double kMenitPulang = 2.5;

/// Laju kesegaran makanan: dari 100 ke 0 dalam sekian jam game.
const double kDecayKesegaranPerJam = 20.0;

/// Pengurangan decay per level kulkas / etalase (fraksi).
const double kBonusKulkas = 0.08;
const double kBonusEtalase = 0.10;

/// Batas karyawan maksimal (tanpa cabang).
const int kMaksKaryawan = 6;
const int kMaksKaryawanCabang = 9;

/// Interval autosave (detik nyata).
const int kIntervalAutosaveDetik = 30;

/// XP yang dibutuhkan untuk naik dari level [level] ke level berikutnya.
int xpUntukNaikLevel(int level) => 60 * level * level;

/// Biaya upgrade pada level tertentu.
int biayaUpgrade(int baseCost, double growth, int levelSaatIni) {
  double cost = baseCost.toDouble();
  for (int i = 0; i < levelSaatIni; i++) {
    cost *= growth;
  }
  return cost.round();
}

/// Batas level maksimum pemain.
const int kLevelMaks = 10;

/// Rentang kesegaran yang masih layak dijual tanpa penalti besar.
const double kKesegaranMinimal = 15;
