import 'dart:convert';

String formatMinute(int minute) {
  final value = minute % 1440;
  return '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
}

int parseMinute(String value) {
  if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
    throw FormatException('Jam harus dalam format HH:mm.', value);
  }
  final parts = value.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String serviceDate(DateTime now) {
  final jakarta = now.toUtc().add(const Duration(hours: 7));
  return '${jakarta.year}-${jakarta.month.toString().padLeft(2, '0')}-${jakarta.day.toString().padLeft(2, '0')}';
}

DateTime plannedInstant(String date, int minute) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
    throw const FormatException('Tanggal harus YYYY-MM-DD.');
  }
  final day = DateTime.parse('${date}T00:00:00Z');
  if (day.toIso8601String().substring(0, 10) != date) {
    throw const FormatException('Tanggal tidak valid.');
  }
  return day.add(Duration(minutes: minute - 420));
}

Map<String, dynamic> jsonMap(Object? value) {
  if (value is! Map) throw const FormatException('Objek data tidak valid.');
  return Map<String, dynamic>.from(value);
}

class FleetUnit {
  const FleetUnit({required this.id, required this.number, this.active = true});
  final String id;
  final String number;
  final bool active;
  FleetUnit copyWith({bool? active}) =>
      FleetUnit(id: id, number: number, active: active ?? this.active);
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'active': active,
  };
  factory FleetUnit.fromJson(Map<String, dynamic> json) => FleetUnit(
    id: json['id'] as String,
    number: json['number'] as String,
    active: json['active'] as bool? ?? true,
  );
}

class PeakPeriod {
  const PeakPeriod({
    required this.start,
    required this.end,
    required this.interval,
  });
  final String start;
  final String end;
  final int interval;
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'interval': interval,
  };
  factory PeakPeriod.fromJson(Map<String, dynamic> json) => PeakPeriod(
    start: json['start'] as String,
    end: json['end'] as String,
    interval: json['interval'] as int,
  );
}

class PlanConfig {
  const PlanConfig({
    this.start = '05:00',
    this.end = '22:00',
    this.rounds = 8,
    this.slowFirst = false,
    this.peakEnabled = false,
    this.peaks = const [
      PeakPeriod(start: '05:00', end: '08:00', interval: 2),
      PeakPeriod(start: '17:00', end: '19:00', interval: 3),
    ],
  });
  final String start;
  final String end;
  final int rounds;
  final bool slowFirst;
  final bool peakEnabled;
  final List<PeakPeriod> peaks;
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'rounds': rounds,
    'slowFirst': slowFirst,
    'peakEnabled': peakEnabled,
    'peaks': peaks.map((p) => p.toJson()).toList(),
  };
  factory PlanConfig.fromJson(Map<String, dynamic> json) => PlanConfig(
    start: json['start'] as String,
    end: json['end'] as String,
    rounds: json['rounds'] as int,
    slowFirst: json['slowFirst'] as bool? ?? false,
    peakEnabled: json['peakEnabled'] as bool? ?? false,
    peaks: (json['peaks'] as List? ?? [])
        .map((p) => PeakPeriod.fromJson(jsonMap(p)))
        .toList(),
  );
}

class Departure {
  const Departure({
    required this.id,
    required this.unitId,
    required this.unitNumber,
    required this.ordinal,
    required this.round,
    required this.minute,
    required this.peak,
    this.nextGap,
  });
  final String id;
  final String unitId;
  final String unitNumber;
  final int ordinal;
  final int round;
  final int minute;
  final bool peak;
  final int? nextGap;
  Departure withGap(int? gap) => Departure(
    id: id,
    unitId: unitId,
    unitNumber: unitNumber,
    ordinal: ordinal,
    round: round,
    minute: minute,
    peak: peak,
    nextGap: gap,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'unitId': unitId,
    'unitNumber': unitNumber,
    'ordinal': ordinal,
    'round': round,
    'minute': minute,
    'peak': peak,
    'nextGap': nextGap,
  };
  factory Departure.fromJson(Map<String, dynamic> json) => Departure(
    id: json['id'] as String,
    unitId: json['unitId'] as String,
    unitNumber: json['unitNumber'] as String,
    ordinal: json['ordinal'] as int,
    round: json['round'] as int,
    minute: json['minute'] as int,
    peak: json['peak'] as bool,
    nextGap: json['nextGap'] as int?,
  );
}

