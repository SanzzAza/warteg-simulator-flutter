/// HUD: uang, waktu, cuaca, reputasi, level, kecepatan, tombol panel.
///
/// Dibuat ringkas agar di layar HP landscape (< 900 px lebar) sisa ruang untuk
/// dunia game tetap besar.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models/game_state.dart';
import '../../features/game_controller.dart';
import '../theme.dart';

class HudBar extends ConsumerWidget {
  const HudBar({super.key, required this.onBukaPanel});

  /// Callback membuka panel manajemen berdasarkan kode panel.
  final void Function(String panel) onBukaPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final lebar = MediaQuery.sizeOf(context).width;
    // HP landscape: semua info tetap tampil, hanya dipadatkan.
    final ringkas = lebar < 900;

    return Container(
      color: WartegColors.brickDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(ringkas ? 6 : 12, 6, ringkas ? 6 : 12, 6),
          child: Column(
            children: [
              _barisInfo(state, controller, ringkas),
              const SizedBox(height: 5),
              _barisPanel(state, controller, ringkas),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- baris 1
  Widget _barisInfo(GameState state, GameController controller, bool ringkas) {
    final cuacaIkon = switch (state.weather) {
      Weather.cerah => Icons.wb_sunny_rounded,
      Weather.mendung => Icons.cloud_rounded,
      Weather.hujan => Icons.thunderstorm_rounded,
    };
    final cuacaWarna = switch (state.weather) {
      Weather.cerah => const Color(0xFFE0A200),
      Weather.mendung => const Color(0xFF78909C),
      Weather.hujan => const Color(0xFF3F6FB5),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: WartegColors.cream.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _chip(Icons.payments_rounded, rupiah(state.money),
              state.money >= 0 ? WartegColors.green : WartegColors.brick,
              kecil: ringkas),
          const SizedBox(width: 5),
          _chip(cuacaIkon, jamDariMenit(state.minuteOfDay), cuacaWarna,
              kecil: ringkas),
          if (!ringkas) ...[
            const SizedBox(width: 5),
            _chip(Icons.cloud_rounded, state.weather.label, cuacaWarna),
          ],
          const SizedBox(width: 5),
          _chip(Icons.star_rounded, state.reputation.toStringAsFixed(1),
              const Color(0xFFE0A200),
              kecil: ringkas),
          const SizedBox(width: 5),
          _chip(Icons.military_tech_rounded, 'Lv ${state.level}',
              WartegColors.brickDark,
              kecil: ringkas),
          if (!ringkas) ...[
            const SizedBox(width: 5),
            _chip(Icons.groups_rounded, '${state.customers.length} tamu',
                WartegColors.brown,
                kecil: ringkas),
          ],
          const Spacer(),
          _kontrolWaktu(state, controller, ringkas),
        ],
      ),
    );
  }

  Widget _chip(IconData ikon, String label, Color warna, {bool kecil = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: kecil ? 13 : 15, color: warna),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: kecil ? 11.5 : 12.5,
            fontWeight: FontWeight.w800,
            color: warna,
          ),
        ),
      ],
    );
  }

  Widget _kontrolWaktu(GameState state, GameController controller, bool ringkas) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: controller.togglePause,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              state.settings.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 20,
              color: WartegColors.brickDark,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x22A8702F),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in [1, 2, 3])
                InkWell(
                  onTap: () => controller.setKecepatan(s),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: ringkas ? 6 : 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: state.settings.speed == s
                          ? WartegColors.brick
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s}x',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: state.settings.speed == s
                            ? WartegColors.cream
                            : WartegColors.brickDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- baris 2
  Widget _barisPanel(GameState state, GameController controller, bool ringkas) {
    const tombol = <_TombolPanel>[
      _TombolPanel('menu', Icons.restaurant_menu_rounded, 'Menu & Harga', 'Menu'),
      _TombolPanel('stok', Icons.inventory_2_rounded, 'Stok', 'Stok'),
      _TombolPanel('karyawan', Icons.groups_rounded, 'Karyawan', 'Karyawan'),
      _TombolPanel('upgrade', Icons.auto_awesome_rounded, 'Upgrade', 'Upgrade'),
      _TombolPanel('laporan', Icons.receipt_long_rounded, 'Laporan', 'Laporan'),
      _TombolPanel('pengaturan', Icons.settings_rounded, 'Setelan', 'Setelan'),
      _TombolPanel('tutup', Icons.night_shelter_rounded, 'Tutup Warung', 'Tutup'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final t in tombol)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onBukaPanel(t.id),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: ringkas ? 2 : 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.ikon, size: ringkas ? 14 : 18, color: WartegColors.cream),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          ringkas ? t.labelPendek : t.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: ringkas ? 9.5 : 10.5,
                            fontWeight: FontWeight.w700,
                            color: WartegColors.cream,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Di layar sempit tetap ada label pada 3 tombol penting.
          if (ringkas)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                '${state.dishCount} porsi',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xCCFFF3D6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TombolPanel {
  const _TombolPanel(this.id, this.ikon, this.label, this.labelPendek);
  final String id;
  final IconData ikon;
  final String label;
  final String labelPendek;

}
