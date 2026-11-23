/// Layar permainan: Flame GameWidget + HUD + panel manajemen + dialog laporan.
library;

import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/audio_service.dart';
import '../../core/format.dart';
import '../../data/models/game_state.dart';
import '../../features/game_controller.dart';
import '../../game/warteg_game.dart';
import '../game/hud.dart';
import '../theme.dart';
import '../widgets.dart';
import 'menu_panel.dart';
import 'report_panel.dart';
import 'settings_sheet.dart';
import 'staff_panel.dart';
import 'stock_panel.dart';
import 'upgrade_panel.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  WartegGame? _game;
  GameController? _controller;
  DailyReport? _laporan;
  String? _panelAktif;
  Timer? _timerToast;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Layar penuh (immersive) saat bermain.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final controller = ref.read(gameControllerProvider.notifier);
    _controller = controller;
    _game = WartegGame(
      controller: controller,
      onTutupHari: (report) {
        if (mounted) setState(() => _laporan = report);
      },
    );
    controller.pesanToast.addListener(_toastListener);
    AudioSvc.instance.aktif = controller.stateSaatIni.settings.soundOn;
  }

  void _toastListener() {
    if (!mounted) return;
    final pesan = ref.read(gameControllerProvider.notifier).pesanToast.value;
    if (pesan == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(pesan, style: const TextStyle(fontSize: 13)),
          duration: const Duration(milliseconds: 1400),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    _timerToast?.cancel();
    _timerToast = Timer(const Duration(milliseconds: 1500), () {
      ref.read(gameControllerProvider.notifier).pesanToast.value = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerToast?.cancel();
    // Simpan referensi controller di initState: `ref` tidak boleh dipakai
    // saat dispose.
    _controller?.pesanToast.removeListener(_toastListener);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Lifecycle: pause + autosave saat aplikasi ke background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(gameControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _game?.pauseSimulasi();
    } else if (state == AppLifecycleState.resumed) {
      // Tetap pause sampai pemain menekan Lanjutkan (mencegah waktu lompat).
      controller.setPause(true);
    }
  }

  void _bukaPanel(String id) {
    if (id == 'tutup') {
      _konfirmasiTutupWarung();
      return;
    }
    setState(() => _panelAktif = id);
  }

  Future<void> _konfirmasiTutupWarung() async {
    final state = ref.read(gameControllerProvider);
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Warung Sekarang?'),
        content: Text(
          'Hari ke-${state.day} akan berakhir. Pendapatan hari ini '
          '${rupiah(state.dailyIncome)} dan biaya tetap + gaji akan dibayar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tutup')),
        ],
      ),
    );
    if (ya == true) {
      ref.read(gameControllerProvider.notifier).tutupWarung();
    }
  }

  Future<void> _kembaliKeMenu() async {
    final controller = ref.read(gameControllerProvider.notifier);
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kembali ke Menu Utama?'),
        content: const Text('Progres warung akan disimpan otomatis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan & Keluar'),
          ),
        ],
      ),
    );
    if (keluar != true) return;
    await controller.simpanSekarang();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final panel = _panelAktif;
    final layar = MediaQuery.sizeOf(context);
    final lebarPanel = layar.width < 640 ? layar.width : 430.0;
    final controller = ref.read(gameControllerProvider.notifier);

    return PopScope(
      canPop: panel == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _panelAktif != null) {
          setState(() => _panelAktif = null);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                // HUD selalu bisa dipakai, termasuk saat jeda.
                HudBar(onBukaPanel: _bukaPanel),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _game == null
                            ? const ColoredBox(color: WartegColors.creamDark)
                            : GameWidget(game: _game!),
                      ),
                      const Positioned.fill(
                        child: IgnorePointer(child: _Vignette()),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: StatusChip(
                          icon: Icons.home_rounded,
                          label: 'Menu Utama',
                          onTap: _kembaliKeMenu,
                        ),
                      ),
                      // Overlay jeda: menutup area game saja agar HUD tetap aktif.
                      if (state.settings.paused)
                        Positioned.fill(
                          child: Container(
                            color: const Color(0x66000000),
                            alignment: Alignment.center,
                            child: Card(
                              elevation: 8,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_cafe_rounded,
                                        size: 40, color: WartegColors.brickDark),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Warung Sedang Jeda',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: WartegColors.brickDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Hari ke-${state.day} • '
                                      '${jamDariMenit(state.minuteOfDay)} • '
                                      '${state.weather.label}',
                                      style: const TextStyle(
                                          fontSize: 12.5, color: Color(0x993B2414)),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.icon(
                                      onPressed: controller.togglePause,
                                      icon: const Icon(Icons.play_arrow_rounded),
                                      label: const Text('Lanjutkan Bermain'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Panel manajemen: sheet kanan di desktop, penuh di HP.
            if (panel != null)
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _panelAktif = null),
                        child: Container(color: Colors.black26),
                      ),
                    ),
                    SizedBox(
                      width: lebarPanel,
                      child: Material(
                        color: WartegColors.creamDark,
                        elevation: 12,
                        child: SafeArea(left: false, child: _isiPanel(panel)),
                      ),
                    ),
                  ],
                ),
              ),
            // Dialog laporan harian.
            if (_laporan != null)
              _dialogLaporan(_laporan!, () => setState(() => _laporan = null)),
          ],
        ),
      ),
    );
  }

  Widget _isiPanel(String id) {
    switch (id) {
      case 'menu':
        return const MenuPanel();
      case 'stok':
        return const StockPanel();
      case 'karyawan':
        return const StaffPanel();
      case 'upgrade':
        return const UpgradePanel();
      case 'laporan':
        return const ReportPanel();
      case 'pengaturan':
        return const PengaturanSheet();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _dialogLaporan(DailyReport r, VoidCallback tutup) {
    final laba = r.profit;
    return Center(
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '📒 Laporan Harian',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: WartegColors.brickDark,
                ),
              ),
              Text(
                'Hari ke-${r.day} selesai',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0x993B2414)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Pendapatan',
                      value: rupiah(r.income),
                      color: WartegColors.green,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatTile(
                      label: 'Pengeluaran',
                      value: rupiah(r.expense),
                      color: WartegColors.brick,
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StatTile(
                label: 'Laba Bersih',
                value: rupiah(laba),
                color: laba >= 0 ? WartegColors.green : WartegColors.brick,
                icon: Icons.savings_rounded,
              ),
              const SizedBox(height: 10),
              InfoRow('Pelanggan dilayani', '${r.served}'),
              InfoRow('Pelanggan kabur', '${r.lost}'),
              InfoRow('Porsi basi', '${r.spoiled}'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: tutup,
                icon: const Icon(Icons.wb_sunny_rounded),
                label: const Text('Hari Baru, Semangat Baru!'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vignette hangat sederhana di tepi layar.
class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.1,
          colors: [Color(0x00000000), Color(0x22000000)],
          stops: [0.65, 1.0],
        ),
      ),
    );
  }
}
