import 'models.dart';

class AlarmEvent {
  const AlarmEvent({
    required this.key,
    required this.routeId,
    required this.revisionId,
    required this.departureId,
    required this.routeName,
    required this.unitNumber,
    required this.stage,
    required this.at,
    required this.departureAt,
    required this.round,
    required this.durationSeconds,
    required this.preferences,
    required this.theme,
  });
  final String key,
      routeId,
      revisionId,
      departureId,
      routeName,
      unitNumber,
      stage,
      theme;
  final DateTime at, departureAt;
  final int round, durationSeconds;
  final AlarmPreferences preferences;
  Map<String, dynamic> toJson() => {
    'key': key,
    'routeId': routeId,
    'revisionId': revisionId,
    'departureId': departureId,
    'routeName': routeName,
    'unitNumber': unitNumber,
    'stage': stage,
    'at': at.millisecondsSinceEpoch,
    'departureAt': departureAt.millisecondsSinceEpoch,
    'round': round,
    'durationSeconds': durationSeconds,
    'theme': theme,
    ...preferences.toJson(),
  };
}

/// Entire future queue. Android persists this and rearms without a Dart process.
List<AlarmEvent> buildAlarmPlan(Workspace workspace, DateTime now) {
  final events = <AlarmEvent>[];
  for (final route in workspace.routes) {
    if (!route.participates ||
        !route.alarmEnabled ||
        route.schedule == null ||
        (!route.alerts.banner && !route.alerts.fullScreen)) {
      continue;
    }
    final revision = route.schedule!;
    for (final row in revision.departures) {
      if (workspace.hasDeparted(row.id) || workspace.hasAcknowledged(row.id)) {
        continue;
      }
      final due = plannedInstant(revision.date, row.minute);
      void add(String stage, DateTime at) {
        if (!at.isAfter(now.toUtc())) return;
        events.add(
          AlarmEvent(
            key: '${row.id}:$stage',
            routeId: route.id,
            revisionId: revision.id,
            departureId: row.id,
            routeName: route.name,
            unitNumber: row.unitNumber,
            stage: stage,
            at: at,
            departureAt: due,
            round: row.round,
            durationSeconds: route.alarmDuration.clamp(1, 300),
            preferences: route.alerts,
            theme: workspace.theme,
          ),
        );
      }

      if (route.alerts.departure) add('due', due);
      if (route.alerts.preparation && route.preparationSeconds > 0) {
        add(
          'prep',
          due.subtract(
            Duration(seconds: route.preparationSeconds.clamp(0, 300)),
          ),
        );
      }
    }
  }
  events.sort((a, b) {
    final order = a.at.compareTo(b.at);
    return order != 0 ? order : a.key.compareTo(b.key);
  });
  return events;
}

class NativeAlarmAction {
  const NativeAlarmAction({
    required this.id,
    required this.routeId,
    required this.kind,
    required this.at,
    this.departureId,
    this.revisionId,
  });
  final String id, routeId, kind, at;
  final String? departureId, revisionId;
  factory NativeAlarmAction.fromJson(Map<String, dynamic> json) =>
      NativeAlarmAction(
        id: json['id'] as String,
        routeId: json['routeId'] as String,
        kind: json['kind'] as String,
        at: json['at'] as String,
        departureId: json['departureId'] as String?,
        revisionId: json['revisionId'] as String?,
      );
}

/// Native actions remain on Android until this workspace is durably saved.
Workspace applyNativeAlarmActions(
  Workspace workspace,
  List<NativeAlarmAction> actions,
) {
  var routes = workspace.routes;
  final events = [...workspace.events];
  final revisions = {
    for (final r in workspace.history) r.id: r,
    for (final route in workspace.routes)
      if (route.schedule != null) route.schedule!.id: route.schedule!,
  };
  for (final action in actions) {
    if (action.kind == 'disableAlarm') {
      routes = routes
          .map(
            (r) => r.id == action.routeId ? r.copyWith(alarmEnabled: false) : r,
          )
          .toList();
    } else if (action.kind == 'departed') {
      final revision = revisions[action.revisionId];
      if (revision == null ||
          revision.routeId != action.routeId ||
          !revision.departures.any((d) => d.id == action.departureId)) {
        continue;
      }
      if (events.any(
        (e) => e.departureId == action.departureId && e.kind == 'departed',
      )) {
        continue;
      }
      DateTime.parse(action.at);
      events.add(
        DispatchEvent(
          id: action.id,
          departureId: action.departureId!,
          revisionId: revision.id,
          kind: 'departed',
          at: action.at,
        ),
      );
    }
  }
  return workspace.copyWith(routes: routes, events: events);
}

List<NativeAlarmAction> acceptedNativeAlarmActions(
  Workspace workspace,
  List<NativeAlarmAction> actions,
) {
  final revisions = {
    for (final r in workspace.history) r.id: r,
    for (final r in workspace.routes)
      if (r.schedule != null) r.schedule!.id: r.schedule!,
  };
  return actions
      .where(
        (a) =>
            a.kind == 'disableAlarm' ||
            (a.kind == 'departed' &&
                DateTime.tryParse(a.at) != null &&
                revisions[a.revisionId]?.routeId == a.routeId &&
                (revisions[a.revisionId]?.departures.any(
                      (d) => d.id == a.departureId,
                    ) ??
                    false)),
      )
      .toList();
}
