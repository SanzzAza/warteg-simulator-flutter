/// Panel Upgrade & Ekspansi.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/format.dart';
import '../../data/models/upgrade.dart';
import '../../features/game_controller.dart';
import '../theme.dart';
import '../widgets.dart';

class UpgradePanel extends ConsumerWidget {
  const UpgradePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    return Column(
      children: [
        PanelHeader(
          icon: Icons.auto_awesome_rounded,
          title: 'Upgrade & Ekspansi',
          subtitle: 'Uang: ${rupiah(state.money)} • Level ${state.level}',
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            itemCount: kUpgrades.length,
            itemBuilder: (context, i) {
              final u = kUpgrades[i];
              final levelSekarang = state.upgradeLevel(u.id);
              final maks = levelSekarang >= u.maxLevel;
              final terbuka = state.level >= u.requiredLevel;
              final biaya = maks
                  ? 0
                  : biayaUpgrade(u.baseCost, u.costGrowth, levelSekarang);
              final mampu = state.money >= biaya;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: WartegColors.orangeSoft.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(_ikon(u.id), color: WartegColors.brickDark, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 14)),
                                Text(
                                  u.desc,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0x993B2414), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Indikator level (kotak penuh sesuai level).
                          for (var l = 0; l < u.maxLevel; l++)
                            Container(
                              width: 14,
                              height: 10,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: l < levelSekarang
                                    ? WartegColors.orange
                                    : const Color(0x22A8702F),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Text(
                            'Lv $levelSekarang/${u.maxLevel}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          if (!terbuka)
                            StatusChip(
                              icon: Icons.lock_rounded,
                              label: 'Butuh Lv ${u.requiredLevel}',
                              color: WartegColors.brown,
                            )
                          else if (maks)
                            const StatusChip(
                              icon: Icons.verified_rounded,
                              label: 'Maksimal',
                              color: WartegColors.green,
                            )
                          else
                            MiniButton(
                              label: 'Beli ${rupiah(biaya)}',
                              icon: Icons.shopping_cart_checkout_rounded,
                              aktif: mampu,
                              onPressed: () => controller.beliUpgrade(u.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _ikon(String id) {
    switch (id) {
      case 'etalase':
        return Icons.storefront_rounded;
      case 'kompor':
        return Icons.local_fire_department_rounded;
      case 'kulkas':
        return Icons.kitchen_rounded;
      case 'meja_kursi':
        return Icons.chair_rounded;
      case 'dekorasi':
        return Icons.park_rounded;
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'cabang':
        return Icons.store_mall_directory_rounded;
      default:
        return Icons.upgrade_rounded;
    }
  }
}