class ScheduleRevision {
  ScheduleRevision({
    required this.id,
    required this.routeId,
    required this.date,
    required this.createdAt,
    required this.inputFingerprint,
    required this.config,
    required List<Departure> departures,
    this.parentId,
    this.frozenCount = 0,
    this.engineVersion = 'validated-v2.0',
    this.reason = 'generate',
  }) : departures = List.unmodifiable(departures);
  final String id;
  final String routeId;
  final String date;
  final String createdAt;
  final String inputFingerprint;
  final PlanConfig config;
  final List<Departure> departures;
  final String? parentId;
  final int frozenCount;
  final String engineVersion;
  final String reason;
  Map<String, dynamic> toJson({bool includeRows = true}) => {
    'id': id,
    'routeId': routeId,
    'date': date,
    'createdAt': createdAt,
    'inputFingerprint': inputFingerprint,
    'config': config.toJson(),
    'parentId': parentId,
    'frozenCount': frozenCount,
    'engineVersion': engineVersion,
    'reason': reason,
    if (includeRows) 'departures': departures.map((r) => r.toJson()).toList(),
  };
  factory ScheduleRevision.fromJson(Map<String, dynamic> json) =>
      ScheduleRevision(
        id: json['id'] as String,
        routeId: json['routeId'] as String,
        date: json['date'] as String,
        createdAt: json['createdAt'] as String,
        inputFingerprint: json['inputFingerprint'] as String,
        config: PlanConfig.fromJson(jsonMap(json['config'])),
        departures: (json['departures'] as List? ?? [])
            .map((r) => Departure.fromJson(jsonMap(r)))
            .toList(),
        parentId: json['parentId'] as String?,
        frozenCount: json['frozenCount'] as int? ?? 0,
        engineVersion: json['engineVersion'] as String? ?? 'validated-v2.0',
        reason: json['reason'] as String? ?? 'generate',
      );
}

class AlarmPreferences {
  const AlarmPreferences({
    this.banner = true,
    this.fullScreen = true,
    this.preparation = true,
    this.departure = true,
    this.sound = true,
    this.vibration = true,
  });
  final bool banner, fullScreen, preparation, departure, sound, vibration;
  Map<String, dynamic> toJson() => {
    'banner': banner,
    'fullScreen': fullScreen,
    'preparation': preparation,
    'departure': departure,
    'sound': sound,
    'vibration': vibration,
  };
  factory AlarmPreferences.fromJson(Map<String, dynamic> json) =>
      AlarmPreferences(
        banner: json['banner'] as bool? ?? true,
        fullScreen: json['fullScreen'] as bool? ?? true,
        preparation: json['preparation'] as bool? ?? true,
        departure: json['departure'] as bool? ?? true,
        sound: json['sound'] as bool? ?? true,
        vibration: json['vibration'] as bool? ?? true,
      );
}

class HedgeRoute {
  HedgeRoute({
    required this.id,
    required this.name,
    required this.color,
    required List<FleetUnit> units,
    required List<String> order,
    this.config = const PlanConfig(),
    this.participates = true,
    this.alarmEnabled = true,
    this.alarmDuration = 8,
    this.preparationSeconds = 10,
    this.alerts = const AlarmPreferences(),
    this.schedule,
  }) : units = List.unmodifiable(units),
       order = List.unmodifiable(order);
  final String id;
  final String name;
  final int color;
  final List<FleetUnit> units;
  final List<String> order;
  final PlanConfig config;
  final bool participates;
  final bool alarmEnabled;
  final int alarmDuration;
  final int preparationSeconds;
  final AlarmPreferences alerts;
  final ScheduleRevision? schedule;
  List<FleetUnit> get activeUnits {
    final byId = {for (final u in units) u.id: u};
    return order
        .map((id) => byId[id])
        .whereType<FleetUnit>()
        .where((u) => u.active)
        .toList();
  }

