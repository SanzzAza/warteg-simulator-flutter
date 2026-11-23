/// Panel Stok: belanja bahan, lihat batch & kesegaran masakan, antrean masak.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/models/game_state.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/menu_item.dart';
import '../../features/game_controller.dart';
import '../panel_route.dart';
import '../theme.dart';
import '../widgets.dart';

class StockPanel extends ConsumerStatefulWidget {
  const StockPanel({super.key});

  @override
  ConsumerState<StockPanel> createState() => _StockPanelState();
}

class _StockPanelState extends ConsumerState<StockPanel> {
  int _tab = 0;
  int _qtyBeli = 5;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);

    return Column(
      children: [
        PanelHeader(
          icon: Icons.inventory_2_rounded,
          title: 'Stok & Dapur',
          subtitle: 'Belanja bahan, pantau kesegaran',
          onClose: () => tutupPanel(context),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Belanja'), icon: Icon(Icons.shopping_basket_rounded, size: 16)),
                    ButtonSegment(value: 1, label: Text('Etalase'), icon: Icon(Icons.bakery_dining_rounded, size: 16)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (_tab == 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Jumlah beli:', style: kWartegLabel),
                for (final q in [1, 5, 10, 20])
                  ChoiceChip(
                    label: Text('$q'),
                    selected: _qtyBeli == q,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) => setState(() => _qtyBeli = q),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: WartegColors.green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rupiah(state.money),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: WartegColors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: _tab == 0 ? _daftarBelanja(state) : _daftarEtalase(state),
        ),
      ],
    );
  }

  Widget _daftarBelanja(GameState state) {
    final controller = ref.read(gameControllerProvider.notifier);
    final bahan = daftarBahan;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      itemCount: bahan.length + 1,
      itemBuilder: (context, i) {
        if (i == bahan.length) return _antreanMasak(state);
        final b = bahan[i];
        final stok = state.stockOf(b.id);
        final total = b.buyPrice * _qtyBeli;
        final mampu = state.money >= total;
        // Batch terdekat kedaluwarsa.
        final batches = state.ingredientBatches
            .where((x) => x.ingredientId == b.id)
            .toList()
          ..sort((IngredientBatch a, IngredientBatch c) => a.expiryDay.compareTo(c.expiryDay));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stok > 0 ? WartegColors.green : WartegColors.creamDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      Text(
                        'Stok $stok • ${rupiah(b.buyPrice)}/${b.unit} • '
                        'awet ${b.shelfLifeDays} hari',
                        style: const TextStyle(fontSize: 11, color: Color(0x993B2414)),
                      ),
                      if (batches.isNotEmpty)
                        Text(
                          'Batch terlama kedaluwarsa hari ke-${batches.first.expiryDay}'
                          '${batches.first.expiryDay <= state.day + 1 ? " ⚠️" : ""}',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: batches.first.expiryDay <= state.day + 1
                                ? WartegColors.brick
                                : const Color(0x883B2414),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'biaya ${rupiah(total)}',
                      style: const TextStyle(fontSize: 11, color: Color(0x993B2414)),
                    ),
                    const SizedBox(height: 2),
                    MiniButton(
                      label: '+$_qtyBeli',
                      icon: Icons.add_shopping_cart_rounded,
                      aktif: mampu,
                      onPressed: () => controller.beliBahan(b.id, _qtyBeli),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _antreanMasak(GameState state) {
    if (state.cookingQueue.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Text(
          'Tidak ada masakan di antrean.\nMasak dari panel "Menu & Harga".',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0x993B2414)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('Sedang dimasak', style: TextStyle(fontWeight: FontWeight.w800, color: WartegColors.brickDark)),
        const SizedBox(height: 6),
        for (final job in state.cookingQueue)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${menuById(job.menuId)?.name ?? job.menuId} × ${job.portions} porsi',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    WartegProgressBar(
                      value: job.totalMinutes == 0 ? 1 : job.progress / job.totalMinutes,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _daftarEtalase(GameState state) {
    final dish = state.dishBatches;
    if (dish.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Etalase kosong.\nMasak dulu dari panel "Menu & Harga".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0x993B2414)),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Kapasitas ${state.dishCount}/${state.displayCapacity} porsi • '
            'Kesegaran turun ${state.freshnessDecayPerHour.toStringAsFixed(1)}/jam',
            style: const TextStyle(fontSize: 11.5, color: Color(0x993B2414)),
          ),
        ),
        for (final b in dish)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    b.freshness > 55
                        ? Icons.egg_alt_rounded
                        : b.freshness > 25
                            ? Icons.warning_amber_rounded
                            : Icons.dangerous_rounded,
                    color: b.freshness > 55
                        ? WartegColors.green
                        : b.freshness > 25
                            ? const Color(0xFFE0A200)
                            : WartegColors.brick,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${menuById(b.menuId)?.name ?? b.menuId} × ${b.qty}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        WartegProgressBar(
                          value: b.freshness / 100,
                          color: b.freshness > 55
                              ? WartegColors.green
                              : b.freshness > 25
                                  ? const Color(0xFFE0A200)
                                  : WartegColors.brick,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${b.freshness.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
