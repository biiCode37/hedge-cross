import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'design_system.dart';

/// Cyber-Transit Timeline Schedule View.
/// Menggambar rel transit vertikal menyambungkan status armada (Departed, Live, Upcoming)
/// 100% sesuai dengan desain Mockup Resmi Cyber-Transit HUD.
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
    final activeColor = focused ? p.cyanInk : p.amberInk;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kolom Waktu (Kiri Rel)
              SizedBox(
                width: 48,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    formatMinute(departure.minute),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 13,
                      fontWeight: focused ? FontWeight.w900 : FontWeight.w700,
                      letterSpacing: 0.5,
                      color: focused
                          ? p.cyanInk
                          : (done ? p.muted : (isDark ? const Color(0xFFCBD5E1) : p.text)),
                      fontFeatures: HedgeTokens.numberFeatures,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Garis Rel Transit Vertikal & Node Konsentris Bercahaya (Tengah)
              SizedBox(
                width: 28,
                child: CustomPaint(
                  painter: TransitRailPainter(
                    isFirst: isFirst,
                    isLast: isLast,
                    done: done,
                    focused: focused,
                    activeColor: activeColor,
                    mutedColor: p.muted,
                    railColor: isDark ? const Color(0xFF1E293B) : p.border,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Konten Unit & Status Futuristik (Kanan Rel - Tanpa Card Biasa)
              Expanded(
                child: InkWell(
                  onTap: done ? null : onRecord,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Baris Badge Status Futuristik
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (focused)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF001F29)
                                      : p.focusSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: p.cyanInk,
                                    width: 1.2,
                                  ),
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color: p.cyanInk.withValues(alpha: 0.35),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: p.cyanInk,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'WAKTU BERANGKAT',
                                        style: TextStyle(
                                          fontFamily: HedgeTokens.cyberFont,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: p.cyanInk,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'AKTIF',
                                        style: TextStyle(
                                          fontFamily: HedgeTokens.cyberFont,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                          color: p.cyanInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (done)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF261500)
                                      : p.warningSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: p.amberInk,
                                    width: 1.2,
                                  ),
                                  boxShadow: isDark
                                      ? [
                                          BoxShadow(
                                            color: p.amberInk.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: p.amberInk,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'SUDAH BERANGKAT',
                                        style: TextStyle(
                                          fontFamily: HedgeTokens.cyberFont,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: p.amberInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : p.raised,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: p.border.withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'STANDBY',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: p.muted,
                                  ),
                                ),
                              ),
                            Text(
                              'R${departure.round} · ${departure.nextGap == null ? 'Terakhir' : '${departure.nextGap}m'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: p.muted,
                              ),
                            ),
                            if (departure.peak)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: p.cyanInk.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: p.cyanInk.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  'PEAK',
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: p.cyanInk,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),

                        // Nomor Unit Raksasa Futuristik
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            departure.unitNumber,
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 26,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: done
                                  ? (isDark ? const Color(0xFF64748B) : p.muted)
                                  : (isDark ? Colors.white : p.text),
                              fontFeatures: HedgeTokens.numberFeatures,
                              shadows: (focused && isDark)
                                  ? [
                                      Shadow(
                                        color: p.cyanInk.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
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
                ),
              ),

              // Trailing Action (Centang Semantik / Tombol Catat)
              if (done)
                Semantics(
                  label: 'Keberangkatan aktual tercatat',
                  container: true,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF261500)
                          : p.warningSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: p.amberInk.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: p.amberInk.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
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
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: focused
                          ? (isDark ? const Color(0xFF001F29) : p.focusSurface)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: focused
                            ? p.cyanInk
                            : p.border.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.done,
                      size: 16,
                      color: focused ? p.cyanInk : p.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter untuk rel transit vertikal bercahaya.
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
    final nodeRadius = focused ? 8.0 : (done ? 7.0 : 6.0);

    // Rel Garis Atas
    if (!isFirst) {
      final topColor = (done || focused) ? activeColor : railColor;
      final topPaint = Paint()
        ..color = topColor.withValues(alpha: (done || focused) ? 0.9 : 0.4)
        ..strokeWidth = (done || focused) ? 3.0 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(centerX, 0),
        Offset(centerX, centerY - nodeRadius - 3),
        topPaint,
      );

      // Pendaran rel atas
      if (done || focused) {
        final topGlow = Paint()
          ..color = topColor.withValues(alpha: 0.3)
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawLine(
          Offset(centerX, 0),
          Offset(centerX, centerY - nodeRadius - 3),
          topGlow,
        );
      }
    }

    // Rel Garis Bawah
    if (!isLast) {
      if (!done && !focused) {
        _drawDashedLine(
          canvas,
          Offset(centerX, centerY + nodeRadius + 3),
          Offset(centerX, size.height),
          railColor.withValues(alpha: 0.4),
        );
      } else {
        final bottomColor = done ? activeColor : railColor;
        final bottomPaint = Paint()
          ..color = bottomColor.withValues(alpha: done ? 0.9 : 0.4)
          ..strokeWidth = done ? 3.0 : 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(centerX, centerY + nodeRadius + 3),
          Offset(centerX, size.height),
          bottomPaint,
        );

        if (done) {
          final bottomGlow = Paint()
            ..color = bottomColor.withValues(alpha: 0.3)
            ..strokeWidth = 6.0
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawLine(
            Offset(centerX, centerY + nodeRadius + 3),
            Offset(centerX, size.height),
            bottomGlow,
          );
        }
      }
    }

    // Transit Node Konsentris Bercahaya
    if (focused) {
      // Outer aura glow
      final auraPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius + 6, auraPaint);

      // Outer ring
      final ringPaint = Paint()
        ..color = activeColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius + 2, ringPaint);

      // Inner solid node
      final nodePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius - 2, nodePaint);

      // Center white core
      final corePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), 2.5, corePaint);
    } else if (done) {
      // Outer aura glow
      final auraPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius + 4, auraPaint);

      // Outer amber ring
      final ringPaint = Paint()
        ..color = activeColor
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius + 1.5, ringPaint);

      // Inner solid amber dot
      final nodePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(centerX, centerY), nodeRadius - 2, nodePaint);
    } else {
      // Hollow circle untuk upcoming
      final nodePaint = Paint()
        ..color = railColor
        ..strokeWidth = 1.8
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
      itemBuilder: (_, i) {
        final d = departures[i];
        return CyberTimelineTile(
          departure: d,
          done: hasDeparted(d.id),
          focused: d.id == focusedDepartureId,
          frozen: d.ordinal <= frozenCount,
          isFirst: i == 0,
          isLast: i == departures.length - 1,
          onRecord: () => onRecord(d),
        );
      },
    );
  }
}
