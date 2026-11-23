/// Panel pengaturan — dapat dibuka dari menu utama maupun saat bermain.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game_controller.dart';
import '../theme.dart';
import '../widgets.dart';

Future<void> tampilkanPengaturan(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: WartegColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const PengaturanSheet(sebagaiPanel: false),
  );
}

class PengaturanSheet extends ConsumerWidget {
  const PengaturanSheet({super.key, this.sebagaiPanel = true});

  /// true = konten panel (di dalam game), false = bottom sheet.
  final bool sebagaiPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    final isi = ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        if (sebagaiPanel)
          PanelHeader(
            icon: Icons.settings_rounded,
            title: 'Pengaturan',
            subtitle: 'Sesuaikan pengalaman bermain',
            onClose: () => Navigator.of(context).pop(),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: state.settings.soundOn,
          onChanged: (_) => controller.toggleSuara(),
          title: const Text('Suara & Musik', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Efek suara sederhana saat bermain'),
          secondary: Icon(
            state.settings.soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: WartegColors.brickDark,
          ),
        ),
        const Divider(),
        const Text('Kecepatan Waktu', style: TextStyle(fontWeight: FontWeight.w800, color: WartegColors.brickDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final s in [1, 2, 3])
              ChoiceChip(
                label: Text('${s}x'),
                selected: state.settings.speed == s,
                onSelected: (_) => controller.setKecepatan(s),
              ),
          ],
        ),
        const Divider(),
        const Text('Tentang', style: TextStyle(fontWeight: FontWeight.w800, color: WartegColors.brickDark)),
        const SizedBox(height: 6),
        const Text(
          'Warteg Simulator v1.0.0\n'
          'Game simulasi warung tegal khas Indonesia. '
          'Dibuat dengan Flutter, Flame, Riverpod, dan Hive.\n\n'
          'Tips: ubah harga menu di panel "Menu & Harga" — harga murah '
          'menarik pelanggan, tapi jaga margin agar tetap untung!',
          style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xCC3B2414)),
        ),
        const SizedBox(height: 16),
        if (sebagaiPanel)
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Selesai'),
          ),
      ],
    );

    if (!sebagaiPanel) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0x33A8702F),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Flexible(child: isi),
          ],
        ),
      );
    }
    return isi;
  }
}
