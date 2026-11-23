/// Controller pusat game (Riverpod StateNotifier).
///
/// Mengorkestrasi seluruh simulasi: waktu & cuaca, spawn pelanggan, alur
/// transaksi, memasak, kesegaran, karyawan, upgrade, reputasi, XP/level,
/// laporan harian, dan autosave.
///
/// Logika murni ada di service (EconomyService, StaffService, ProgressService);
/// controller hanya menyambungkan semuanya ke [GameState].
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';
import '../core/audio_service.dart';
import '../data/models/customer_type.dart';
import '../data/models/employee.dart';
import '../data/models/game_state.dart';
import '../data/models/ingredient.dart';
import '../data/models/menu_item.dart';
import '../data/models/upgrade.dart';
import '../data/repositories/save_repository.dart';
import 'ekonomi/economy_service.dart';
import 'karyawan/staff_service.dart';
import 'progres/progress_service.dart';

/// Provider repository save (di-override di main dengan instance ber-Hive).
final saveRepositoryProvider = Provider<SaveRepository>((ref) => SaveRepository());

/// Provider controller game utama.
final gameControllerProvider = StateNotifierProvider<GameController, GameState>(
  (ref) => GameController(saveRepository: ref.watch(saveRepositoryProvider)),
);

class GameController extends StateNotifier<GameState> {
  GameController({
    required this.saveRepository,
    EconomyService economy = const EconomyService(),
    StaffService staff = const StaffService(),
    ProgressService progress = const ProgressService(),
    Random? random,
    bool autosaveAktif = true,
  })  : _autosaveAktif = autosaveAktif,
        _economy = economy,
        _staff = staff,
        _progress = progress,
        _random = random ?? Random(),
        super(GameState.newGame()) {
    if (_autosaveAktif) _jadwalkanAutosave();
  }

  /// Autosave baru aktif setelah pemain memilih Game Baru / Lanjutkan.
  /// Mencegah save lama tertimpa state default hanya karena app dibuka.
  bool _sesiAktif = false;

  /// Autosave dimatikan pada unit test agar tidak ada timer menggantung.
  final bool _autosaveAktif;

  final SaveRepository saveRepository;
  final EconomyService _economy;
  final StaffService _staff;
  final ProgressService _progress;
  final Random _random;

  /// Laporan harian terbaru — UI menampilkan dialog saat berubah.
  final ValueNotifier<DailyReport?> laporanBaru = ValueNotifier<DailyReport?>(null);

  /// Notifikasi ringan (toast) untuk umpan balik aksi pemain.
  final ValueNotifier<String?> pesanToast = ValueNotifier<String?>(null);

  Timer? _autosaveTimer;
  double _akumulasiNotifikasi = 0;

  /// Batas waktu nyata maksimum satu langkah simulasi (detik) — mencegah
  /// lompatan waktu besar setelah aplikasi resume dari background.
  static const double _dtMaks = 0.1;

  EconomyService get economy => _economy;
  StaffService get staffService => _staff;

  /// Akses state dari luar (widget/Flame) tanpa melanggar `state` protected.
  GameState get stateSaatIni => state;

  // ---------------------------------------------------------------------
  // Alur utama
  // ---------------------------------------------------------------------

  /// Mulai game baru.
  void mulaiBaru() {
    state = GameState.newGame();
    state.settings.paused = false;
    laporanBaru.value = null;
    _sesiAktif = true;
    _waktuPeringatanBahan = 0;
    _waktuPeringatanEtalase = 0;
    _isiWarungAwal();
    _emit();
  }

  /// Saat warung dibuka, langsung ada beberapa pelanggan agar tidak terasa
  /// kosong. Mereka adalah pengunjung pagi biasa, bukan "bonus".
  void _isiWarungAwal() {
    final jumlah = 2 + _random.nextInt(2); // 2-3 orang
    for (var i = 0; i < jumlah; i++) {
      _datangkanPelanggan();
    }
    _resetJedaKedatangan();
  }

  /// Timer sejak pelanggan terakhir datang (menit game).
  double _jedaKedatangan = 0;

  void _resetJedaKedatangan() => _jedaKedatangan = 0;

