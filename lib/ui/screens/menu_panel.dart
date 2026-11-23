/// Panel "Menu & Harga": atur harga jual dan masak porsi.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/models/menu_item.dart';
import '../../features/game_controller.dart';
import '../panel_route.dart';
import '../theme.dart';
import '../widgets.dart';

class MenuPanel extends ConsumerStatefulWidget {
  const MenuPanel({super.key});

  @override
  ConsumerState<MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends ConsumerState<MenuPanel> {
  MenuCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    final menu = kMenu
        .where((m) => _filter == null || m.category == _filter)
        .toList()
      ..sort((a, b) => a.unlockLevel.compareTo(b.unlockLevel));

    return Column(
      children: [
        PanelHeader(
          icon: Icons.restaurant_menu_rounded,
          title: 'Menu & Harga',
          subtitle: 'Harga murah = laris, tapi jaga margin',
          onClose: () => tutupPanel(context),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _chip('Semua', null),
              for (final c in MenuCategory.values) _chip(c.label, c),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            itemCount: menu.length,
            itemBuilder: (context, i) {
              final m = menu[i];
              final terkunci = state.level < m.unlockLevel;
              final harga = state.priceOf(m.id);
              final porsiEtalase = state.dishBatches
                  .where((b) => b.menuId == m.id)
                  .fold<int>(0, (a, b) => a + b.qty);
              final bahanKurang = m.recipe.entries
                  .any((e) => state.stockOf(e.key) < e.value);

              return Card(
                child: Opacity(
                  opacity: terkunci ? 0.55 : 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(m.colorArgb),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(color: const Color(0x33A8702F)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          m.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800, fontSize: 14.5),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (m.hotDrink)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.local_cafe_rounded,
                                              size: 14, color: WartegColors.brick),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    '${m.category.label} • modal ${rupiah(m.modalBahan)} • '
                                    'masak ${m.cookMinutes} mnt',
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0x993B2414)),
                                  ),
                                ],
                              ),
                            ),
                            if (terkunci)
                              StatusChip(
                                icon: Icons.lock_rounded,
                                label: 'Lv ${m.unlockLevel}',
                                color: WartegColors.brown,
                              )
                            else
                              StatusChip(
                                icon: Icons.inventory_2_rounded,
                                label: '$porsiEtalase porsi',
                                color: porsiEtalase > 0
                                    ? WartegColors.green
                                    : WartegColors.brick,
                              ),
                          ],
                        ),
                        if (!terkunci) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SizedBox(
                                width: 92,
                                child: Text(
                                  rupiah(harga),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: WartegColors.brickDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: harga.toDouble().clamp(
                                        (m.basePrice * 0.4),
                                        (m.basePrice * 2.5),
                                      ),
                                  min: m.basePrice * 0.4,
                                  max: m.basePrice * 2.5,
                                  divisions: 42,
                                  onChanged: (v) => controller.ubahHarga(m.id, v.round()),
                                ),
                              ),
                            ],
                          ),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Margin ${rupiah(harga - m.modalBahan)}/porsi',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: harga - m.modalBahan > 0
                                      ? WartegColors.green
                                      : WartegColors.brick,
                                ),
                              ),
                              Wrap(
                                spacing: 6,
                                children: [
                                  for (final n in [1, 3, 5])
                                    MiniButton(
                                      label: '+$n',
                                      icon: Icons.soup_kitchen_rounded,
                                      aktif: !bahanKurang,
                                      onPressed: () => controller.masak(m.id, n),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (bahanKurang)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Bahan kurang — belanja dulu di panel Stok.',
                                style: TextStyle(fontSize: 11, color: WartegColors.brick),
                              ),
                            ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Terbuka di level ${m.unlockLevel}. Terus layani pelanggan '
                              'untuk naik level!',
                              style: const TextStyle(fontSize: 11.5, color: Color(0x993B2414)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, MenuCategory? kategori) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == kategori,
        onSelected: (_) => setState(() => _filter = kategori),
      ),
    );
  }
}
