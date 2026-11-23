/// Panel Laporan Keuangan: rekap hari ini + riwayat harian.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/format.dart';
import '../../data/models/game_state.dart';
import '../../features/game_controller.dart';
import '../theme.dart';
import '../widgets.dart';

class ReportPanel extends ConsumerWidget {
  const ReportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final labaHariIni = state.dailyIncome - state.dailyExpense;

    return Column(
      children: [
        PanelHeader(
          icon: Icons.receipt_long_rounded,
          title: 'Laporan Keuangan',
          subtitle: 'Hari ke-${state.day} • kas ${rupiah(state.money)}',
          onClose: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hari Ini (berjalan)',
                          style: TextStyle(fontWeight: FontWeight.w900, color: WartegColors.brickDark)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _kartuAngka('Pendapatan', rupiah(state.dailyIncome),
                              WartegColors.green, Icons.trending_up_rounded),
                          const SizedBox(width: 8),
                          _kartuAngka('Pengeluaran', rupiah(state.dailyExpense),
                              WartegColors.brick, Icons.trending_down_rounded),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _kartuAngka(
                        'Laba Bersih',
                        rupiah(labaHariIni),
                        labaHariIni >= 0 ? WartegColors.green : WartegColors.brick,
                        Icons.savings_rounded,
                        lebar: double.infinity,
                      ),
                      const SizedBox(height: 10),
                      InfoRow('Pelanggan dilayani', '${state.dailyServed} orang'),
                      InfoRow('Pelanggan kabur', '${state.dailyLost} orang'),
                      InfoRow('Porsi basi terbuang', '${state.dailySpoiled} porsi'),
                      const Divider(),
                      const Text('Biaya harian (dibayar saat tutup)',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      InfoRow('Sewa', rupiah(_sewaHarian(state))),
                      InfoRow('Listrik', rupiah(state.dailyFixedCost - _sewaHarian(state))),
                      InfoRow('Gaji karyawan', rupiah(state.dailyWages)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Riwayat Harian',
                  style: TextStyle(fontWeight: FontWeight.w900, color: WartegColors.brickDark)),
              const SizedBox(height: 4),
              if (state.reports.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada laporan. Laporan muncul setelah warung tutup (22.00).',
                    style: TextStyle(fontSize: 12.5, color: Color(0x993B2414)),
                  ),
                ),
              for (final r in state.reports.reversed.take(14))
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: WartegPaletteColors.hari(r),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'H${r.day}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w900, color: WartegColors.cream),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masuk ${rupiah(r.income)} • Keluar ${rupiah(r.expense)}',
                                style: const TextStyle(fontSize: 11.5),
                              ),
                              Text(
                                '${r.served} dilayani • ${r.lost} kabur • ${r.spoiled} basi',
                                style: const TextStyle(fontSize: 10.5, color: Color(0x993B2414)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          rupiah(r.profit),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: r.profit >= 0 ? WartegColors.green : WartegColors.brick,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sepanjang Masa',
                          style: TextStyle(fontWeight: FontWeight.w900, color: WartegColors.brickDark)),
                      const SizedBox(height: 6),
                      InfoRow('Total pelanggan dilayani', '${state.totalServed}'),
                      InfoRow('Total pendapatan', rupiah(state.totalIncome)),
                      InfoRow('Total porsi basi', '${state.totalSpoiled}'),
                      InfoRow('Total pelanggan kabur', '${state.totalLost}'),
                      InfoRow('Reputasi', '${state.reputation.toStringAsFixed(1)} / 5'),
                      InfoRow('Level pemain', '${state.level}'),
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

  Widget _kartuAngka(String label, String nilai, Color warna, IconData ikon,
      {double? lebar}) {
    return Container(
      width: lebar,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: warna.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ikon, size: 14, color: warna),
              const SizedBox(width: 4),
              Text(label, style: kWartegLabel),
            ],
          ),
          const SizedBox(height: 2),
          Text(nilai,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: warna)),
        ],
      ),
    );
  }
}

/// Sewa utama + cabang; selisih dailyFixedCost dihitung sebagai listrik.
int _sewaHarian(GameState state) =>
    kSewaPerHari + (state.branchCount > 1 ? kSewaCabangPerHari : 0);

class WartegPaletteColors {
  WartegPaletteColors._();
  static Color hari(DailyReport r) =>
      r.profit >= 0 ? WartegColors.green : WartegColors.brick;
}