  /// Muat state dari save (Continue).
  void muat(GameState tersimpan) {
    state = tersimpan;
    state.settings.paused = true; // pemain menekan Play setelah masuk.
    laporanBaru.value = null;
    _sesiAktif = true;
    if (state.customers.isEmpty) _isiWarungAwal();
    _emit();
  }

  /// Langkah simulasi dari game loop Flame. [dt] dalam detik nyata.
  void tick(double dt) {
    if (!mounted) return;
    if (state.settings.paused) return;
    final delta = dt.clamp(0.0, _dtMaks);
    final menit = delta * kMenitPerDetik * state.settings.speed;

    _majukanWaktu(menit);
    if (!mounted) return;

    // Proses simulasi per langkah.
    _updatePelanggan(menit);
    _economy.prosesMasak(state, menit);
    _autoMasakKaryawan(menit);
    _isiDaruratEtalase();
    _peringatanEtalase(menit);
    _prosesKesegaran(menit);

    // Notifikasi UI dibatasi 4x/detik agar widget tidak rebuild tiap frame.
    _akumulasiNotifikasi += delta;
    if (_akumulasiNotifikasi >= 0.25) {
      _akumulasiNotifikasi = 0;
      _emit();
    }
  }

  /// Paksa emit (dipakai setelah aksi pemain).
  void _emit() {
    if (!mounted) return;
    state = state.clone();
  }

  /// Simpan state ke Hive. Tidak menulis apa pun sebelum sesi dimulai.
  Future<void> simpanSekarang() async {
    if (!_sesiAktif) return;
    await saveRepository.save(state);
  }

  // ---------------------------------------------------------------------
  // Waktu, cuaca, hari
  // ---------------------------------------------------------------------

  /// Akumulator pecahan menit agar waktu tetap akurat di frame rate berapa pun.
  double _sisaMenit = 0;

  void _majukanWaktu(double menit) {
    _sisaMenit += menit;
    final utuh = _sisaMenit.floor();
    if (utuh <= 0) return;
    _sisaMenit -= utuh;
    state.minuteOfDay = (state.minuteOfDay + utuh).clamp(0, 24 * 60);
    if (state.minuteOfDay >= kJamTutup) {
      _tutupHari();
    }
  }

  /// Dipanggil saat jam tutup tercapai: catat laporan, bayar biaya, ganti hari.
  void _tutupHari() {
    // Pelanggan yang masih ada pulang (tidak dihitung hilang).
    state.customers.clear();

    // Biaya tetap & gaji dibebankan saat menutup buku.
    _economy.bayarBiayaHarian(state);
    state.reports.add(DailyReport(
      day: state.day,
      income: state.dailyIncome,
      expense: state.dailyExpense,
      served: state.dailyServed,
      lost: state.dailyLost,
      spoiled: state.dailySpoiled,
    ));
    laporanBaru.value = state.reports.last;

    // Hari baru.
    state.day += 1;
    state.minuteOfDay = kJamBuka;
    state.weather = _cuacaBaru();
    state.dailyIncome = 0;
    state.dailyExpense = 0;
    state.dailyServed = 0;
    state.dailyLost = 0;
    state.dailySpoiled = 0;
    _economy.prosesBahanKedaluwarsa(state);
    _isiWarungAwal(); // pembeli pagi sudah menunggu saat warung buka
    unawaited(simpanSekarang());
    _emit();
  }

  Weather _cuacaBaru() {
    final roll = _random.nextDouble();
    if (roll < 0.58) return Weather.cerah;
    if (roll < 0.82) return Weather.mendung;
    return Weather.hujan;
  }

  // ---------------------------------------------------------------------
  // Pelanggan
  // ---------------------------------------------------------------------

  /// Faktor keramaian berdasarkan jam & cuaca.
  double get _faktorJam {
    final t = state.minuteOfDay;
    double f = 1.0;
    if (t >= kMulaiSiang && t <= kSelesaiSiang) f *= kFaktorRamaiSiang;
    if (t >= kMulaiMalam && t <= kSelesaiMalam) f *= kFaktorRamaiMalam;
    if (t < 8 * 60) f *= 0.6; // pagi sepi
    if (t > 21 * 60) f *= 0.4; // hampir tutup
    f *= state.weather.spawnFactor;
    f *= 1 + (state.reputation - 3) * 0.15;
    if (state.branchCount > 1) f *= 1.35;
    return f.clamp(0.1, 5.0);
  }