  String get fingerprint => jsonEncode({
    'config': config.toJson(),
    'order': activeUnits.map((u) => u.id).toList(),
  });
  bool get dirty =>
      schedule != null && schedule!.inputFingerprint != fingerprint;
  HedgeRoute copyWith({
    String? name,
    int? color,
    List<FleetUnit>? units,
    List<String>? order,
    PlanConfig? config,
    bool? participates,
    bool? alarmEnabled,
    int? alarmDuration,
    int? preparationSeconds,
    AlarmPreferences? alerts,
    ScheduleRevision? schedule,
    bool clearSchedule = false,
  }) => HedgeRoute(
    id: id,
    name: name ?? this.name,
    color: color ?? this.color,
    units: units ?? this.units,
    order: order ?? this.order,
    config: config ?? this.config,
    participates: participates ?? this.participates,
    alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    alarmDuration: alarmDuration ?? this.alarmDuration,
    preparationSeconds: preparationSeconds ?? this.preparationSeconds,
    alerts: alerts ?? this.alerts,
    schedule: clearSchedule ? null : schedule ?? this.schedule,
  );
  Map<String, dynamic> toJson({bool includeSchedule = true}) => {
    'id': id,
    'name': name,
    'color': color,
    'units': units.map((u) => u.toJson()).toList(),
    'order': order,
    'config': config.toJson(),
    'participates': participates,
    'alarmEnabled': alarmEnabled,
    'alarmDuration': alarmDuration,
    'preparationSeconds': preparationSeconds,
    'alerts': alerts.toJson(),
    if (includeSchedule) 'schedule': schedule?.toJson(),
  };
  factory HedgeRoute.fromJson(Map<String, dynamic> json) => HedgeRoute(
    id: json['id'] as String,
    name: json['name'] as String,
    color: json['color'] as int,
    units: (json['units'] as List)
        .map((u) => FleetUnit.fromJson(jsonMap(u)))
        .toList(),
    order: List<String>.from(json['order'] as List),
    config: PlanConfig.fromJson(jsonMap(json['config'])),
    participates: json['participates'] as bool? ?? true,
    alarmEnabled: json['alarmEnabled'] as bool? ?? true,
    alarmDuration: json['alarmDuration'] as int? ?? 8,
    preparationSeconds: json['preparationSeconds'] as int? ?? 10,
    alerts: AlarmPreferences.fromJson(
      jsonMap(json['alerts'] ?? <String, dynamic>{}),
    ),
    schedule: json['schedule'] == null
        ? null
        : ScheduleRevision.fromJson(jsonMap(json['schedule'])),
  );
}

class DispatchEvent {
  const DispatchEvent({
    required this.id,
    required this.departureId,
    required this.revisionId,
    required this.kind,
    required this.at,
  });
  final String id;
  final String departureId;
  final String revisionId;
  final String kind;
  final String at;
  Map<String, dynamic> toJson() => {
    'id': id,
    'departureId': departureId,
    'revisionId': revisionId,
    'kind': kind,
    'at': at,
  };
  factory DispatchEvent.fromJson(Map<String, dynamic> json) => DispatchEvent(
    id: json['id'] as String,
    departureId: json['departureId'] as String,
    revisionId: json['revisionId'] as String,
    kind: json['kind'] as String,
    at: json['at'] as String,
  );
}

class Workspace {
  Workspace({
    required List<HedgeRoute> routes,
    required this.activeRouteId,
    required this.date,
    this.theme = 'dark',
    List<DispatchEvent> events = const [],
    List<ScheduleRevision> history = const [],
  }) : routes = List.unmodifiable(routes),
       events = List.unmodifiable(events),
       history = List.unmodifiable(history);
  final List<HedgeRoute> routes;
  final String? activeRouteId;
  final String date;
  final String theme;
  final List<DispatchEvent> events;
  final List<ScheduleRevision> history;
  HedgeRoute? get activeRoute {
    for (final r in routes) {
      if (r.id == activeRouteId) return r;
    }
    return routes.isEmpty ? null : routes.first;
  }

  bool hasDeparted(String departureId) =>
      events.any((e) => e.departureId == departureId && e.kind == 'departed');
  bool hasAcknowledged(String departureId) =>
      events.any((e) => e.departureId == departureId && e.kind == 'alarmAck');
  Workspace copyWith({
    List<HedgeRoute>? routes,
    String? activeRouteId,
    String? date,
    String? theme,
    List<DispatchEvent>? events,
    List<ScheduleRevision>? history,
  }) => Workspace(
    routes: routes ?? this.routes,
    activeRouteId: activeRouteId ?? this.activeRouteId,
    date: date ?? this.date,
    theme: theme ?? this.theme,
    events: events ?? this.events,
    history: history ?? this.history,
  );
  Map<String, dynamic> toJson() => {
    'format': 'hedge-native-backup',
    'schemaVersion': 1,
    'timezone': 'Asia/Jakarta',
    'date': date,
    'activeRouteId': activeRouteId,
    'theme': theme,
    'routes': routes.map((r) => r.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'history': history.map((r) => r.toJson()).toList(),
  };
  factory Workspace.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 || json['format'] != 'hedge-native-backup') {
      throw const FormatException('Versi backup tidak didukung.');
    }
    final routes = (json['routes'] as List)
        .map((r) => HedgeRoute.fromJson(jsonMap(r)))
        .toList();
    return Workspace(
      routes: routes,
      activeRouteId: json['activeRouteId'] as String?,
      date: json['date'] as String,
      theme: json['theme'] as String? ?? 'dark',
      events: (json['events'] as List? ?? [])
          .map((e) => DispatchEvent.fromJson(jsonMap(e)))
          .toList(),
      history: (json['history'] as List? ?? [])
          .map((r) => ScheduleRevision.fromJson(jsonMap(r)))
          .toList(),
    );
  }
}
