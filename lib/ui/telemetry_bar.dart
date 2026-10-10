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
              label: headwayMinutes > 0
                  ? 'Headway ${headwayMinutes}m'
                  : 'Ritase Terakhir',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF090E17) : background;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.6 : 0.7),
          width: 1.1,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent,
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: HedgeTokens.cyberFont,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
              color: isDark ? Colors.white : p.text,
              fontFeatures: HedgeTokens.numberFeatures,
            ),
          ),
        ],
      ),
    );
  }
}
