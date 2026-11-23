// Alat bantu developer (bukan unit test): merender layar game & menu utama
// ke PNG agar tampilan bisa diperiksa tanpa emulator.
//
// Jalankan: flutter test test/preview_capture.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warteg_simulator/data/models/customer_type.dart';
import 'package:warteg_simulator/data/models/game_state.dart';
import 'package:warteg_simulator/data/repositories/save_repository.dart';
import 'package:warteg_simulator/features/game_controller.dart';
import 'package:warteg_simulator/ui/screens/game_screen.dart';
import 'package:warteg_simulator/ui/screens/main_menu_screen.dart';
import 'package:warteg_simulator/ui/theme.dart';

Future<void> _simpan(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  // ignore: avoid_print
  print('menyimpan $path ukuran=${boundary.size}');
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

Future<void> _muatFont() async {
  final roboto = FontLoader('Roboto');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']) {
    roboto.addFont(Future.value(File('assets/fonts/$f').readAsBytesSync().buffer.asByteData()));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(File('assets/fonts/MaterialIcons-Regular.otf').readAsBytesSync().buffer.asByteData()));
  await icons.load();
}

void main() {
  setUpAll(_muatFont);

  testWidgets('capture menu utama', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        child: ProviderScope(
          overrides: [saveRepositoryProvider.overrideWithValue(SaveRepository())],
          child: MaterialApp(theme: buildWartegTheme(), home: const MainMenuScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _simpan(tester, 'design/preview_menu.png');
  });

  testWidgets('capture layar game portrait (HP)', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [saveRepositoryProvider.overrideWithValue(SaveRepository())],
        child: MaterialApp(theme: buildWartegTheme(), home: const GameScreen()),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('design/preview_portrait.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  });

  testWidgets('capture panel menu', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        child: ProviderScope(
          overrides: [saveRepositoryProvider.overrideWithValue(SaveRepository())],
          child: MaterialApp(theme: buildWartegTheme(), home: const GameScreen()),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.tap(find.text('Menu & Harga'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first,
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('design/preview_panel.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  });

  testWidgets('capture layar game', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      RepaintBoundary(
        child: ProviderScope(
          overrides: [
            saveRepositoryProvider.overrideWithValue(SaveRepository()),
            gameControllerProvider.overrideWith((ref) {
              final c = GameController(
                saveRepository: SaveRepository(),
                autosaveAktif: false,
              );
              // Isi etalase & pelanggan agar preview hidup.
              final st = c.stateSaatIni;
              st.minuteOfDay = 12 * 60 + 15;
              st.money = 2450000;
              st.dailyIncome = 185000;
              st.dailyServed = 9;
              st.level = 3;
              st.reputation = 4.1;
              st.upgrades['etalase'] = 2;
              st.upgrades['kompor'] = 1;
              st.upgrades['meja_kursi'] = 1;
              st.upgrades['dekorasi'] = 1;
              st.ingredientBatches.add(
                IngredientBatch(ingredientId: 'ayam', qty: 8, expiryDay: 3),
              );
              st.dishBatches.addAll([
                DishBatch(menuId: 'nasi_putih', qty: 6, freshness: 92),
                DishBatch(menuId: 'orek_tempe', qty: 4, freshness: 80),
                DishBatch(menuId: 'tahu_goreng', qty: 5, freshness: 55),
                DishBatch(menuId: 'ayam_goreng', qty: 3, freshness: 88),
                DishBatch(menuId: 'tumis_kangkung', qty: 3, freshness: 70),
                DishBatch(menuId: 'es_teh', qty: 6, freshness: 95),
              ]);
              st.customers.addAll([
                CustomerSim(
                  id: 1,
                  type: CustomerType.ojol,
                  stage: CustomerStage.antre,
                  patience: 8,
                  budget: 18000,
                  queueIndex: 0,
                ),
                CustomerSim(
                  id: 2,
                  type: CustomerType.ibuRT,
                  stage: CustomerStage.antre,
                  patience: 20,
                  budget: 25000,
                  queueIndex: 1,
                ),
                CustomerSim(
                  id: 3,
                  type: CustomerType.pekerja,
                  stage: CustomerStage.makan,
                  patience: 10,
                  budget: 30000,
                  satisfaction: 4.5,
                  seatIndex: 0,
                  order: {'nasi_putih': 1, 'ayam_goreng': 1},
                  totalBayar: 20000,
                ),
                CustomerSim(
                  id: 4,
                  type: CustomerType.anakKos,
                  stage: CustomerStage.makan,
                  patience: 22,
                  budget: 15000,
                  satisfaction: 2.0,
                  seatIndex: 5,
                  order: {'nasi_putih': 1, 'orek_tempe': 1},
                  totalBayar: 13000,
                ),
                CustomerSim(
                  id: 5,
                  type: CustomerType.mahasiswa,
                  stage: CustomerStage.pesan,
                  patience: 18,
                  budget: 12000,
                  seatIndex: -2,
                  order: {'nasi_putih': 1, 'es_teh': 1},
                  totalBayar: 9000,
                ),
              ]);
              c.setPause(true);
              return c;
            }),
          ],
          child: MaterialApp(theme: buildWartegTheme(), home: const GameScreen()),
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await _simpan(tester, 'design/preview_game.png');
  });
}
