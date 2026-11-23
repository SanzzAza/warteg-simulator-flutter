/// State game pusat — semua data yang bisa di-serialize untuk save/load.
///
/// Desain: model polos (plain Dart) tanpa dependensi Flutter agar mudah
/// diuji unit test dan disimpan sebagai JSON di Hive.
library;

import '../../core/app_config.dart';
import 'customer_type.dart';
import 'employee.dart';
import 'menu_item.dart';

/// Cuaca hari ini.
enum Weather { cerah, mendung, hujan }

extension WeatherX on Weather {
  String get label {
    switch (this) {
      case Weather.cerah:
        return 'Cerah';
      case Weather.mendung:
        return 'Mendung';
      case Weather.hujan:
        return 'Hujan';
    }
  }

  /// Pengali jumlah pelanggan datang.
  double get spawnFactor {
    switch (this) {
      case Weather.cerah:
        return 1.0;
      case Weather.mendung:
        return 0.85;
      case Weather.hujan:
        return 0.7;
    }
  }
}

/// Tahap pelanggan dalam alur transaksi.
enum CustomerStage { datang, antre, pesan, makan, pulang }

/// Simulasi satu pelanggan (logika), digambar oleh Flame component.
class CustomerSim {
  final int id;
  final CustomerType type;
  CustomerStage stage;

  /// Sisa kesabaran (menit game).
  double patience;

  /// Anggaran belanja (Rupiah).
  int budget;

  /// Kepuasan terakhir 1-5 (untuk indikator emosi).
  double satisfaction;

  /// Menu yang dipesan (id menu -> jumlah).
  final Map<String, int> order;

  /// Total bayar.
  int totalBayar;

  /// Waktu makan tersisa (menit game).
  double eatTimer;

  /// Waktu transaksi tersisa di kasir (menit game).
  double serviceTimer;

  /// Index kursi yang diduduki (-1 = tidak ada).
  int seatIndex;

  /// Posisi dalam antrean (0 = paling depan).
  int queueIndex;

  /// Menit menunggu sejauh ini.
  double waitedMinutes;

  CustomerSim({
    required this.id,
    required this.type,
    this.stage = CustomerStage.datang,
    required this.patience,
    required this.budget,
    this.satisfaction = 3,
    Map<String, int>? order,
    this.totalBayar = 0,
    this.eatTimer = 0,
    this.serviceTimer = 0,
    this.seatIndex = -1,
    this.queueIndex = -1,
    this.waitedMinutes = 0,
  }) : order = order ?? <String, int>{};

  /// Mood untuk indikator emosi: 0=kesal, 1=netral, 2=senang.
  int get mood {
    if (satisfaction >= 4) return 2;
    if (satisfaction <= 2) return 0;
    return 1;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.index,
        'stage': stage.index,
        'patience': patience,
        'budget': budget,
        'satisfaction': satisfaction,
        'order': order,
        'totalBayar': totalBayar,
        'eatTimer': eatTimer,
        'serviceTimer': serviceTimer,
        'seatIndex': seatIndex,
        'queueIndex': queueIndex,
        'waitedMinutes': waitedMinutes,
      };