  void _updatePelanggan(double menit) {
    // 1) Spawn pelanggan baru.
    _jedaKedatangan += menit;
    final peluang = kPeluangDatangPerMenit * menit * _faktorJam;
    final sudahCukupLama = _jedaKedatangan >= kJedaMaksKedatangan / _faktorJam;
    final adaRuang = state.customers.length < kBatasPelangganAktif;
    if (adaRuang && (_random.nextDouble() < peluang || sudahCukupLama)) {
      // Saat jam sepi tetap ada tamu sesekali, tapi tidak berdesakan.
      _datangkanPelanggan();
      _resetJedaKedatangan();
      // Peluang tambahan saat ramai (mis. jam makan siang berbonus 1 tamu).
      if (_faktorJam > 1.8 && _random.nextDouble() < 0.45) {
        _datangkanPelanggan();
      }
    }

    // 2) Majukan tiap pelanggan.
    final pulang = <CustomerSim>[];
    // Iterasi salinan: _updateAntre bisa mengeluarkan pelanggan dari daftar.
    for (final c in List<CustomerSim>.of(state.customers)) {
      switch (c.stage) {
        case CustomerStage.datang:
          // Berjalan menuju antrean.
          c.waitedMinutes += menit;
          if (c.waitedMinutes >= kMenitDatang) {
            c.stage = CustomerStage.antre;
            _susunAntrean();
          }
          break;
        case CustomerStage.antre:
          _updateAntre(c, menit);
          break;
        case CustomerStage.pesan:
          c.serviceTimer -= menit;
          if (c.serviceTimer <= 0) {
            _prosesPesanan(c);
          }
          break;
        case CustomerStage.makan:
          c.eatTimer -= menit * (1 + state.pelayanSkill * 0.08);
          if (c.eatTimer <= 0) {
            c.stage = CustomerStage.pulang;
            c.waitedMinutes = 0;
          }
          break;
        case CustomerStage.pulang:
          c.waitedMinutes += menit;
          if (c.waitedMinutes >= kMenitPulang) pulang.add(c);
          break;
      }
    }
    for (final c in pulang) {
      state.customers.remove(c);
    }
    _susunAntrean();
  }

  void _datangkanPelanggan() {
    final type = _pilihTipePelanggan();
    final profil = kCustomerProfiles[type]!;
    final budget = profil.budgetMin +
        _random.nextInt((profil.budgetMax - profil.budgetMin).clamp(1, 100000));
    state.customers.add(CustomerSim(
      id: state.nextCustomerId++,
      type: type,
      patience: profil.patienceMinutes * (0.85 + _random.nextDouble() * 0.3),
      budget: budget,
    ));
  }

