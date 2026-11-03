import 'package:flutter/material.dart';

class BatteryBadge extends StatelessWidget {
  const BatteryBadge({
    super.key,
    required this.percent,
    required this.isCharging,
  });

  final int percent;
  final bool isCharging;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = percent <= 20
        ? scheme.error
        : isCharging
        ? const Color(0xFF6F9E62)
        : scheme.onSurfaceVariant;

    return Tooltip(
      message: isCharging ? 'Charging · $percent%' : 'Battery · $percent%',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(percent, isCharging), size: 15, color: color),
          const SizedBox(width: 3),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(int percent, bool isCharging) {
    if (isCharging) return Icons.battery_charging_full_rounded;
    if (percent >= 95) return Icons.battery_full_rounded;
    if (percent >= 80) return Icons.battery_6_bar_rounded;
    if (percent >= 65) return Icons.battery_5_bar_rounded;
    if (percent >= 50) return Icons.battery_4_bar_rounded;
    if (percent >= 35) return Icons.battery_3_bar_rounded;
    if (percent >= 20) return Icons.battery_2_bar_rounded;
    if (percent >= 8) return Icons.battery_1_bar_rounded;
    return Icons.battery_0_bar_rounded;
  }
}
