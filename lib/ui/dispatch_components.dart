import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/dispatch_focus.dart';
import '../application/workspace_controller.dart';
import '../domain/models.dart';
import 'design_system.dart';
import 'schedule_timeline.dart';

class DepartureFocusPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final p = context.hedge;
    final accent = focus.due ? p.amberInk : p.cyanInk;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(HedgeTokens.panelRadius),
          border: Border.all(
            color: focus.due ? p.amberInk : accent.withValues(alpha: .5),
            width: focus.due ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: focus.due ? .14 : .06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(large ? 24 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: focus.due ? p.warningSurface : p.focusSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: .4)),
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
                            color: accent.withValues(alpha: .6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          focus.due
                              ? 'WAKTU BERANGKAT'
                              : 'KEBERANGKATAN BERIKUTNYA',
                          style: TextStyle(
                            fontSize: 11,
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
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final unit = Semantics(
                    sortKey: const OrdinalSortKey(1),
                    label: 'Nomor unit ${focus.departure.unitNumber}',
                    excludeSemantics: true,
                    child: Text(
                      focus.departure.unitNumber,
                      key: const ValueKey('focus-unit'),
                      style: TextStyle(
                        fontSize: large ? 64 : 44,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                        color: p.text,
                        fontFeatures: HedgeTokens.numberFeatures,
                      ),
                    ),
                  );
                  final timer = CountdownIndicator(
                    at: plannedInstant(
                      focus.revision.date,
                      focus.departure.minute,
                    ),
                    large: large,
                  );
                  final scaled =
                      MediaQuery.textScalerOf(context).scale(14) / 14;
                  final stacked =
                      constraints.maxWidth < 280 ||
                      scaled > 1.3 ||
                      focus.departure.unitNumber.length > 6;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [unit, const SizedBox(height: 10), timer],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: unit),
                      const SizedBox(width: 16),
                      timer,
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Semantics(
                    sortKey: const OrdinalSortKey(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 16, color: p.muted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${formatMinute(focus.departure.minute)} WIB',
                            style: TextStyle(
                              fontSize: 16,
                              color: p.text,
                              fontFeatures: HedgeTokens.numberFeatures,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${focus.route.name} · R${focus.departure.round}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.muted,
                    ),
                  ),
                  if (focus.departure.peak)
                    Text(
                      'PEAK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.cyanInk,
                      ),
                    ),
                ],
              ),
              if (onDispatch != null)
                SlideAwayDispatchAction(onDispatch: onDispatch!),
            ],
          ),
        ),
      ),
    );
  }
}

class SlideAwayDispatchAction extends StatefulWidget {
  const SlideAwayDispatchAction({super.key, required this.onDispatch});
  final VoidCallback onDispatch;
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
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        width: double.infinity,
        height: HedgeTokens.primaryButtonHeight,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: HedgeTokens.amber,
            foregroundColor: HedgeTokens.obsidian,
            elevation: 3,
            shadowColor: HedgeTokens.amber.withValues(alpha: .45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HedgeTokens.radius),
            ),
          ),
          onPressed: _handleTap,
          icon: const Icon(Icons.check_circle_rounded, size: 22),
          label: const Text(
            'SUDAH BERANGKAT',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ),
      ),
    );
  }
}

class CountdownIndicator extends ConsumerWidget {
  const CountdownIndicator({super.key, required this.at, this.large = false});
  final DateTime at;
  final bool large;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final remaining = at.difference(now.toUtc());
    final due = remaining <= Duration.zero;
    final imminent = remaining <= const Duration(seconds: 60);
    final p = context.hedge;
    final color = imminent ? p.amberInk : p.cyanInk;
    final label = due ? 'Waktu berangkat' : 'Menuju berangkat';
    final progress = due
        ? 1.0
        : (1.0 - (remaining.inSeconds.clamp(0, 300) / 300)).clamp(0.0, 1.0);
    return Semantics(
      sortKey: const OrdinalSortKey(2),
      label: due ? label : 'Countdown ${formatCountdown(remaining)}',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size(large ? 48 : 36, large ? 48 : 36),
              painter: CountdownRingPainter(
                progress: progress,
                color: color,
                trackColor: (imminent ? p.warningSurface : p.focusSurface),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      key: const ValueKey('countdown-label'),
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCountdown(remaining),
                      key: const ValueKey('focus-countdown'),
                      style: TextStyle(
                        fontSize: large ? 40 : 28,
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                        color: color,
                        fontFeatures: HedgeTokens.numberFeatures,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CountdownRingPainter extends CustomPainter {
  CountdownRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });
  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .12;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265 / 2,
      progress * 2 * 3.14159265,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CountdownRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
