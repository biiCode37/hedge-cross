import 'package:flutter/material.dart';
import 'design_system.dart';

/// Bar kapsul telemetri armada di bagian atas jadwal operasional.
class FleetTelemetryPillBar extends StatelessWidget {
  const FleetTelemetryPillBar({
    super.key,
    required this.activeUnits,
    required this.currentRound,
    required this.totalRounds,
    required this.headwayMinutes,
  });

  final int activeUnits;
  final int currentRound;
  final int totalRounds;
  final int headwayMinutes;

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pill(
              icon: Icons.directions_bus_rounded,
              label: '$activeUnits Unit Aktif',
              accent: p.cyanInk,
              background: p.focusSurface,
            ),
            const SizedBox(width: 8),
            _Pill(
              icon: Icons.sync_rounded,
              label: totalRounds > 0
                  ? 'Ritase $currentRound/$totalRounds'
                  : 'Ritase $currentRound',
              accent: p.muted,
              background: p.raised,
            ),
            const SizedBox(width: 8),
            _Pill(
              icon: Icons.timelapse_rounded,
              label: 'Headway ${headwayMinutes}m',
              accent: p.amberInk,
              background: p.warningSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(HedgeTokens.radius),
        border: Border.all(color: accent.withValues(alpha: .35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
              color: p.text,
              fontFeatures: HedgeTokens.numberFeatures,
            ),
          ),
        ],
      ),
    );
  }
}