  CustomerType _pilihTipePelanggan() {
    final total = kCustomerWeights.values.fold<int>(0, (a, b) => a + b);
    var roll = _random.nextInt(total);
    for (final entry in kCustomerWeights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return CustomerType.anakKos;
  }

  /// Pelanggan di tahap antre berkurang kesabarannya; yang paling depan
  /// mulai dilayani jika kasir siap.
  void _updateAntre(CustomerSim c, double menit) {
    c.patience -= menit;
    c.waitedMinutes += menit;

    if (c.patience <= 0) {
      // Kabur karena terlalu lama menunggu.
      state.dailyLost += 1;
      state.totalLost += 1;
      state.reputation = (state.reputation - 0.03).clamp(1.0, 5.0);
      _toast('${c.type.label} pergi karena menunggu terlalu lama.');
      state.customers.remove(c);
      _susunAntrean();
      return;
    }
    if (c.queueIndex == 0 && c.stage == CustomerStage.antre) {
      final sedangDilayani = state.customers.any(
        (o) => o.stage == CustomerStage.pesan && o.seatIndex == -2,
      );
      if (!sedangDilayani) {
        c.stage = CustomerStage.pesan;
        c.serviceTimer = state.serviceMinutes;
        c.seatIndex = -2; // tanda sedang di kasir
        c.waitedMinutes = 0;
      }
    }
  }

  void _susunAntrean() {
    final antre = state.customers.where((c) => c.stage == CustomerStage.antre).toList();
    for (var i = 0; i < antre.length; i++) {
      antre[i].queueIndex = i;
    }
  }

  /// Pelanggan memilih menu (saat mulai dilayani) lalu membayar.
  void _pilihPesanan(CustomerSim c) {
    final kandidat = _kandidatMenu(c);
    if (kandidat.isEmpty) return;

    var sisaBudget = c.budget;
    final dipilih = <String, int>{};

    // Ambil sampai 3 item: utama lalu pelengkap/minuman bila budget cukup.
    for (var i = 0; i < 3; i++) {
      final opsi = _kandidatMenu(c)
          .where((m) => (state.priceOf(m.id) <= sisaBudget) && !dipilih.containsKey(m.id))
          .toList();
      if (opsi.isEmpty) break;
      // Bobot acak berdasarkan skor.
      final totalSkor = opsi.fold<double>(0, (a, m) => a + _skorMenu(m, c));
      var roll = _random.nextDouble() * totalSkor;
      MenuItem? pilih;
      for (final m in opsi) {
        roll -= _skorMenu(m, c);
        if (roll <= 0) {
          pilih = m;
          break;
        }
      }
      pilih ??= opsi.first;
      dipilih[pilih.id] = 1;
      sisaBudget -= state.priceOf(pilih.id);
      if (_random.nextDouble() < 0.25) break; // cukup, tidak menambah lagi
    }

    if (dipilih.isEmpty) return;
    for (final entry in dipilih.entries) {
      c.order[entry.key] = entry.value;
      c.totalBayar += state.priceOf(entry.key) * entry.value;
    }
  }

  /// Menu yang layak dipilih: terbuka, ada stok segar di etalase.
  List<MenuItem> _kandidatMenu(CustomerSim c) {
    final hasil = <MenuItem>[];
    for (final m in kMenu) {
      if (state.level < m.unlockLevel) continue;
      final tersedia = state.dishBatches.any((b) => b.menuId == m.id && b.qty > 0 && b.freshness > 0);
      if (!tersedia) continue;
      if (state.priceOf(m.id) > c.budget * 1.2) continue; // terlalu mahal
      hasil.add(m);
    }
    return hasil;
  }

  /// Skor preferensi pelanggan terhadap menu (harga, selera, cuaca, kesegaran).
  double _skorMenu(MenuItem m, CustomerSim c) {
    final profil = kCustomerProfiles[c.type]!;
    double skor = 1.0;

    final idx = profil.favoriteCategories.indexOf(m.category);
    if (idx >= 0) skor *= 1.8 - idx * 0.25;

    // Harga relatif: makin mahal makin tidak diminati (demand elastis).
    final rasio = state.priceOf(m.id) / m.basePrice;
    skor *= pow(rasio, -2.2).toDouble();

    // Cuaca hujan -> minuman panas lebih laku.
    if (m.hotDrink && state.weather == Weather.hujan) skor *= 2.4;
    if (m.hotDrink && state.weather == Weather.cerah) skor *= 0.8;

    // Rata-rata kesegaran menu tersebut.
    final batches = state.dishBatches.where((b) => b.menuId == m.id && b.qty > 0);
    if (batches.isNotEmpty) {
      final avg = batches.fold<double>(0, (a, b) => a + b.freshness) / batches.length;
      skor *= 0.4 + avg / 100;
    }
    return max(skor, 0.0001);
  }

  /// Setelah waktu transaksi habis: ambil masakan, hitung kepuasan, bayar.
  void _prosesPesanan(CustomerSim c) {
    _pilihPesanan(c);

    if (c.order.isEmpty || c.totalBayar > c.budget) {
      // Tidak ada menu yang cocok/terjangkau -> pulang tanpa membeli.
      state.dailyLost += 1;
      state.totalLost += 1;
      state.reputation = (state.reputation - 0.01).clamp(1.0, 5.0);
      _toast('${c.type.label} tidak jadi membeli (menu terlalu mahal).');
      state.customers.remove(c);
      _susunAntrean();
      return;
    }

    // Cek stok aktual; jika kurang, kurangi pesanan.
    final kesegaran = <double>[];
    final jadi = <String, int>{};
    for (final entry in c.order.entries) {
      final diambil = _economy.ambilPorsi(state, entry.key, entry.value);
      if (diambil.length == entry.value) {
        jadi[entry.key] = entry.value;
        kesegaran.addAll(diambil);
      }
    }
    if (jadi.isEmpty) {
      state.dailyLost += 1;
      state.totalLost += 1;
      state.reputation = (state.reputation - 0.01).clamp(1.0, 5.0);
      _toast('${c.type.label} pulang karena pesanan habis.');
      state.customers.remove(c);
      _susunAntrean();
      return;
    }

    var total = 0;
    jadi.forEach((id, qty) => total += state.priceOf(id) * qty);
    c.order
      ..clear()
      ..addAll(jadi);
    c.totalBayar = total;
    _economy.catatPenjualan(state, total);
    AudioSvc.instance.koin();

    // Kepuasan: kesegaran, harga, kenyamanan, lama menunggu.
    c.satisfaction = _hitungKepuasan(c, kesegaran);

    // Tempat duduk; jika penuh, pelanggan makan berdiri (kepuasan turun).
    final kursi = _kursiKosong();
    c.seatIndex = kursi;
    if (kursi == -1) {
      c.satisfaction = (c.satisfaction - 0.6).clamp(1.0, 5.0);
    }
    c.eatTimer = state.eatMinutes * (0.85 + _random.nextDouble() * 0.3);
    c.stage = CustomerStage.makan;
    c.waitedMinutes = 0;
    _susunAntrean();
    _terapkanKonsekuensi(c, total);
  }

  /// Terapkan efek tambahan setelah transaksi sukses: reputasi, XP, karyawan.
  void _terapkanKonsekuensi(CustomerSim c, int total) {
    // total sudah dicatat di kas; parameter dipertahankan untuk kejelasan.
    state.reputation = (state.reputation + (c.satisfaction - state.reputation) * 0.04)
        .clamp(1.0, 5.0);
    state.dailyServed += 1;
    state.totalServed += 1;
    _progress.tambahXp(state, 6 + (c.satisfaction * 4).round());
    _akumulasiKaryawan();
  }

  double _hitungKepuasan(CustomerSim c, List<double> kesegaran) {
    final fresh = kesegaran.isEmpty
        ? 50.0
        : kesegaran.fold<double>(0, (a, b) => a + b) / kesegaran.length;

    // Rasio harga rata-rata terhadap harga dasar (1.0 = wajar).
    double rasio = 1.0;
    if (c.order.isNotEmpty) {
      var harga = 0.0;
      var dasar = 0.0;
      c.order.forEach((id, qty) {
        harga += state.priceOf(id) * qty;
        dasar += (menuById(id)?.basePrice ?? 1) * qty;
      });
      rasio = dasar > 0 ? harga / dasar : 1.0;
    }

    final kenyamanan = state.upgradeLevel('ac') * 0.15 +
        state.upgradeLevel('dekorasi') * 0.08 +
        state.pelayanSkill * 0.05;
    final telat = (c.patience <= 0) ? 1.0 : (1 - c.patience / 30).clamp(0.0, 1.0);

    final nilai = 1.2 +
        (fresh / 100) * 2.2 +
        (1.6 - rasio * 1.2).clamp(-0.8, 0.8) +
        kenyamanan -
        telat * 0.5;

    return nilai.clamp(1.0, 5.0);
  }

  int _kursiKosong() {
    final terpakai = state.customers
        .where((c) => c.stage == CustomerStage.makan && c.seatIndex >= 0)
        .map((c) => c.seatIndex)
        .toSet();
    for (var i = 0; i < state.seatCount; i++) {
      if (!terpakai.contains(i)) return i;
    }
    return -1;
  }

  /// Juru masak otomatis: mengisi etalase saat stok menipis.
  void _autoMasakKaryawan(double menit) {
    final adaJuruMasak = state.employees.any((e) => e.role == EmployeeRole.juruMasak);
    if (!adaJuruMasak) return;
    _autoCooldown -= menit;
    if (_autoCooldown > 0) return;
    _autoCooldown = 25; // tiap 25 menit game

    if (state.cookingQueue.length >= 2) return;
    if (state.dishCount > state.displayCapacity - 3) return;

    // Pilih menu terbuka yang stoknya paling sedikit tapi bahan tersedia.
    MenuItem? target;
    var stokTerendah = 999;
    for (final m in kMenu) {
      if (state.level < m.unlockLevel) continue;
      if (state.dishBatches.any((b) => b.menuId == m.id)) continue;
      final cukup = m.recipe.entries.every(
        (e) => state.stockOf(e.key) >= e.value * 2,
      );
      if (!cukup) continue;
      if (m.unlockLevel < stokTerendah) {
        target = m;
        stokTerendah = m.unlockLevel;
      }
    }
    if (target != null) _economy.mulaiMasak(state, target.id, 2);
  }

  double _autoCooldown = 0;

  /// Saat etalase hampir kosong dan bahan tersedia, pemilik warung (pemain)
  /// otomatis memasak 2 porsi menu termurah yang bahannya ada. Ini menjaga
  /// pelanggan tetap terlayani tanpa harus membuka panel terus-menerus.
  void _isiDaruratEtalase() {
    if (state.cookingQueue.isNotEmpty) return;
    final porsiKritis = state.dishCount <= 2;
    if (!porsiKritis) return;

    MenuItem? pilihan;
    var hargaTermurah = 1 << 30;
    for (final m in kMenu) {
      if (state.level < m.unlockLevel) continue;
      final cukup = m.recipe.entries.every(
        (e) => state.stockOf(e.key) >= e.value * 2,
      );
      if (!cukup) continue;
      if (state.priceOf(m.id) < hargaTermurah) {
        hargaTermurah = state.priceOf(m.id);
        pilihan = m;
      }
    }
    if (pilihan != null) {
      _economy.mulaiMasak(state, pilihan.id, 2);
    } else if (state.dishBatches.isEmpty) {
      // Bahan habis total: beri tahu pemain, sekali saja per beberapa menit.
      if (_waktuPeringatanBahan <= 0) {
        _waktuPeringatanBahan = 120; // menit game
        _toast('⚠️ Bahan habis! Belanja di panel Stok agar bisa memasak.');
      }
    }
  }

  double _waktuPeringatanBahan = 0;

  /// Pengingat ketika etalase mulai kosong.
  double _waktuPeringatanEtalase = 0;
  void _peringatanEtalase(double menit) {
    if (_waktuPeringatanBahan > 0) _waktuPeringatanBahan -= menit;
    if (state.dishCount > 4) {
      _waktuPeringatanEtalase = 0;
      return;
    }
    if (_waktuPeringatanEtalase > 0) {
      _waktuPeringatanEtalase -= menit;
      return;
    }
    _waktuPeringatanEtalase = 90; // beri tahu tiap 90 menit game
    _toast('Etalase hampir kosong — masak menu lewat panel Menu & Harga.');
  }

  /// Karyawan mendapat XP saat warung melayani pelanggan.
  void _akumulasiKaryawan() {
    for (final e in state.employees) {
      e.xp += 3;
      final butuh = 100 * e.skill;
      if (e.xp >= butuh && e.skill < 5) {
        e.xp -= butuh;
        e.skill += 1;
        _toast('${e.name} naik skill menjadi ${e.skill}!');
      }
    }
  }

  // ---------------------------------------------------------------------
  // Kesegaran
  // ---------------------------------------------------------------------

  double _akumulasiJamKesegaran = 0;
  void _prosesKesegaran(double menit) {
    _akumulasiJamKesegaran += menit;
    if (_akumulasiJamKesegaran < 10) return; // proses tiap 10 menit game
    final jam = _akumulasiJamKesegaran / 60;
    _akumulasiJamKesegaran = 0;
    final dibuang = _economy.prosesKesegaran(state, jam);
    if (dibuang > 0) {
      _toast('$dibuang porsi basi dibuang.');
    }
  }

  // ---------------------------------------------------------------------
  // Aksi pemain: belanja, masak, harga
  // ---------------------------------------------------------------------

  bool beliBahan(String ingredientId, int qty) {
    final ok = _economy.beliBahan(state, ingredientId, qty);
    ok ? AudioSvc.instance.beli() : AudioSvc.instance.salah();
    _toast(ok ? 'Bahan berhasil dibeli.' : 'Uang tidak cukup untuk belanja ini.');
    _emit();
    return ok;
  }

  bool masak(String menuId, int porsi) {
    final cek = _economy.cekMemasak(state, menuId, porsi);
    if (!cek.bisa) {
      AudioSvc.instance.salah();
      _toast(cek.alasan);
      return false;
    }
    final ok = _economy.mulaiMasak(state, menuId, porsi);
    if (ok) AudioSvc.instance.masak();
    _toast(ok ? 'Mulai memasak $porsi porsi.' : 'Gagal memasak.');
    _emit();
    return ok;
  }

  void ubahHarga(String menuId, int harga) {
    final menu = menuById(menuId);
    if (menu == null) return;
    final minimal = (menu.basePrice * 0.4).round();
    final maksimal = (menu.basePrice * 2.5).round();
    state.menuPrices[menuId] = harga.clamp(minimal, maksimal);
    _emit();
  }

  // ---------------------------------------------------------------------
  // Karyawan
  // ---------------------------------------------------------------------

  bool rekrut(EmployeeRole role) {
    final hasil = _staff.rekrut(state, role, _random);
    if (hasil == null) {
      _toast('Tidak bisa merekrut: periksa modal & batas karyawan.');
      return false;
    }
    AudioSvc.instance.beli();
    _toast('${hasil.name} bergabung sebagai ${role.label}.');
    _emit();
    return true;
  }

  void pecat(Employee employee) {
    final pesangon = _staff.pecat(state, employee);
    _toast('${employee.name} dipecat. Pesangon ${_formatRupiah(pesangon)}.');
    _emit();
  }

  // ---------------------------------------------------------------------
  // Upgrade
  // ---------------------------------------------------------------------

  bool beliUpgrade(String upgradeId) {
    final def = upgradeById(upgradeId);
    if (def == null) return false;
    final levelSekarang = state.upgradeLevel(upgradeId);
    if (levelSekarang >= def.maxLevel) {
      _toast('${def.name} sudah di level maksimum.');
      return false;
    }
    if (state.level < def.requiredLevel) {
      _toast('${def.name} terbuka di level ${def.requiredLevel}.');
      return false;
    }
    final biaya = biayaUpgrade(def.baseCost, def.costGrowth, levelSekarang);
    if (state.money < biaya) {
      _toast('Uang tidak cukup untuk ${def.name}.');
      return false;
    }
    state.money -= biaya;
    state.dailyExpense += biaya;
    state.upgrades[upgradeId] = levelSekarang + 1;
    if (upgradeId == 'cabang') state.branchCount = 2;
    AudioSvc.instance.beli();
    _toast('${def.name} berhasil diupgrade!');
    _emit();
    return true;
  }

  // ---------------------------------------------------------------------
  // Pengaturan & tambahan
  // ---------------------------------------------------------------------

  void setKecepatan(int speed) {
    state.settings.speed = speed.clamp(1, 3);
    _emit();
  }

  void togglePause() {
    state.settings.paused = !state.settings.paused;
    _emit();
  }

  void setPause(bool value) {
    if (state.settings.paused == value) return;
    state.settings.paused = value;
    _emit();
  }

  void toggleSuara() {
    state.settings.soundOn = !state.settings.soundOn;
    AudioSvc.instance.aktif = state.settings.soundOn;
    if (state.settings.soundOn) {
      unawaited(AudioSvc.instance.lanjutkanMusik());
    } else {
      unawaited(AudioSvc.instance.hentikanMusik());
    }
    _emit();
  }

  /// Tutup warung lebih awal (pemain memilih "Tutup Warung").
  void tutupWarung() {
    state.minuteOfDay = kJamTutup;
    _tutupHari();
  }

  void _toast(String pesan) {
    pesanToast.value = pesan;
  }

  String _formatRupiah(int nilai) {
    final digits = nilai.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp$buffer';
  }

  // ---------------------------------------------------------------------
  // Autosave
  // ---------------------------------------------------------------------

  void _jadwalkanAutosave() {
    if (!_autosaveAktif) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(
      const Duration(seconds: kIntervalAutosaveDetik),
      (_) {
        // Autosave berkala hanya selama sesi berjalan.
        unawaited(simpanSekarang());
      },
    );
  }

  /// Dipakai saat aplikasi masuk background / ditutup.
  Future<void> simpanDanPause() async {
    state.settings.paused = true;
    _emit();
    await simpanSekarang();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    laporanBaru.dispose();
    pesanToast.dispose();
    super.dispose();
  }

  /// Ekspos daftar bahan yang bisa dibeli (untuk UI stok).
  List<Ingredient> get daftarBahanBelanja => daftarBahan;
}
