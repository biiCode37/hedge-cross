import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/dispatch_focus.dart';
import '../application/workspace_controller.dart';
import '../domain/models.dart';
import 'design_system.dart';
import 'schedule_timeline.dart';

class DepartureFocusPanel extends StatefulWidget {
  const DepartureFocusPanel({
    super.key,
    required this.focus,
    this.large = false,
    this.onDispatch,
  });

  final DispatchFocus focus;
  final bool large;
  final VoidCallback? onDispatch;

  @override
  State<DepartureFocusPanel> createState() => _DepartureFocusPanelState();
}

class _DepartureFocusPanelState extends State<DepartureFocusPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.focus.due ? p.amberInk : p.cyanInk;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          final pulse = _pulseAnimation.value;
          final glowOpacity = (0.35 + 0.35 * pulse).clamp(0.0, 1.0);
          final cardBg = isDark ? const Color(0xFF0A0F18) : p.surface;

          return CustomPaint(
            painter: CyberHudFramePainter(
              color: accent,
              pulse: pulse,
              isDark: isDark,
              isDue: widget.focus.due,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(HedgeTokens.panelRadius),
                border: Border.all(
                  color: accent.withValues(
                    alpha: isDark ? (0.5 + 0.45 * pulse) : 0.8,
                  ),
                  width: widget.focus.due ? 2.0 : 1.5,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: glowOpacity * 0.45),
                          blurRadius: 18 + 8 * pulse,
                          spreadRadius: 1 + 1.5 * pulse,
                        ),
                        BoxShadow(
                          color: accent.withValues(alpha: glowOpacity * 0.2),
                          blurRadius: 36 + 10 * pulse,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.large ? 24 : 14,
                vertical: widget.large ? 18 : 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge Kapsul Status di Atas
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF060B12) : (widget.focus.due ? p.warningSurface : p.focusSurface),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? (0.6 + 0.4 * pulse) : 0.6),
                        width: 1.2,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35 * pulse),
                                blurRadius: 8 * pulse,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.7 + 0.3 * pulse),
                                blurRadius: 6 * pulse,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.focus.due
                                  ? 'WAKTU BERANGKAT'
                                  : 'KEBERANGKATAN BERIKUTNYA',
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nomor Unit Raksasa Terpusat
                  Semantics(
                    sortKey: const OrdinalSortKey(1),
                    label: 'Nomor unit ${widget.focus.departure.unitNumber}',
                    excludeSemantics: true,
                    child: Text(
                      widget.focus.departure.unitNumber,
                      key: const ValueKey('focus-unit'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: HedgeTokens.cyberFont,
                        fontSize: widget.large ? 64 : 44,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: p.text,
                        fontFeatures: HedgeTokens.numberFeatures,
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: accent.withValues(alpha: 0.45 * pulse),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Centerpiece Circular Countdown HUD Gauge
                  CountdownIndicator(
                    at: plannedInstant(
                      widget.focus.revision.date,
                      widget.focus.departure.minute,
                    ),
                    large: widget.large,
                    pulse: pulse,
                  ),
                  const SizedBox(height: 8),

                  // Metadata Jadwal & Rute
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Semantics(
                        sortKey: const OrdinalSortKey(3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 15, color: p.muted),
                            const SizedBox(width: 5),
                            Text(
                              '${formatMinute(widget.focus.departure.minute)} WIB',
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.text,
                                fontFeatures: HedgeTokens.numberFeatures,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.focus.route.name} · R${widget.focus.departure.round}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.muted,
                        ),
                      ),
                      if (widget.focus.departure.peak)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: p.cyanInk.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: p.cyanInk.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'PEAK',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: p.cyanInk,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Tombol Aksi Thumb-First Ergonomis
                  if (widget.onDispatch != null)
                    SlideAwayDispatchAction(
                      onDispatch: widget.onDispatch!,
                      pulse: pulse,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter untuk frame geometris Cyber HUD.
class CyberHudFramePainter extends CustomPainter {
  const CyberHudFramePainter({
    required this.color,
    required this.pulse,
    required this.isDark,
    required this.isDue,
  });

  final Color color;
  final double pulse;
  final bool isDark;
  final bool isDue;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDark) return;

    final bracketPaint = Paint()
      ..color = color.withValues(alpha: 0.4 + 0.3 * pulse)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const cornerLength = 16.0;
    const inset = 6.0;

    // Top-Left corner bracket
    canvas.drawLine(
      const Offset(inset, inset + cornerLength),
      const Offset(inset, inset),
      bracketPaint,
    );
    canvas.drawLine(
      const Offset(inset, inset),
      const Offset(inset + cornerLength, inset),
      bracketPaint,
    );

    // Top-Right corner bracket
    canvas.drawLine(
      Offset(size.width - inset - cornerLength, inset),
      Offset(size.width - inset, inset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(size.width - inset, inset + cornerLength),
      bracketPaint,
    );

    // Bottom-Left corner bracket
    canvas.drawLine(
      Offset(inset, size.height - inset - cornerLength),
      Offset(inset, size.height - inset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(inset, size.height - inset),
      Offset(inset + cornerLength, size.height - inset),
      bracketPaint,
    );

    // Bottom-Right corner bracket
    canvas.drawLine(
      Offset(size.width - inset - cornerLength, size.height - inset),
      Offset(size.width - inset, size.height - inset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset - cornerLength),
      Offset(size.width - inset, size.height - inset),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CyberHudFramePainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.color != color ||
      oldDelegate.isDue != isDue;
}

class SlideAwayDispatchAction extends StatefulWidget {
  const SlideAwayDispatchAction({
    super.key,
    required this.onDispatch,
    this.pulse = 1.0,
  });

  final VoidCallback onDispatch;
  final double pulse;

  @override
  State<SlideAwayDispatchAction> createState() => _SlideAwayDispatchActionState();
}

class _SlideAwayDispatchActionState extends State<SlideAwayDispatchAction> {
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _handleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTap) < const Duration(milliseconds: 500)) return;
    _lastTap = now;
    unawaited(HapticFeedback.mediumImpact());
    widget.onDispatch();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        height: HedgeTokens.primaryButtonHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HedgeTokens.radius),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: HedgeTokens.amber.withValues(
                      alpha: 0.45 + 0.3 * widget.pulse,
                    ),
                    blurRadius: 16 + 6 * widget.pulse,
                    spreadRadius: 1 + 1 * widget.pulse,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: HedgeTokens.amber.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: HedgeTokens.amber,
            foregroundColor: HedgeTokens.obsidian,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HedgeTokens.radius),
            ),
          ),
          onPressed: _handleTap,
          icon: const Icon(Icons.check_circle_rounded, size: 22),
          label: const Text(
            'SUDAH BERANGKAT',
            style: TextStyle(
              fontFamily: HedgeTokens.cyberFont,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class CountdownIndicator extends ConsumerWidget {
  const CountdownIndicator({
    super.key,
    required this.at,
    this.large = false,
    this.pulse = 1.0,
  });

  final DateTime at;
  final bool large;
  final double pulse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final remaining = at.difference(now.toUtc());
    final due = remaining <= Duration.zero;
    final imminent = remaining <= const Duration(seconds: 60);
    final p = context.hedge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = imminent ? p.amberInk : p.cyanInk;
    final label = due ? 'Waktu berangkat' : 'Menuju berangkat';
    final progress = due
        ? 1.0
        : (1.0 - (remaining.inSeconds.clamp(0, 300) / 300)).clamp(0.0, 1.0);

    final gaugeSize = large ? 160.0 : 114.0;

    return Semantics(
      sortKey: const OrdinalSortKey(2),
      label: due ? label : 'Countdown ${formatCountdown(remaining)}',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: gaugeSize,
          height: gaugeSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(gaugeSize, gaugeSize),
                painter: CyberCircularGaugePainter(
                  progress: progress,
                  activeColor: color,
                  trackColor: isDark ? const Color(0xFF070D16) : p.focusSurface,
                  pulse: pulse,
                  isDark: isDark,
                  isImminent: imminent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      key: const ValueKey('countdown-label'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: p.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      formatCountdown(remaining),
                      key: const ValueKey('focus-countdown'),
                      style: TextStyle(
                        fontFamily: HedgeTokens.cyberFont,
                        fontSize: large ? 40 : 28,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: color,
                        fontFeatures: HedgeTokens.numberFeatures,
                        shadows: isDark
                            ? [
                                Shadow(
                                  color: color.withValues(alpha: 0.5 * pulse),
                                  blurRadius: 10 * pulse,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter untuk Centerpiece Circular HUD Countdown Gauge.
class CyberCircularGaugePainter extends CustomPainter {
  CyberCircularGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.pulse,
    required this.isDark,
    required this.isImminent,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final double pulse;
  final bool isDark;
  final bool isImminent;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.085;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Outer decorative segmented ring
    if (isDark) {
      final outerRingPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.18 + 0.12 * pulse)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius + strokeWidth * 0.7, outerRingPaint);

      // Radial dark background glow
      final bgGlowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.04 + 0.03 * pulse)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bgGlowPaint);
    }

    // Circular background groove/track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Glowing Neon Dual-Arc Effect
    if (isDark) {
      // Blur glow underlay
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.45 * pulse)
        ..strokeWidth = strokeWidth + (4 * pulse)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * pulse);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        progress * 2 * math.pi,
        false,
        glowPaint,
      );

      // Amber counter-accent arc di kuadran atas/kanan untuk dual-glow otentik
      final dualAccentColor = isImminent ? HedgeTokens.electricCyan : HedgeTokens.amber;
      final dualArcPaint = Paint()
        ..color = dualAccentColor.withValues(alpha: 0.4 + 0.3 * pulse)
        ..strokeWidth = strokeWidth * 0.9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Busur amber di kuadran atas
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 0.45,
        false,
        dualArcPaint,
      );
    }

    // Solid Foreground Progress Arc
    final arcPaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      arcPaint,
    );

    // Head glowing node at the tip of progress arc
    if (progress > 0.02) {
      final headAngle = -math.pi / 2 + (progress * 2 * math.pi);
      final headX = center.dx + radius * math.cos(headAngle);
      final headY = center.dy + radius * math.sin(headAngle);

      final headPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.32, headPaint);

      if (isDark) {
        final headGlowPaint = Paint()
          ..color = activeColor.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * pulse);
        canvas.drawCircle(Offset(headX, headY), strokeWidth * 0.6, headGlowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CyberCircularGaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.pulse != pulse ||
      oldDelegate.isImminent != isImminent;
}

class ScheduleDepartureTile extends StatelessWidget {
  const ScheduleDepartureTile({
    super.key,
    required this.departure,
    required this.done,
    required this.focused,
    required this.frozen,
    required this.onRecord,
    this.isFirst = false,
    this.isLast = false,
  });

  final Departure departure;
  final bool done, focused, frozen;
  final bool isFirst, isLast;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return CyberTimelineTile(
      departure: departure,
      done: done,
      focused: focused,
      frozen: frozen,
      isFirst: isFirst,
      isLast: isLast,
      onRecord: onRecord,
    );
  }
}
