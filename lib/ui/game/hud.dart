/// HUD: uang, waktu, cuaca, reputasi, level, kecepatan, tombol panel.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/models/game_state.dart';
import '../../features/game_controller.dart';
import '../theme.dart';
import '../widgets.dart';

class HudBar extends ConsumerWidget {
  const HudBar({super.key, required this.onBukaPanel});

  /// Callback membuka panel manajemen berdasarkan nama panel.
  final void Function(String panel) onBukaPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final lebar = MediaQuery.sizeOf(context).width;
    final padat = lebar < 760;

    return Container(
      color: WartegColors.brickDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(padat ? 8 : 14, 8, padat ? 8 : 14, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _barisAtas(context, state, controller, padat),
              const SizedBox(height: 6),
              _barisBawah(context, state, controller, padat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barisAtas(
      BuildContext context, GameState state, GameController controller, bool padat) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: WartegColors.cream.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x44A8702F)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Uang
          StatusChip(
            icon: Icons.payments_rounded,
            label: rupiah(state.money),
            color: state.money >= 0 ? WartegColors.green : WartegColors.brick,
          ),
          const SizedBox(width: 6),
          // Waktu + cuaca
          StatusChip(
            icon: cuacaIkon,
            label: '${jamDariMenit(state.minuteOfDay)} • ${state.weather.label}',
            color: cuacaWarna,
          ),
          const SizedBox(width: 6),
          if (!padat) ...[
            // Reputasi
            StatusChip(
              icon: Icons.star_rounded,
              label: state.reputation.toStringAsFixed(1),
              color: const Color(0xFFE0A200),
            ),
            const SizedBox(width: 6),
            // Level + XP
            StatusChip(
              icon: Icons.military_tech_rounded,
              label: 'Lv ${state.level}',
              color: WartegColors.brickDark,
            ),
          ],
          const Spacer(),
          // Kontrol kecepatan
          _kontrolKecepatan(state, controller, padat),
        ],
      ),
    );
  }

  Widget _kontrolKecepatan(GameState state, GameController controller, bool padat) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: state.settings.paused ? 'Lanjutkan' : 'Jeda',
          onPressed: controller.togglePause,
          icon: Icon(
            state.settings.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            color: WartegColors.brickDark,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x22A8702F),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in [1, 2, 3])
                GestureDetector(
                  onTap: () => controller.setKecepatan(s),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: padat ? 7 : 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: state.settings.speed == s
                          ? WartegColors.brick
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${s}x',
                      style: TextStyle(
                        fontSize: 11.5,
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

  Widget _barisBawah(
      BuildContext context, GameState state, GameController controller, bool padat) {
    const tombol = <_TombolPanel>[
      _TombolPanel('menu', Icons.restaurant_menu_rounded, 'Menu & Harga'),
      _TombolPanel('stok', Icons.inventory_2_rounded, 'Stok'),
      _TombolPanel('karyawan', Icons.groups_rounded, 'Karyawan'),
      _TombolPanel('upgrade', Icons.auto_awesome_rounded, 'Upgrade'),
      _TombolPanel('laporan', Icons.receipt_long_rounded, 'Laporan'),
      _TombolPanel('pengaturan', Icons.settings_rounded, 'Setelan'),
      _TombolPanel('tutup', Icons.night_shelter_rounded, 'Tutup Warung'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: WartegColors.brickDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final t in tombol)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onBukaPanel(t.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.ikon, size: padat ? 18 : 20, color: WartegColors.cream),
                      const SizedBox(height: 1),
                      Text(
                        padat ? _singkat(t.label) : t.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: WartegColors.cream,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _singkat(String label) {
    if (label.length <= 7) return label;
    return label
        .replaceAll(' & Harga', '')
        .replaceAll('Warung', '')
        .replaceAll('& ', '')
        .trim();
  }
}

class _TombolPanel {
  const _TombolPanel(this.id, this.ikon, this.label);
  final String id;
  final IconData ikon;
  final String label;
}
