// Test regresi: panel manajemen harus render bersih di layar HP landscape
// dan tombol X hanya menutup panel (tidak kembali ke menu utama).
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warteg_simulator/data/repositories/save_repository.dart';
import 'package:warteg_simulator/features/game_controller.dart';
import 'package:warteg_simulator/ui/screens/game_screen.dart';
import 'package:warteg_simulator/ui/theme.dart';

Future<void> muat() async {
  final r = FontLoader('Roboto');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']) {
    r.addFont(Future.value(File('assets/fonts/$f').readAsBytesSync().buffer.asByteData()));
  }
  await r.load();
  final i = FontLoader('MaterialIcons')
    ..addFont(Future.value(File('assets/fonts/MaterialIcons-Regular.otf').readAsBytesSync().buffer.asByteData()));
  await i.load();
}

void main() {
  setUpAll(muat);
  for (final tab in ['Stok', 'Menu', 'Karyawan', 'Upgrade', 'Laporan']) {
    testWidgets('panel $tab di landscape HP', (tester) async {
      tester.view.physicalSize = const Size(892, 412);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RepaintBoundary(child: ProviderScope(
        overrides: [saveRepositoryProvider.overrideWithValue(SaveRepository())],
        child: MaterialApp(theme: buildWartegTheme(), home: const GameScreen()),
      )));
      for (var i = 0; i < 8; i++) { await tester.pump(const Duration(milliseconds: 16)); }
      await tester.tap(find.text(tab));
      await tester.pump(); await tester.pump(const Duration(milliseconds: 400));
      final b = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
      await tester.runAsync(() async {
        final img = await b.toImage(pixelRatio: 2.0);
        final d = await img.toByteData(format: ui.ImageByteFormat.png);
        File('/tmp/panel_$tab.png').writeAsBytesSync(d!.buffer.asUint8List());
      });
      // tombol X harus menutup panel, bukan layar game
      expect(find.byType(GameScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(GameScreen), findsOneWidget, reason: 'X tidak boleh menutup layar game');
    });
  }
}

// Regresi bug: dulu tombol X memanggil Navigator.pop() sehingga layar
// permainan ikut tertutup dan aplikasi kembali ke menu utama.
