// Smoke test UI: menu utama tampil, game screen + Flame berjalan tanpa error.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warteg_simulator/data/repositories/save_repository.dart';
import 'package:warteg_simulator/features/game_controller.dart';
import 'package:warteg_simulator/main.dart';
import 'package:warteg_simulator/ui/screens/game_screen.dart';

void main() {
  testWidgets('menu utama menampilkan semua opsi dalam Bahasa Indonesia', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveRepositoryProvider.overrideWithValue(SaveRepository()),
        ],
        child: const WartegApp(),
      ),
    );
    await tester.pump();

    expect(find.text('WARTEG'), findsOneWidget);
    expect(find.text('SIMULATOR'), findsOneWidget);
    expect(find.text('Lanjutkan'), findsOneWidget);
    expect(find.text('Game Baru'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
  });

  testWidgets('layar game merender Flame + HUD dan bisa dibuka panelnya', (tester) async {
    // Layar lebar (desktop) agar HUD memakai label lengkap.
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saveRepositoryProvider.overrideWithValue(SaveRepository()),
        ],
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    // Biarkan Flame onLoad + beberapa frame simulasi berjalan.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // HUD dasar.
    expect(find.textContaining('Rp2.000.000'), findsOneWidget);
    expect(find.text('Menu & Harga'), findsOneWidget);
    expect(find.text('Tutup Warung'), findsOneWidget);

    // Buka panel Menu & Harga.
    await tester.tap(find.text('Menu & Harga'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Nasi Putih'), findsWidgets);

    // Tutup panel.
    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump(const Duration(milliseconds: 50));
  });
}
