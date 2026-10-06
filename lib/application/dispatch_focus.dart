import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import 'workspace_controller.dart';

typedef DispatchFocus = ({
  HedgeRoute route,
  ScheduleRevision revision,
  Departure departure,
  bool due,
});

/// Presentation selection only. Does not modify the committed schedule or ledger.
DispatchFocus? selectDispatchFocus(
  Workspace workspace,
  DateTime now, {
  String? routeId,
}) {
  final actual = workspace.events
      .where((e) => e.kind == 'departed')
      .map((e) => e.departureId)
      .toSet();
  final nowMs = now.toUtc().millisecondsSinceEpoch;
  DispatchFocus? result;
  var bestMs = 0;
  for (final route in workspace.routes) {
    if (routeId == null ? !route.participates : route.id != routeId) continue;
    final revision = route.schedule;
    if (revision == null) continue;
    final rows = revision.departures;
    final dayMs = plannedInstant(revision.date, 0).millisecondsSinceEpoch;
    final holdMs = route.alarmDuration.clamp(1, 60) * 1000;
    final minimum = nowMs - dayMs - holdMs;
    var low = 0;
    var high = rows.length;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (rows[middle].minute * 60000 <= minimum) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    for (var i = low; i < rows.length; i++) {
      final departure = rows[i];
      if (actual.contains(departure.id)) continue;
      final atMs = dayMs + departure.minute * 60000;
      final candidate = (
        route: route,
        revision: revision,
        departure: departure,
        due: atMs <= nowMs,
      );
      final tie =
          result != null &&
          atMs == bestMs &&
          '${route.id}:${departure.id}'.compareTo(
                '${result.route.id}:${result.departure.id}',
              ) <
              0;
      if (result == null || atMs < bestMs || tie) {
        result = candidate;
        bestMs = atMs;
      }
      break;
    }
  }
  return result;
}

/// Record equality suppresses downstream rebuilds while the focused departure is unchanged.
final dispatchFocusProvider = Provider.family<DispatchFocus?, String?>((
  ref,
  routeId,
) {
  final workspace = ref.watch(workspaceProvider.select((s) => s.workspace));
  final now = ref.watch(clockProvider).value ?? DateTime.now();
  return selectDispatchFocus(workspace, now, routeId: routeId);
});

String formatCountdown(Duration duration) {
  final seconds = (duration.inMilliseconds / 1000).ceil().clamp(0, 999999);
  final h = seconds ~/ 3600;
  final m = seconds % 3600 ~/ 60;
  final s = seconds % 60;
  return '${h > 0 ? '${h.toString().padLeft(2, '0')}:' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
