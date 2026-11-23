/// Object pool untuk komponen pelanggan — menghindari alokasi komponen
/// baru setiap kali pelanggan datang (target 60 FPS di HP mid-range).
library;

import 'dart:ui';

import 'package:flame/components.dart';

import '../data/models/game_state.dart';
import 'components/customer_component.dart';

class CustomerPool {
  CustomerPool({required this.parent, this.initialSize = 12, this.maxSize = 18});

  final Component parent;
  final int initialSize;
  final int maxSize;

  final List<CustomerComponent> _pool = [];
  final Map<int, CustomerComponent> _aktif = {};

  /// Komponen pelanggan aktif berdasarkan id simulasi.
  Map<int, CustomerComponent> get aktif => Map.unmodifiable(_aktif);

  /// Isi pool di awal (dipanggil saat onLoad).
  void warmUp() {
    for (var i = 0; i < initialSize; i++) {
      final c = CustomerComponent()..lepas();
      _pool.add(c);
      parent.add(c);
    }
  }

  /// Sinkronkan daftar simulasi pelanggan ke komponen visual.
  ///
  /// Komponen yang tidak lagi dipakai dikembalikan ke pool — tidak pernah
  /// dihancurkan selama game berjalan.
  void sinkronkan(List<CustomerSim> daftar, Offset Function(CustomerSim) posisiAwal) {
    final ids = daftar.map((e) => e.id).toSet();

    // 1) Lepas komponen yang pelanggannya sudah pergi.
    final lepas = _aktif.keys.where((id) => !ids.contains(id)).toList();
    for (final id in lepas) {
      final comp = _aktif.remove(id)!;
      comp.lepas();
      _pool.add(comp);
    }

    // 2) Ambil / buat komponen untuk pelanggan baru.
    for (final sim in daftar) {
      if (_aktif.containsKey(sim.id)) continue;
      CustomerComponent? comp;
      if (_pool.isNotEmpty) {
        comp = _pool.removeLast();
      } else if (_aktif.length < maxSize) {
        comp = CustomerComponent();
        parent.add(comp);
      } else {
        continue; // batas visual tercapai; pelanggan tetap disimulasikan.
      }
      _aktif[sim.id] = comp;
      comp.siapkan(sim, posisiAwal(sim));
    }
  }

  /// Lepas semua komponen (dipakai saat meninggalkan game).
  void bersihkan() {
    for (final comp in _aktif.values) {
      comp.lepas();
      _pool.add(comp);
    }
    _aktif.clear();
  }
}
