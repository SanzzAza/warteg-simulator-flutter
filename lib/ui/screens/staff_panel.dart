/// Panel Karyawan: rekrut & pecat juru masak, kasir, pelayan.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/models/employee.dart';
import '../../features/game_controller.dart';
import '../theme.dart';
import '../widgets.dart';

class StaffPanel extends ConsumerWidget {
  const StaffPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final batas = ref.read(gameControllerProvider.notifier).staffService.batasKaryawan(state);
    final penuh = state.employees.length >= batas;

    return Column(
      children: [
        PanelHeader(
          icon: Icons.groups_rounded,
          title: 'Karyawan',
          subtitle: '${state.employees.length}/$batas orang • gaji ${rupiah(state.dailyWages)}/hari',
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            children: [
              const Text('Rekrut Baru', style: TextStyle(fontWeight: FontWeight.w900, color: WartegColors.brickDark)),
              const SizedBox(height: 6),
              for (final role in EmployeeRole.values)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: WartegColors.orangeSoft.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(_ikon(role), color: WartegColors.brickDark),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(role.label,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                              Text(
                                '${role.desc}\nGaji ${rupiah(role.baseWage)}/hari + bonus skill',
                                style: const TextStyle(fontSize: 11, color: Color(0x993B2414), height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rekrut ${rupiah(role.hireFee)}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            MiniButton(
                              label: 'Rekrut',
                              icon: Icons.person_add_alt_1_rounded,
                              aktif: !penuh && state.money >= role.hireFee,
                              onPressed: () => controller.rekrut(role),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              if (penuh)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Karyawan penuh. Buka cabang kedua untuk menambah 3 slot lagi.',
                    style: TextStyle(fontSize: 11.5, color: WartegColors.brick),
                  ),
                ),
              const SizedBox(height: 10),
              const Text('Tim Saat Ini', style: TextStyle(fontWeight: FontWeight.w900, color: WartegColors.brickDark)),
              const SizedBox(height: 6),
              if (state.employees.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada karyawan. Warung masih dikelola sendiri — '
                    'pelanggan menunggu lebih lama.',
                    style: TextStyle(fontSize: 12.5, color: Color(0x993B2414)),
                  ),
                ),
              for (final e in state.employees)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: WartegColors.wood,
                          child: Text(
                            e.name.split(' ').last.characters.first,
                            style: const TextStyle(
                                color: WartegColors.cream, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.name} • ${e.role.label}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 13)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text('Skill ${e.skill}/5 ',
                                      style: const TextStyle(fontSize: 11)),
                                  StarRating(value: e.skill.toDouble(), size: 12),
                                ],
                              ),
                              Text(
                                'Gaji ${rupiah(e.wagePerDay)}/hari • XP ${e.xp}/${100 * e.skill}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0x993B2414)),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _konfirmasiPecat(context, controller, e),
                          icon: const Icon(Icons.person_remove_rounded, size: 16),
                          label: const Text('Pecat', style: TextStyle(fontSize: 11.5)),
                          style: TextButton.styleFrom(foregroundColor: WartegColors.brick),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _ikon(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.juruMasak:
        return Icons.soup_kitchen_rounded;
      case EmployeeRole.kasir:
        return Icons.point_of_sale_rounded;
      case EmployeeRole.pelayan:
        return Icons.room_service_rounded;
    }
  }

  Future<void> _konfirmasiPecat(
      BuildContext context, GameController controller, Employee e) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pecat ${e.name}?'),
        content: Text(
          'Pesangon ${rupiah((e.wagePerDay * 0.5).round())} dibayar sekali. '
          'Karyawan akan hilang dari tim.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: WartegColors.brick),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pecat'),
          ),
        ],
      ),
    );
    if (ya == true) controller.pecat(e);
  }
}
