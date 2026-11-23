/// Widget kecil yang dipakai berulang di seluruh UI.
library;

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Kartu statistik kecil (label kecil di atas, nilai besar).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = WartegColors.brickDark,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 6 : 10),
      decoration: BoxDecoration(
        color: WartegColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33A8702F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: compact ? 13 : 15, color: color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: kWartegLabel.copyWith(fontSize: compact ? 10 : 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 13 : 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip status berikon untuk HUD.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = WartegColors.brickDark,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WartegColors.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33A8702F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }
}

/// Bintang reputasi berwarna kuning.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.value, this.size = 14});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final selisih = value - i;
        final icon = selisih >= 0.75
            ? Icons.star
            : selisih >= 0.25
                ? Icons.star_half
                : Icons.star_border;
        return Icon(icon, size: size, color: const Color(0xFFE0A200));
      }),
    );
  }
}

/// Bar progress bertema (XP, kesegaran, dsb).
class WartegProgressBar extends StatelessWidget {
  const WartegProgressBar({
    super.key,
    required this.value,
    this.color = WartegColors.orange,
    this.height = 8,
    this.background,
  });

  final double value;
  final Color color;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: background ?? const Color(0x22A8702F),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// Baris label + nilai.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xBB3B2414))),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color ?? WartegColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header panel manajemen dengan ikon + judul + aksi tutup.
class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onClose,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: WartegColors.orangeSoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: WartegColors.brickDark, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: WartegColors.brickDark),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 11.5, color: Color(0x993B2414)),
                  ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: WartegColors.brickDark,
              tooltip: 'Tutup',
            ),
        ],
      ),
    );
  }
}

/// Tombol kecil bermerek.
class MiniButton extends StatelessWidget {
  const MiniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = WartegColors.brick,
    this.aktif = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: aktif ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      icon: icon == null ? null : Icon(icon, size: 15),
      label: Text(label),
    );
  }
}
