import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/workspace_controller.dart';
import '../domain/alarm_plan.dart';
import 'design_system.dart';
import 'dispatch_components.dart';

/// Foreground fallback for platforms without the Android native alarm Activity.
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
    final seconds =
        item.shownAt
            .add(Duration(seconds: route.alarmDuration.clamp(1, 300)))
            .difference(now)
            .inMilliseconds ~/
        1000;
    final p = context.hedge;
    return Positioned.fill(
      child: Material(
        key: const ValueKey('fullscreen-alarm'),
        color: p.background,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HEDGE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    Text(
                      'Headway Generator · By Mikrotrans Utara',
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      DepartureFocusPanel(
                        focus: (
                          route: route,
                          revision: revision,
                          departure: row,
                          due: !event.departureAt.isAfter(now),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Menutup otomatis dalam ${seconds.clamp(0, 300)} detik',
                        key: const ValueKey('alert-timeout'),
                      ),
                      if (items.length > 1) Text('${items.length} alert aktif'),
                      const SizedBox(height: 12),
                      const Text(
                        'Sudah Berangkat mencatat aktual. Timeout hanya menutup alert.',
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: ref.watch(workspaceProvider).saving
                          ? null
                          : () => ref
                                .read(workspaceProvider.notifier)
                                .record(revision, row, 'departed'),
                      child: const Text('Sudah Berangkat'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: ref.watch(workspaceProvider).saving
                          ? null
                          : () => ref
                                .read(workspaceProvider.notifier)
                                .updateRoute(
                                  route.copyWith(alarmEnabled: false),
                                ),
                      child: const Text('Matikan alarm rute'),
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
}
