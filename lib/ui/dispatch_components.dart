import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/dispatch_focus.dart';
import '../application/workspace_controller.dart';
import '../domain/models.dart';
import 'design_system.dart';

class DepartureFocusPanel extends StatelessWidget {
  const DepartureFocusPanel({
    super.key,
    required this.focus,
    this.large = false,
  });
  final DispatchFocus focus;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    final accent = focus.due ? p.amberInk : p.cyanInk;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(HedgeTokens.panelRadius),
          border: Border.all(color: accent.withValues(alpha: .45)),
        ),
        child: Padding(
          padding: EdgeInsets.all(large ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
                ],
              ),
              const SizedBox(height: 12),
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
                        fontWeight: FontWeight.w700,
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
                      children: [unit, const SizedBox(height: 12), timer],
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
              const SizedBox(height: 16),
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
            ],
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
    return Semantics(
      sortKey: const OrdinalSortKey(2),
      label: due ? label : 'Countdown ${formatCountdown(remaining)}',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              key: const ValueKey('countdown-label'),
              style: TextStyle(fontSize: 12, color: p.muted),
            ),
            const SizedBox(height: 4),
            Text(
              formatCountdown(remaining),
              key: const ValueKey('focus-countdown'),
              style: TextStyle(
                fontSize: large ? 40 : 28,
                fontWeight: FontWeight.w700,
                height: 1.08,
                color: color,
                fontFeatures: HedgeTokens.numberFeatures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleDepartureTile extends StatelessWidget {
  const ScheduleDepartureTile({
    super.key,
    required this.departure,
    required this.done,
    required this.focused,
    required this.frozen,
    required this.onRecord,
  });
  final Departure departure;
  final bool done, focused, frozen;
  final VoidCallback onRecord;
  @override
  Widget build(BuildContext context) {
    final p = context.hedge;
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: focused ? p.focusSurface : p.surface,
          borderRadius: BorderRadius.circular(HedgeTokens.radius),
          border: Border.all(
            color: focused ? p.cyanInk.withValues(alpha: .55) : p.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    departure.unitNumber,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: done ? p.muted : p.text,
                      fontFeatures: HedgeTokens.numberFeatures,
                    ),
                  ),
                  if (frozen)
                    Text(
                      'Histori rencana',
                      style: TextStyle(fontSize: 11, color: p.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMinute(departure.minute),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                      fontFeatures: HedgeTokens.numberFeatures,
                    ),
                  ),
                  Text(
                    'R${departure.round} · ${departure.nextGap == null ? 'Terakhir' : '${departure.nextGap} menit'}',
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                  if (departure.peak)
                    Text(
                      'PEAK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: p.cyanInk,
                      ),
                    ),
                ],
              ),
            ),
            if (done)
              Semantics(
                label: 'Keberangkatan aktual tercatat',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.check_circle, color: p.success),
                ),
              )
            else
              IconButton(
                tooltip: 'Catat keberangkatan aktual',
                onPressed: onRecord,
                icon: Icon(Icons.check_circle_outline, color: p.muted),
              ),
          ],
        ),
      ),
    );
  }
}
