import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/workspace_controller.dart';
import '../domain/alarm_plan.dart';
import 'design_system.dart';

/// Fullscreen Cyber-Transit HUD Alarm Overlay.
/// Displays high-contrast glowing dispatch telemetry when an alarm is triggered.
class ForegroundAlarmOverlay extends ConsumerStatefulWidget {
  const ForegroundAlarmOverlay({super.key});
  @override
  ConsumerState<ForegroundAlarmOverlay> createState() =>
      _ForegroundAlarmOverlayState();
}

class _ForegroundAlarmOverlayState
    extends ConsumerState<ForegroundAlarmOverlay> {
  final seen = <String>{};
  final active = <String, ({AlarmEvent event, DateTime shownAt})>{};
  DateTime? last;

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceProvider.select((s) => s.workspace));
    final now = (ref.watch(clockProvider).value ?? DateTime.now()).toUtc();
    if (last != null && now.isBefore(last!)) {
      seen.clear();
      active.clear();
    }
    last = now;
    final routes = {for (final r in workspace.routes) r.id: r};
    active.removeWhere((_, a) {
      final r = routes[a.event.routeId];
      return r == null ||
          !r.participates ||
          !r.alarmEnabled ||
          !r.alerts.fullScreen ||
          !(a.event.stage == 'prep'
              ? r.alerts.preparation
              : r.alerts.departure) ||
          workspace.hasDeparted(a.event.departureId) ||
          workspace.hasAcknowledged(a.event.departureId) ||
          !now.isBefore(
            a.shownAt.add(Duration(seconds: r.alarmDuration.clamp(1, 300))),
          );
    });
    for (final e in buildAlarmPlan(
      workspace,
      now.subtract(const Duration(seconds: 301)),
    )) {
      if (!e.preferences.fullScreen ||
          e.at.isAfter(now) ||
          seen.contains(e.key)) {
        continue;
      }
      seen.add(e.key);
      if ((e.stage == 'prep' && !now.isBefore(e.departureAt)) ||
          (e.stage == 'due' &&
              now.difference(e.at) >= const Duration(minutes: 1))) {
        continue;
      }
      if (e.stage == 'due') {
        active.removeWhere(
          (_, a) =>
              a.event.departureId == e.departureId && a.event.stage == 'prep',
        );
      }
      active[e.key] = (event: e, shownAt: now);
    }
    if (active.isEmpty) return const SizedBox.shrink();
    final items = active.values.toList()
      ..sort((a, b) {
        final stage = (a.event.stage == 'due' ? 0 : 1).compareTo(
          b.event.stage == 'due' ? 0 : 1,
        );
        return stage != 0 ? stage : a.event.at.compareTo(b.event.at);
      });
    final item = items.first;
    final event = item.event;
    final route = routes[event.routeId]!;
    final revisions = {
      for (final r in workspace.history) r.id: r,
      for (final r in workspace.routes)
        if (r.schedule != null) r.schedule!.id: r.schedule!,
    };
    final revision = revisions[event.revisionId];
    if (revision == null) return const SizedBox.shrink();
    final row = revision.departures
        .where((d) => d.id == event.departureId)
        .first;
    final durationSec = route.alarmDuration.clamp(1, 300);
    final remainingMillis = item.shownAt
        .add(Duration(seconds: durationSec))
        .difference(now)
        .inMilliseconds;
    final seconds = (remainingMillis / 1000).ceil().clamp(0, durationSec);
    final timeoutProgress = (remainingMillis / (durationSec * 1000)).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = context.hedge;
    final isDue = event.stage == 'due';
    final accentColor = isDue ? p.amberInk : p.cyanInk;

    return Positioned.fill(
      child: Material(
        key: const ValueKey('fullscreen-alarm'),
        color: isDark ? const Color(0xFF070B12) : const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Cyber Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'HEDGE',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: isDark ? Colors.white : p.text,
                            ),
                          ),
                        ),
                        if (items.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.amberInk.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${items.length} alert aktif',
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: p.amberInk,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Headway Generator · By Mikrotrans Utara',
                      style: TextStyle(
                        fontFamily: HedgeTokens.cyberFont,
                        fontSize: 11,
                        color: p.muted,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Neon Timeout Energy Gauge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: timeoutProgress,
                        minHeight: 3,
                        backgroundColor: isDark ? const Color(0xFF141A24) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable Center Cockpit Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      // Card Telemetri Utama
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF080D16) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: accentColor.withValues(alpha: isDark ? 0.5 : 0.6),
                            width: 1.5,
                          ),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.15),
                                    blurRadius: 24,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Column(
                          children: [
                            // 1. Status Capsule Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF05080E)
                                    : (isDue ? p.warningSurface : p.focusSurface),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: isDark ? 0.7 : 0.8),
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                isDue ? '● WAKTU BERANGKAT' : '● BERSIAP BERANGKAT',
                                style: TextStyle(
                                  fontFamily: HedgeTokens.cyberFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 2. Monolith Fleet Unit Identifier (72sp)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                row.unitNumber,
                                style: TextStyle(
                                  fontFamily: HedgeTokens.cyberFont,
                                  fontSize: 72,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  height: 1.0,
                                  color: isDark ? Colors.white : p.text,
                                  shadows: isDark
                                      ? [
                                          Shadow(
                                            color: accentColor.withValues(alpha: 0.5),
                                            blurRadius: 18,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Giant Chrono-Dial Radar (220dp)
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(220, 220),
                                    painter: CockpitDialPainter(
                                      accentColor: accentColor,
                                      isDark: isDark,
                                      timeoutProgress: timeoutProgress,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isDue ? 'Waktu berangkat' : 'Bersiap berangkat',
                                            style: TextStyle(
                                              fontFamily: HedgeTokens.cyberFont,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatCountdown(isDue, event.departureAt, now),
                                            style: TextStyle(
                                              fontFamily: HedgeTokens.cyberFont,
                                              fontSize: 40,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.5,
                                              color: accentColor,
                                              fontFeatures: HedgeTokens.numberFeatures,
                                              shadows: isDark
                                                  ? [
                                                      Shadow(
                                                        color: accentColor.withValues(alpha: 0.6),
                                                        blurRadius: 14,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4. Live Mission Telemetry Grid (3 Cards)
                            Row(
                              children: [
                                Expanded(
                                  child: _TelemetryCard(
                                    icon: Icons.schedule_rounded,
                                    label: 'JADWAL',
                                    value:
                                        '${event.departureAt.toLocal().hour.toString().padLeft(2, '0')}:${event.departureAt.toLocal().minute.toString().padLeft(2, '0')} WIB',
                                    accentColor: accentColor,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TelemetryCard(
                                    icon: Icons.directions_bus_rounded,
                                    label: 'RUTE',
                                    value: route.name,
                                    accentColor: accentColor,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _TelemetryCard(
                                    icon: Icons.sync_rounded,
                                    label: 'PUTARAN',
                                    value: 'RITASE ${row.round}',
                                    accentColor: accentColor,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Timeout Indicator Pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0C1017) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : p.border,
                          ),
                        ),
                        child: Text(
                          'Menutup otomatis dalam ${seconds.clamp(0, 300)} detik',
                          key: const ValueKey('alert-timeout'),
                          style: TextStyle(
                            fontFamily: HedgeTokens.cyberFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontFeatures: HedgeTokens.numberFeatures,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (items.length > 1) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${items.length} alert aktif',
                          style: TextStyle(fontSize: 11, color: p.muted),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        'Sudah Berangkat mencatat aktual. Timeout hanya menutup alert.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions (Cyberpunk HUD Controls)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Primary Amber Glowing Button
                    Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(alpha: isDark ? 0.35 : 0.2),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: ref.watch(workspaceProvider).saving
                            ? null
                            : () => ref
                                  .read(workspaceProvider.notifier)
                                  .record(revision, row, 'departed'),
                        icon: const Icon(Icons.check_circle_rounded, size: 20, color: Colors.black),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Sudah Berangkat',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tutup Alert Sementara (Dismiss Button)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFFF8FAFC) : p.text,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : p.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: () {
                        setState(() {
                          active.remove(event.key);
                        });
                      },
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Tutup Alert',
                          style: TextStyle(
                            fontFamily: HedgeTokens.cyberFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Matikan Alarm Rute
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.muted,
                        side: BorderSide(
                          color: isDark ? const Color(0xFF1E293B) : p.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size.fromHeight(38),
                      ),
                      onPressed: ref.watch(workspaceProvider).saving
                          ? null
                          : () => ref
                                .read(workspaceProvider.notifier)
                                .updateRoute(
                                  route.copyWith(alarmEnabled: false),
                                ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Matikan alarm rute'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCountdown(bool isDue, DateTime departureAt, DateTime now) {
    final diffSecs = now.difference(departureAt).inSeconds;
    if (isDue && diffSecs > 0) {
      final mins = (diffSecs ~/ 60).toString().padLeft(2, '0');
      final secs = (diffSecs % 60).toString().padLeft(2, '0');
      return '+$mins:$secs';
    } else {
      final left = departureAt.difference(now).inSeconds.clamp(0, 86400);
      final mins = (left ~/ 60).toString().padLeft(2, '0');
      final secs = (left % 60).toString().padLeft(2, '0');
      return '$mins:$secs';
    }
  }
}

class CockpitDialPainter extends CustomPainter {
  const CockpitDialPainter({
    required this.accentColor,
    required this.isDark,
    required this.timeoutProgress,
  });

  final Color accentColor;
  final bool isDark;
  final double timeoutProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // 1. Outer Timeout Arc Gauge (shrinking with remaining timeout)
    final arcPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * timeoutProgress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );

    // 2. Outer Track Background (subtle full circle)
    final trackPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.15 : 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, radius, trackPaint);

    // 3. Inner Solid Background Plate
    final platePaint = Paint()
      ..color = isDark ? const Color(0xFF0A0F18) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 8, platePaint);

    // 4. Concentric Tech Ring
    final ringPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.4 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 8, ringPaint);

    // 5. Tick Marks around the circumference (12 ticks like a clock radar)
    final tickPaint = Paint()
      ..color = accentColor.withValues(alpha: isDark ? 0.6 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final p1 = Offset(
        center.dx + (radius - 16) * math.cos(angle),
        center.dy + (radius - 16) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 6. Top Notch Indicator Dot
    final notchPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius),
      4.0,
      notchPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CockpitDialPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.timeoutProgress != timeoutProgress;
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF050911) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF192231) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: HedgeTokens.cyberFont,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
