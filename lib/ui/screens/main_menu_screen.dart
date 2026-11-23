/// Layar menu utama: Lanjutkan, Game Baru, Pengaturan, Keluar.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio_service.dart';
import '../../features/game_controller.dart';
import '../screens/settings_sheet.dart';
import '../theme.dart';
import 'game_screen.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  bool _adaSave = false;

  @override
  void initState() {
    super.initState();
    _adaSave = ref.read(saveRepositoryProvider).hasSave;
  }

  void _lanjutkan() {
    final save = ref.read(saveRepositoryProvider).load();
    if (save == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save tidak ditemukan atau rusak.')),
      );
      setState(() => _adaSave = false);
      return;
    }
    AudioSvc.instance.klik();
    AudioSvc.instance.aktif = save.settings.soundOn;
    ref.read(gameControllerProvider.notifier).muat(save);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
  }

  Future<void> _baru() async {
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai Game Baru?'),
        content: const Text(
          'Progres warung saat ini akan tertimpa oleh warung baru dengan '
          'modal Rp2.000.000. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Mulai Baru'),
          ),
        ],
      ),
    );
    if (lanjut != true) return;
    AudioSvc.instance.klik();
    final controller = ref.read(gameControllerProvider.notifier);
    controller.mulaiBaru();
    await ref.read(saveRepositoryProvider).delete();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
  }

  Future<void> _keluar() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar Aplikasi?'),
        content: const Text('Progres tersimpan otomatis. Sampai jumpa!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (keluar == true && mounted) {
      // Menutup aplikasi dengan aman di desktop & Android.
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final layar = MediaQuery.sizeOf(context);
    final lebar = layar.width < 720 ? layar.width * 0.86 : 380.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7B267), Color(0xFFE07A2E), Color(0xFFB4472B)],
          ),
        ),
        child: Stack(
          children: [
            // Atap genteng dekoratif di atas.
            Positioned.fill(
              child: CustomPaint(painter: _BackdropPainter()),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _logo(),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: lebar,
                        child: Column(
                          children: [
                            _TombolMenu(
                              ikon: Icons.play_arrow_rounded,
                              label: 'Lanjutkan',
                              sublabel: _adaSave ? 'Muat warung terakhir' : 'Belum ada save',
                              onTap: _adaSave ? _lanjutkan : null,
                              utama: true,
                            ),
                            const SizedBox(height: 10),
                            _TombolMenu(
                              ikon: Icons.restaurant_menu_rounded,
                              label: 'Game Baru',
                              sublabel: 'Mulai dari modal Rp2.000.000',
                              onTap: _baru,
                            ),
                            const SizedBox(height: 10),
                            _TombolMenu(
                              ikon: Icons.settings_rounded,
                              label: 'Pengaturan',
                              sublabel: 'Suara, kecepatan, info',
                              onTap: () => tampilkanPengaturan(context, ref),
                            ),
                            const SizedBox(height: 10),
                            _TombolMenu(
                              ikon: Icons.exit_to_app_rounded,
                              label: 'Keluar',
                              sublabel: 'Tutup aplikasi',
                              onTap: _keluar,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Masakan rumahan, harga merakyat 🇮🇩',
                        style: TextStyle(
                          color: Color(0xFFFFF3D6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: WartegColors.brick,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: WartegColors.yellow, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0x55000000), blurRadius: 16, offset: Offset(0, 8)),
            ],
          ),
          child: const Column(
            children: [
              Text(
                'WARTEG',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: WartegColors.yellow,
                  letterSpacing: 8,
                  height: 1.0,
                ),
              ),
              Text(
                'SIMULATOR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: WartegColors.cream,
                  letterSpacing: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kelola warung tegal, dari kompor sampai cabang!',
          style: TextStyle(color: Color(0xFFFFE8B8), fontSize: 13.5),
        ),
      ],
    );
  }
}

class _TombolMenu extends StatelessWidget {
  const _TombolMenu({
    required this.ikon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.utama = false,
  });

  final IconData ikon;
  final String label;
  final String sublabel;
  final VoidCallback? onTap;
  final bool utama;

  @override
  Widget build(BuildContext context) {
    final aktif = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: aktif
                ? (utama ? WartegColors.brick : WartegColors.cream)
                : const Color(0x55FFF3D6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: utama ? WartegColors.yellow : const Color(0x55A8702F),
              width: utama ? 2.5 : 1.5,
            ),
            boxShadow: aktif
                ? const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                ikon,
                size: 30,
                color: aktif
                    ? (utama ? WartegColors.yellow : WartegColors.brickDark)
                    : const Color(0x88FFF3D6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: aktif
                            ? (utama ? WartegColors.cream : WartegColors.brickDark)
                            : const Color(0x88FFF3D6),
                      ),
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: aktif
                            ? (utama ? const Color(0xCCFFF3D6) : const Color(0x993B2414))
                            : const Color(0x66FFF3D6),
                      ),
                    ),
                  ],
                ),
              ),
              if (aktif)
                Icon(
                  Icons.chevron_right_rounded,
                  color: utama ? WartegColors.yellow : WartegColors.wood,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Latar bergaya: atap genteng + uap hangat.
class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final genteng = Paint()..color = const Color(0x22FFF3D6);
    for (var y = 0.0; y < size.height; y += 44) {
      final offset = (y / 44).round().isOdd ? 28.0 : 0.0;
      for (var x = -28.0; x < size.width + 28; x += 56) {
        canvas.drawArc(
          Rect.fromLTWH(x + offset, y, 56, 44),
          0,
          3.14159,
          true,
          genteng,
        );
      }
    }
    // Lingkaran hangat di sudut (efek lampu).
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.18),
      170,
      Paint()..color = const Color(0x22FFD24C),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      220,
      Paint()..color = const Color(0x11FFF3D6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
