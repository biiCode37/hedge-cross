import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'design_system.dart';

/// Cyber-Transit Timeline Schedule View.
/// Menggambar rel transit vertikal menyambungkan status armada (Departed, Live, Upcoming).
class CyberTimelineTile extends StatelessWidget {
  const CyberTimelineTile({
    super.key,
    required this.departure,
    required this.done,
    required this.focused,
    required this.frozen,
    required this.isFirst,
    required this.isLast,
    required this.onRecord,
  });

  final Departure departure;
  final bool done;
  final bool focused;
  final bool frozen;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: CustomPaint(
                painter: TransitRailPainter(
                  isFirst: isFirst,
                  isLast: isLast,
                  done: done,
                  focused: focused,
                  activeColor: focused ? p.cyanInk : p.amberInk,
                  mutedColor: p.muted,
                  railColor: p.border,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: focused
                      ? (isDark ? const Color(0xFF0C141F) : p.focusSurface)
                      : (isDark ? const Color(0xFF0C1017) : p.surface),
                  borderRadius: BorderRadius.circular(HedgeTokens.radius),
                  border: Border.all(
                    color: focused
                        ? p.cyanInk.withValues(alpha: .6)
                        : (done ? p.border.withValues(alpha: .4) : p.border),
                    width: focused ? 1.5 : 1.0,
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: p.cyanInk.withValues(alpha: .12),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'UNIT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: p.muted,
                                  ),
                                ),
                                if (focused) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.cyanInk.withValues(alpha: .15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .6,
                                        color: p.cyanInk,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            departure.unitNumber,
                            style: TextStyle(
                              fontSize: 22,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.3,
                              color: done ? p.muted : p.text,
                              fontFeatures: HedgeTokens.numberFeatures,
                            ),
                          ),
                          if (frozen)
                            Text(
                              'Histori rencana',
                              style: TextStyle(fontSize: 10, color: p.muted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatMinute(departure.minute),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: done ? p.muted : p.text,
                              fontFeatures: HedgeTokens.numberFeatures,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'R${departure.round} · ${departure.nextGap == null ? 'Terakhir' : '${departure.nextGap}m'}',
                            style: TextStyle(fontSize: 12, color: p.muted),
                          ),
                          if (departure.peak)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'PEAK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: p.cyanInk,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (done)
                      Semantics(
                        label: 'Keberangkatan aktual tercatat',
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: p.focusSurface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: p.amberInk.withValues(alpha: .5),
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: p.amberInk,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Catat keberangkatan aktual',
                        onPressed: onRecord,
                        icon: Icon(
                          Icons.done,
                          color: focused ? p.cyanInk : p.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter untuk rel transit vertikal.
class TransitRailPainter extends CustomPainter {
  const TransitRailPainter({
    required this.isFirst,
    required this.isLast,
    required this.done,
    required this.focused,
    required this.activeColor,
    required this.mutedColor,
    required this.railColor,
  });

  final bool isFirst;
  final bool isLast;
  final bool done;
  final bool focused;
  final Color activeColor;
  final Color mutedColor;
  final Color railColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final nodeRadius = focused ? 7.0 : (done ? 6.0 : 5.0);

    // Top connecting line
    if (!isFirst) {
      final topPaint = Paint()
        ..color = (done || focused) ? activeColor.withValues(alpha: .7) : railColor
        ..strokeWidth = (done || focused) ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, centerY - nodeRadius - 2),
        topPaint,
      );
    }

    // Bottom connecting line
    if (!isLast) {
      if (!done && !focused) {
        // Dashed line for upcoming schedule
        _drawDashedLine(
          canvas,
          Offset(centerX, centerY + nodeRadius + 2),
          Offset(centerX, size.height),
          railColor,
        );
      } else {
        final bottomPaint = Paint()
          ..color = done ? activeColor.withValues(alpha: .7) : railColor
          ..strokeWidth = done ? 2.5 : 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(centerX, centerY + nodeRadius + 2),
          Offset(centerX, size.height),
          bottomPaint,
        );
      }
    }

    // Transit Node
    if (focused) {
      // Outer aura glow
      final auraPaint = Paint()
        ..color = activeColor.withValues(alpha: .25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius + 5, auraPaint);

      final nodePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius, nodePaint);

      final innerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), 2.5, innerDot);
    } else if (done) {
      final nodePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius, nodePaint);
    } else {
      final nodePaint = Paint()
        ..color = railColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius, nodePaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    var startY = p1.dy;
    while (startY < p2.dy) {
      final endY = (startY + dashHeight).clamp(p1.dy, p2.dy);
      canvas.drawLine(Offset(p1.dx, startY), Offset(p1.dx, endY), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TransitRailPainter oldDelegate) =>
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast ||
      oldDelegate.done != done ||
      oldDelegate.focused != focused ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.railColor != railColor;
}

/// Standalone ListView builder for Cyber Timeline.
class CyberTimelineList extends StatelessWidget {
  const CyberTimelineList({
    super.key,
    required this.departures,
    required this.hasDeparted,
    this.focusedDepartureId,
    required this.frozenCount,
    required this.onRecord,
  });

  final List<Departure> departures;
  final bool Function(String id) hasDeparted;
  final String? focusedDepartureId;
  final int frozenCount;
  final void Function(Departure d) onRecord;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: departures.length,
      itemBuilder: (context, index) {
        final d = departures[index];
        return CyberTimelineTile(
          key: ValueKey('timeline-row:${d.id}'),
          departure: d,
          done: hasDeparted(d.id),
          focused: d.id == focusedDepartureId,
          frozen: d.ordinal <= frozenCount,
          isFirst: index == 0,
          isLast: index == departures.length - 1,
          onRecord: () => onRecord(d),
        );
      },
    );
  }
}

/// SliverList builder for Cyber Timeline di dalam CustomScrollView.
class SliverCyberTimelineList extends StatelessWidget {
  const SliverCyberTimelineList({
    super.key,
    required this.departures,
    required this.hasDeparted,
    this.focusedDepartureId,
    required this.frozenCount,
    required this.onRecord,
  });

  final List<Departure> departures;
  final bool Function(String id) hasDeparted;
  final String? focusedDepartureId;
  final int frozenCount;
  final void Function(Departure d) onRecord;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: departures.length,
      itemBuilder: (context, index) {
        final d = departures[index];
        return CyberTimelineTile(
          key: ValueKey('schedule-row:${d.id}'),
          departure: d,
          done: hasDeparted(d.id),
          focused: d.id == focusedDepartureId,
          frozen: d.ordinal <= frozenCount,
          isFirst: index == 0,
          isLast: index == departures.length - 1,
          onRecord: () => onRecord(d),
        );
      },
    );
  }
}
