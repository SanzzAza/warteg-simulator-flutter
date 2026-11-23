/// Helper navigasi panel manajemen.
///
/// Panel dibuka sebagai route tersendiri (bukan sheet di dalam tree
/// GameScreen), sehingga tombol X hanya menutup panel — tidak menutup layar
/// permainan lalu membuat aplikasi kembali ke menu utama.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../features/game_controller.dart';
import 'theme.dart';

/// Tutup panel yang sedang terbuka.
void tutupPanel(BuildContext context) => Navigator.of(context).maybePop();

/// Buka panel manajemen [id] dengan isi [isi].
///
/// Simulasi otomatis dijedakan selama panel terbuka agar pemain bisa mengatur
/// warung dengan tenang; status jeda dipulihkan saat panel ditutup.
Future<void> bukaPanel(
  BuildContext context,
  WidgetRef ref,
  String id,
  Widget isi,
) async {
  final controller = ref.read(gameControllerProvider.notifier);
  final sudahJeda = ref.read(gameControllerProvider).settings.paused;
  if (!sudahJeda) controller.setPause(true);

  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => Material(
        color: WartegColors.creamDark,
        child: SafeArea(child: isi),
      ),
    ),
  );

  // Kembalikan simulasi seperti sebelum panel dibuka.
  if (!sudahJeda) controller.setPause(false);
}
