/// Warteg Simulator — entry point.
///
/// Inisialisasi Hive (penyimpanan save), tema, lalu jalankan app Riverpod.
library;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/audio_service.dart';
import 'data/repositories/save_repository.dart';
import 'features/game_controller.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Game didesain untuk orientasi mendatar (landscape) di Android.
  // Hanya dua orientasi mendatar (tidak termasuk landscape terbalik/upside
  // down) supaya HP bisa dibalik kiri-kanan tanpa tampil terbalik.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Hive untuk save lokal (Android & Windows).
  await Hive.initFlutter();
  final saveRepository = SaveRepository();
  await saveRepository.init();

  // Efek suara + musik latar (opsional — gagal pun game tetap jalan).
  await AudioSvc.instance.inisialisasi();
  await AudioSvc.instance.mulaiMusik();

  runApp(
    ProviderScope(
      overrides: [
        // Satu instance repository dipakai seluruh app.
        saveRepositoryProvider.overrideWithValue(saveRepository),
      ],
      child: const WartegApp(),
    ),
  );
}

class WartegApp extends StatelessWidget {
  const WartegApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warteg Simulator',
      debugShowCheckedModeBanner: false,
      theme: buildWartegTheme(),
      home: const MainMenuScreen(),
      builder: (context, child) {
        // Batasi skala teks agar layout tidak rusak di HP kecil.
        final media = MediaQuery.of(context);
        final skala = media.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
        );
        return MediaQuery(data: media.copyWith(textScaler: skala), child: child!);
      },
    );
  }
}
