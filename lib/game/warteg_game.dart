/// FlameGame utama: menghubungkan simulasi (GameController) ke visual.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../data/models/game_state.dart';
import '../features/game_controller.dart';
import 'components/floating_text.dart';
import 'components/table_component.dart';
import 'components/warung_components.dart';
import 'customer_pool.dart';
import 'palette.dart';
import 'scene_layout.dart';

class WartegGame extends FlameGame {
  WartegGame({required this.controller, this.onTutupHari});

  final GameController controller;

  /// Callback saat laporan harian baru tersedia (dipicu controller).
  final void Function(DailyReport report)? onTutupHari;

  late final CustomerPool _pool;
  late final FloatingTextPool _floating;
  late final List<TableComponent> _tables;

  List<CustomerSim> _cacheCustomers = const [];
  int _cacheSeatCount = -1;

  /// Kursi yang terpakai pada frame ini (dihitung sekali, bukan per kursi).
  final Set<int> _kursiTerpakai = <int>{};

  @override
  Color backgroundColor() => WartegPalette.cream;

  @override
  Future<void> onLoad() async {
    // Kamera "contain": dunia 1280x800 selalu tampil utuh, diskalakan
    // otomatis untuk layar HP, tablet, maupun jendela desktop.
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(SceneLayout.width / 2, SceneLayout.height / 2);
    _sesuaikanKamera();

    // Dekorasi statis — ditambahkan ke `world` supaya ikut transform kamera.
    world.addAll([
      WarungInterior(readState: () => controller.stateSaatIni),
      KitchenArea(readState: () => controller.stateSaatIni),
      DisplayCase(readState: () => controller.stateSaatIni),
      CashierStation(readState: () => controller.stateSaatIni),
      DecorationsLayer(readState: () => controller.stateSaatIni),
    ]);

    // Meja & kursi.
    _tables = [];
    for (var i = 0; i < SceneLayout.meja.length; i++) {
      final table = TableComponent(
        index: i,
        seatCount: 4,
        occupied: (seat) => _kursiTerpakai.contains(seat),
      );
      _tables.add(table);
      world.add(table);
    }

    // Pool pelanggan & teks melayang.
    _pool = CustomerPool(parent: world)..warmUp();
    _floating = FloatingTextPool(parent: world)..warmUp();

    // Dengar laporan harian untuk diteruskan ke UI overlay.
    controller.laporanBaru.addListener(_laporanListener);
    controller.pesanToast.addListener(_toastListener);

    // Sinkron awal.
    _sinkronPelanggan(controller.stateSaatIni);
  }

  void _laporanListener() {
    final report = controller.laporanBaru.value;
    if (report != null) onTutupHari?.call(report);
  }

  String? _toastTerakhir;
  void _toastListener() {
    final pesan = controller.pesanToast.value;
    if (pesan == null || pesan == _toastTerakhir) return;
    _toastTerakhir = pesan;
    // Tampilkan toast juga sebagai teks melayang di atas warung.
    _floating.tampilkan(pesan, const Offset(SceneLayout.width / 2, 96),
        WartegPalette.brickDark);
  }

  double _zoomTerakhir = 0;

  @override
  void update(double dt) {
    // Jaga zoom "contain" setiap frame (ukuran viewport bisa berubah kapan
    // saja: rotasi HP, resize jendela desktop).
    _sesuaikanKamera();
    // 1) Majukan simulasi (controller mengabaikan tick saat pause).
    controller.tick(dt);

    // 2) Sinkronkan pelanggan hanya bila daftar atau jumlah kursi berubah.
    final st = controller.stateSaatIni;
    if (!identical(st.customers, _cacheCustomers) ||
        st.customers.length != _cacheCustomers.length ||
        st.seatCount != _cacheSeatCount) {
      _cacheCustomers = List<CustomerSim>.of(st.customers);
      _cacheSeatCount = st.seatCount;
      _sinkronPelanggan(st);
    } else {
      // Data pelanggan dimutasi di tempat; komponen membaca objek yang sama
      // sehingga tidak perlu langkah tambahan.
      _cacheCustomers = st.customers;
    }

    super.update(dt);
  }

  void _sinkronPelanggan(GameState st) {
    _pool.sinkronkan(
      st.customers,
      (sim) => sim.stage == CustomerStage.datang
          ? SceneLayout.pintuLuar
          : sim.stage == CustomerStage.pulang
              ? SceneLayout.pintuDalam
              : sim.stage == CustomerStage.makan
                  ? SceneLayout.kursi(sim.seatIndex)
                  : SceneLayout.depanKasir,
    );
    // Tampilkan +Rp melayang ketika ada pelanggan yang baru selesai bayar.
    for (final c in st.customers) {
      if (c.stage == CustomerStage.makan && c.totalBayar > 0) {
        final comp = _pool.aktif[c.id];
        if (comp != null && !comp.sudahTampilBayar) {
          comp.sudahTampilBayar = true;
          _floating.tampilkan(
            '+Rp${_ribuan(c.totalBayar)}',
            Offset(comp.position.x, comp.position.y - 96),
            const Color(0xFF2E7D32),
          );
        }
      }
    }
  }

  String _ribuan(int v) {
    final digits = v.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Pause otomatis saat aplikasi ke background (lifecycle).
  void pauseSimulasi() {
    controller.setPause(true);
    unawaited(controller.simpanSekarang());
  }

  @override
  void onRemove() {
    controller.laporanBaru.removeListener(_laporanListener);
    controller.pesanToast.removeListener(_toastListener);
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _sesuaikanKamera();
    if (kDebugMode) {
      debugPrint(
        'WartegGame resize: ${size.x.toStringAsFixed(0)}x${size.y.toStringAsFixed(0)} zoom=${camera.viewfinder.zoom}',
      );
    }
  }

  /// Skala kamera agar 1280x800 muat penuh (letterbox bila perlu).
  void _sesuaikanKamera() {
    if (size.x <= 0 || size.y <= 0) return;
    final zoom = math.min(
      size.x / SceneLayout.width,
      size.y / SceneLayout.height,
    ).clamp(0.2, 3.0);
    if ((zoom - _zoomTerakhir).abs() < 0.001) return;
    _zoomTerakhir = zoom;
    camera.viewfinder.zoom = zoom;
  }
}