  factory CustomerSim.fromMap(Map<String, dynamic> map) => CustomerSim(
        id: (map['id'] as num).toInt(),
        type: CustomerType.values[(map['type'] as num).toInt()],
        stage: CustomerStage.values[(map['stage'] as num).toInt()],
        patience: (map['patience'] as num).toDouble(),
        budget: (map['budget'] as num).toInt(),
        satisfaction: (map['satisfaction'] as num).toDouble(),
        order: (map['order'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        totalBayar: (map['totalBayar'] as num).toInt(),
        eatTimer: (map['eatTimer'] as num).toDouble(),
        serviceTimer: (map['serviceTimer'] as num).toDouble(),
        seatIndex: (map['seatIndex'] as num).toInt(),
        queueIndex: (map['queueIndex'] as num).toInt(),
        waitedMinutes: (map['waitedMinutes'] as num).toDouble(),
      );
}

/// Batch bahan mentah dengan tanggal kedaluwarsa.
class IngredientBatch {
  final String ingredientId;
  int qty;

  /// Hari terakhir bisa dipakai (hari game).
  final int expiryDay;

  IngredientBatch({required this.ingredientId, required this.qty, required this.expiryDay});

  Map<String, dynamic> toMap() => {'ingredientId': ingredientId, 'qty': qty, 'expiryDay': expiryDay};

  factory IngredientBatch.fromMap(Map<String, dynamic> map) => IngredientBatch(
        ingredientId: map['ingredientId'] as String,
        qty: (map['qty'] as num).toInt(),
        expiryDay: (map['expiryDay'] as num).toInt(),
      );
}

/// Batch masakan di etalase dengan tingkat kesegaran 0-100.
class DishBatch {
  final String menuId;
  int qty;

  /// 100 = baru dimasak, 0 = basi.
  double freshness;

  DishBatch({required this.menuId, required this.qty, this.freshness = 100});

  Map<String, dynamic> toMap() => {'menuId': menuId, 'qty': qty, 'freshness': freshness};

  factory DishBatch.fromMap(Map<String, dynamic> map) => DishBatch(
        menuId: map['menuId'] as String,
        qty: (map['qty'] as num).toInt(),
        freshness: (map['freshness'] as num).toDouble(),
      );
}

/// Antrean memasak: satu job diproses dalam satu waktu.
class CookingJob {
  final String menuId;
  final int portions;

  /// Progress dalam menit game.
  double progress;

  /// Total menit yang dibutuhkan.
  final double totalMinutes;

  CookingJob({required this.menuId, required this.portions, this.progress = 0, required this.totalMinutes});

  Map<String, dynamic> toMap() => {'menuId': menuId, 'portions': portions, 'progress': progress, 'totalMinutes': totalMinutes};

  factory CookingJob.fromMap(Map<String, dynamic> map) => CookingJob(
        menuId: map['menuId'] as String,
        portions: (map['portions'] as num).toInt(),
        progress: (map['progress'] as num).toDouble(),
        totalMinutes: (map['totalMinutes'] as num).toDouble(),
      );
}

/// Laporan keuangan satu hari.
class DailyReport {
  final int day;
  final int income;
  final int expense;
  final int served;
  final int lost;
  final int spoiled;

  DailyReport({required this.day, required this.income, required this.expense, required this.served, required this.lost, required this.spoiled});

  int get profit => income - expense;

  Map<String, dynamic> toMap() => {'day': day, 'income': income, 'expense': expense, 'served': served, 'lost': lost, 'spoiled': spoiled};

  factory DailyReport.fromMap(Map<String, dynamic> map) => DailyReport(
        day: (map['day'] as num).toInt(),
        income: (map['income'] as num).toInt(),
        expense: (map['expense'] as num).toInt(),
        served: (map['served'] as num).toInt(),
        lost: (map['lost'] as num).toInt(),
        spoiled: (map['spoiled'] as num).toInt(),
      );
}

/// Pengaturan pemain.
class GameSettings {
  bool soundOn;
  int speed; // 1, 2, atau 3
  bool paused;

  GameSettings({this.soundOn = true, this.speed = 1, this.paused = false});

  Map<String, dynamic> toMap() => {'soundOn': soundOn, 'speed': speed, 'paused': paused};

  factory GameSettings.fromMap(Map<String, dynamic> map) => GameSettings(
        soundOn: map['soundOn'] as bool? ?? true,
        speed: (map['speed'] as num?)?.toInt() ?? 1,
        paused: map['paused'] as bool? ?? false,
      );
}

/// State utama game. Semua field mutable agar controller bisa mengubahnya
/// dengan cepat; controller memanggil [clone] untuk memicu rebuild Riverpod.
class GameState {
  int money;
  int day;
  int minuteOfDay;
  Weather weather;
  double reputation; // 1.0 - 5.0
  int level;
  int xp; // progres menuju level berikutnya

  List<IngredientBatch> ingredientBatches;
  List<DishBatch> dishBatches;
  List<CookingJob> cookingQueue;
  Map<String, int> menuPrices;
  List<Employee> employees;
  Map<String, int> upgrades; // id upgrade -> level
  int branchCount; // 1 = warteg utama, 2 = +cabang

  List<CustomerSim> customers;
  int nextCustomerId;

  // Akumulasi hari berjalan
  int dailyIncome;
  int dailyExpense;
  int dailyServed;
  int dailyLost;
  int dailySpoiled;

  // Statistik total
  int totalServed;
  int totalLost;
  int totalSpoiled;
  int totalIncome;

  List<DailyReport> reports;
  GameSettings settings;

  GameState({
    required this.money,
    this.day = 1,
    this.minuteOfDay = kJamBuka,
    this.weather = Weather.cerah,
    this.reputation = 3.0,
    this.level = 1,
    this.xp = 0,
    List<IngredientBatch>? ingredientBatches,
    List<DishBatch>? dishBatches,
    List<CookingJob>? cookingQueue,
    Map<String, int>? menuPrices,
    List<Employee>? employees,
    Map<String, int>? upgrades,
    this.branchCount = 1,
    List<CustomerSim>? customers,
    this.nextCustomerId = 1,
    this.dailyIncome = 0,
    this.dailyExpense = 0,
    this.dailyServed = 0,
    this.dailyLost = 0,
    this.dailySpoiled = 0,
    this.totalServed = 0,
    this.totalLost = 0,
    this.totalSpoiled = 0,
    this.totalIncome = 0,
    List<DailyReport>? reports,
    GameSettings? settings,
  })  : ingredientBatches = ingredientBatches ?? [],
        dishBatches = dishBatches ?? [],
        cookingQueue = cookingQueue ?? [],
        menuPrices = menuPrices ?? {},
        employees = employees ?? [],
        upgrades = upgrades ?? {},
        customers = customers ?? [],
        reports = reports ?? [],
        settings = settings ?? GameSettings();

  /// Game baru: modal awal + harga menu default + stok awal sederhana.
  factory GameState.newGame() {
    final prices = <String, int>{};
    for (final m in kMenu) {
      prices[m.id] = m.basePrice;
    }
    return GameState(
      money: kModalAwal,
      menuPrices: prices,
      // Warung sudah menyiapkan lauk sebelum buka: beberapa porsi siap jual
      // supaya pelanggan pertama langsung bisa dilayani.
      dishBatches: [
        DishBatch(menuId: 'nasi_putih', qty: 6, freshness: 98),
        DishBatch(menuId: 'orek_tempe', qty: 4, freshness: 95),
        DishBatch(menuId: 'tempe_goreng', qty: 4, freshness: 96),
        DishBatch(menuId: 'tahu_goreng', qty: 3, freshness: 96),
        DishBatch(menuId: 'tumis_kangkung', qty: 3, freshness: 92),
        DishBatch(menuId: 'es_teh', qty: 2, freshness: 99),
      ],
      ingredientBatches: [
        IngredientBatch(ingredientId: 'beras', qty: 20, expiryDay: 30),
        IngredientBatch(ingredientId: 'tempe', qty: 10, expiryDay: 4),
        IngredientBatch(ingredientId: 'tahu', qty: 10, expiryDay: 3),
        IngredientBatch(ingredientId: 'telur', qty: 10, expiryDay: 7),
        IngredientBatch(ingredientId: 'ayam', qty: 8, expiryDay: 3),
        IngredientBatch(ingredientId: 'kangkung', qty: 8, expiryDay: 2),
        IngredientBatch(ingredientId: 'sayur_campuran', qty: 8, expiryDay: 3),
        IngredientBatch(ingredientId: 'cabai', qty: 15, expiryDay: 5),
        IngredientBatch(ingredientId: 'bawang', qty: 15, expiryDay: 10),
        IngredientBatch(ingredientId: 'minyak', qty: 10, expiryDay: 30),
        IngredientBatch(ingredientId: 'gula', qty: 10, expiryDay: 30),
        IngredientBatch(ingredientId: 'teh', qty: 10, expiryDay: 30),
        IngredientBatch(ingredientId: 'kopi', qty: 6, expiryDay: 30),
        IngredientBatch(ingredientId: 'tepung', qty: 10, expiryDay: 30),
        IngredientBatch(ingredientId: 'mie', qty: 8, expiryDay: 10),
        IngredientBatch(ingredientId: 'jagung', qty: 6, expiryDay: 5),
        IngredientBatch(ingredientId: 'jeruk', qty: 6, expiryDay: 4),
        IngredientBatch(ingredientId: 'santan', qty: 6, expiryDay: 2),
        IngredientBatch(ingredientId: 'lele', qty: 6, expiryDay: 2),
        IngredientBatch(ingredientId: 'daging', qty: 4, expiryDay: 3),
      ],
    );
  }

  /// Salinan dangkal untuk memicu notifikasi Riverpod setelah mutasi.
  GameState clone() => GameState(
        money: money,
        day: day,
        minuteOfDay: minuteOfDay,
        weather: weather,
        reputation: reputation,
        level: level,
        xp: xp,
        ingredientBatches: ingredientBatches,
        dishBatches: dishBatches,
        cookingQueue: cookingQueue,
        menuPrices: menuPrices,
        employees: employees,
        upgrades: upgrades,
        branchCount: branchCount,
        customers: customers,
        nextCustomerId: nextCustomerId,
        dailyIncome: dailyIncome,
        dailyExpense: dailyExpense,
        dailyServed: dailyServed,
        dailyLost: dailyLost,
        dailySpoiled: dailySpoiled,
        totalServed: totalServed,
        totalLost: totalLost,
        totalSpoiled: totalSpoiled,
        totalIncome: totalIncome,
        reports: reports,
        settings: settings,
      );

  // ---------- Serialisasi (JSON) ----------

  Map<String, dynamic> toMap() => {
        'money': money,
        'day': day,
        'minuteOfDay': minuteOfDay,
        'weather': weather.index,
        'reputation': reputation,
        'level': level,
        'xp': xp,
        'ingredientBatches': ingredientBatches.map((e) => e.toMap()).toList(),
        'dishBatches': dishBatches.map((e) => e.toMap()).toList(),
        'cookingQueue': cookingQueue.map((e) => e.toMap()).toList(),
        'menuPrices': menuPrices,
        'employees': employees.map((e) => e.toMap()).toList(),
        'upgrades': upgrades,
        'branchCount': branchCount,
        'customers': customers.map((e) => e.toMap()).toList(),
        'nextCustomerId': nextCustomerId,
        'dailyIncome': dailyIncome,
        'dailyExpense': dailyExpense,
        'dailyServed': dailyServed,
        'dailyLost': dailyLost,
        'dailySpoiled': dailySpoiled,
        'totalServed': totalServed,
        'totalLost': totalLost,
        'totalSpoiled': totalSpoiled,
        'totalIncome': totalIncome,
        'reports': reports.map((e) => e.toMap()).toList(),
        'settings': settings.toMap(),
      };

  factory GameState.fromMap(Map<String, dynamic> map) => GameState(
        money: (map['money'] as num).toInt(),
        day: (map['day'] as num).toInt(),
        minuteOfDay: (map['minuteOfDay'] as num).toInt(),
        weather: Weather.values[(map['weather'] as num).toInt()],
        reputation: (map['reputation'] as num).toDouble(),
        level: (map['level'] as num).toInt(),
        xp: (map['xp'] as num).toInt(),
        ingredientBatches: (map['ingredientBatches'] as List).map((e) => IngredientBatch.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
        dishBatches: (map['dishBatches'] as List).map((e) => DishBatch.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
        cookingQueue: (map['cookingQueue'] as List).map((e) => CookingJob.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
        menuPrices: (map['menuPrices'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        employees: (map['employees'] as List).map((e) => Employee.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
        upgrades: (map['upgrades'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
        branchCount: (map['branchCount'] as num).toInt(),
        customers: (map['customers'] as List).map((e) => CustomerSim.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
        nextCustomerId: (map['nextCustomerId'] as num).toInt(),
        dailyIncome: (map['dailyIncome'] as num).toInt(),
        dailyExpense: (map['dailyExpense'] as num).toInt(),
        dailyServed: (map['dailyServed'] as num).toInt(),
        dailyLost: (map['dailyLost'] as num).toInt(),
        dailySpoiled: (map['dailySpoiled'] as num).toInt(),
        totalServed: (map['totalServed'] as num).toInt(),
        totalLost: (map['totalLost'] as num).toInt(),
        totalSpoiled: (map['totalSpoiled'] as num).toInt(),
        totalIncome: (map['totalIncome'] as num).toInt(),
        reports: (map['reports'] as List).map((e) => DailyReport.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
        settings: GameSettings.fromMap(Map<String, dynamic>.from(map['settings'] as Map)),
      );

  // ---------- Helper turunan (dari upgrade & karyawan) ----------

  int upgradeLevel(String id) => upgrades[id] ?? 0;

  /// Kapasitas etalase (jumlah porsi masakan).
  /// Dasar 24 porsi cukup untuk lauk pagi; tiap level etalase +6 porsi.
  int get displayCapacity => 24 + upgradeLevel('etalase') * 6;

  /// Jumlah kursi pelanggan.
  int get seatCount => 4 + upgradeLevel('meja_kursi') * 3 + (branchCount > 1 ? 6 : 0);

  /// Pengali kecepatan memasak.
  double get cookSpeedMultiplier {
    double mult = 1.0 + upgradeLevel('kompor') * 0.25;
    for (final e in employees) {
      if (e.role == EmployeeRole.juruMasak) {
        mult += 0.10 * e.skill;
      }
    }
    return mult;
  }

  /// Laju penurunan kesegaran per jam game.
  double get freshnessDecayPerHour {
    double decay = kDecayKesegaranPerJam;
    decay *= 1.0 - kBonusKulkas * upgradeLevel('kulkas');
    decay *= 1.0 - kBonusEtalase * upgradeLevel('etalase');
    return decay < 4 ? 4 : decay;
  }

  /// Total skill kasir (untuk kecepatan transaksi).
  int get kasirSkill {
    int total = 0;
    for (final e in employees) {
      if (e.role == EmployeeRole.kasir) total += e.skill;
    }
    return total;
  }

  /// Total skill pelayan (untuk kecepatan & kepuasan).
  int get pelayanSkill {
    int total = 0;
    for (final e in employees) {
      if (e.role == EmployeeRole.pelayan) total += e.skill;
    }
    return total;
  }

  /// Waktu transaksi per pelanggan di kasir (menit game).
  double get serviceMinutes => (6.0 - kasirSkill * 0.6).clamp(2.0, 6.0);

  /// Waktu makan per pelanggan (menit game).
  double get eatMinutes => (20.0 - pelayanSkill * 1.5).clamp(8.0, 20.0);

  /// Sewa + listrik harian.
  int get dailyFixedCost {
    int cost = kSewaPerHari + kListrikPerHari;
    cost += upgradeLevel('ac') * kListrikPerLevelAc;
    if (branchCount > 1) cost += kSewaCabangPerHari;
    return cost;
  }

  /// Total gaji karyawan per hari.
  int get dailyWages {
    int total = 0;
    for (final e in employees) {
      total += e.wagePerDay;
    }
    return total;
  }

  /// Total stok bahan tertentu (semua batch).
  int stockOf(String ingredientId) {
    int total = 0;
    for (final b in ingredientBatches) {
      if (b.ingredientId == ingredientId) total += b.qty;
    }
    return total;
  }

  /// Total porsi masakan di etalase.
  int get dishCount {
    int total = 0;
    for (final d in dishBatches) {
      total += d.qty;
    }
    return total;
  }

  /// Harga jual menu saat ini (default = harga dasar).
  int priceOf(String menuId) => menuPrices[menuId] ?? menuById(menuId)?.basePrice ?? 0;
}
