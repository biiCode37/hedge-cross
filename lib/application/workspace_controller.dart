import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/workspace_repository.dart';
import '../domain/models.dart';
import '../domain/alarm_plan.dart';
import '../domain/scheduler.dart';

final repositoryProvider = Provider<WorkspaceRepository>(
  (ref) => throw StateError('Repository belum diinisialisasi.'),
);
final initialWorkspaceProvider = Provider<Workspace>(
  (ref) => throw StateError('Workspace belum dimuat.'),
);
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

class AppState {
  const AppState(this.workspace, {this.saving = false, this.error});
  final Workspace workspace;
  final bool saving;
  final String? error;
}

final workspaceProvider = NotifierProvider<WorkspaceController, AppState>(
  WorkspaceController.new,
);

class WorkspaceController extends Notifier<AppState> {
  static const _uuid = Uuid();
  final _scheduler = const Scheduler();
  @override
  AppState build() => AppState(ref.read(initialWorkspaceProvider));

  Future<bool> _save(Workspace next) async {
    if (state.saving) return false;
    final previous = state.workspace;
    final history = {
      for (final r in next.history) r.id: r,
      for (final r in previous.routes)
        if (r.schedule != null) r.schedule!.id: r.schedule!,
    };
    next = next.copyWith(history: history.values.toList());
    state = AppState(previous, saving: true);
    try {
      await ref.read(repositoryProvider).save(next);
      state = AppState(next);
      return true;
    } catch (error) {
      state = AppState(previous, error: 'Data belum tersimpan: $error');
      return false;
    }
  }

  void clearError() => state = AppState(state.workspace, saving: state.saving);
  Future<bool> selectRoute(String id) =>
      _save(state.workspace.copyWith(activeRouteId: id));
  Future<bool> setDate(String date) =>
      _save(state.workspace.copyWith(date: date));
  Future<bool> setTheme(String theme) =>
      _save(state.workspace.copyWith(theme: theme));
  Future<bool> updateRoute(HedgeRoute route) => _save(
    state.workspace.copyWith(
      routes: state.workspace.routes
          .map((r) => r.id == route.id ? route : r)
          .toList(),
    ),
  );

  Future<bool> applyAlarmActions(List<NativeAlarmAction> actions) =>
      _save(applyNativeAlarmActions(state.workspace, actions));

  Future<bool> addRoute(String name) async {
    if (name.trim().isEmpty) return _error('Nama rute wajib diisi.');
    if (state.workspace.routes.any(
      (r) => r.name.toLowerCase() == name.trim().toLowerCase(),
    )) {
      return _error('Nama rute sudah digunakan.');
    }
    final colors = [0xffff9800, 0xff38bdf8, 0xff10b981, 0xffe879f9];
    final route = HedgeRoute(
      id: _uuid.v4(),
      name: name.trim(),
      color: colors[state.workspace.routes.length % colors.length],
      units: [],
      order: [],
    );
    return _save(
      state.workspace.copyWith(
        routes: [...state.workspace.routes, route],
        activeRouteId: route.id,
      ),
    );
  }

  Future<bool> cloneRoute(HedgeRoute route) {
    final units = route.units
        .map(
          (u) => FleetUnit(id: _uuid.v4(), number: u.number, active: u.active),
        )
        .toList();
    final ids = {
      for (var i = 0; i < units.length; i++) route.units[i].id: units[i].id,
    };
    var suffix = 1;
    var name = '${route.name} (Salinan)';
    while (state.workspace.routes.any(
      (r) => r.name.toLowerCase() == name.toLowerCase(),
    )) {
      name = '${route.name} (Salinan ${++suffix})';
    }
    final copy = HedgeRoute(
      id: _uuid.v4(),
      name: name,
      color: route.color,
      units: units,
      order: route.order.map((id) => ids[id]!).toList(),
      config: route.config,
      alarmEnabled: route.alarmEnabled,
      alarmDuration: route.alarmDuration,
      preparationSeconds: route.preparationSeconds,
      alerts: route.alerts,
    );
    return _save(
      state.workspace.copyWith(
        routes: [...state.workspace.routes, copy],
        activeRouteId: copy.id,
      ),
    );
  }

  Future<bool> deleteRoute(String id) {
    final routes = state.workspace.routes.where((r) => r.id != id).toList();
    return _save(
      Workspace(
        routes: routes,
        activeRouteId: state.workspace.activeRouteId == id
            ? (routes.isEmpty ? null : routes.first.id)
            : state.workspace.activeRouteId,
        date: state.workspace.date,
        theme: state.workspace.theme,
        events: state.workspace.events,
        history: state.workspace.history,
      ),
    );
  }

  Future<bool> addUnit(HedgeRoute route, String number) async {
    final value = number.trim();
    if (value.isEmpty) return _error('Nomor unit wajib diisi.');
    if (route.units.any((u) => u.number == value)) {
      return _error('Nomor unit sudah ada pada rute ini.');
    }
    final unit = FleetUnit(id: _uuid.v4(), number: value);
    return updateRoute(
      route.copyWith(
        units: [...route.units, unit],
        order: [...route.order, unit.id],
      ),
    );
  }

  Future<bool> setUnitActive(HedgeRoute route, FleetUnit unit, bool active) {
    final order = [
      ...route.order.where((id) => id != unit.id),
      if (active) unit.id,
    ];
    return updateRoute(
      route.copyWith(
        units: route.units
            .map((u) => u.id == unit.id ? u.copyWith(active: active) : u)
            .toList(),
        order: order,
      ),
    );
  }

  Future<bool> deleteUnit(HedgeRoute route, String id) => updateRoute(
    route.copyWith(
      units: route.units.where((u) => u.id != id).toList(),
      order: route.order.where((value) => value != id).toList(),
    ),
  );

  Future<bool> reorder(HedgeRoute route, List<String> order) =>
      updateRoute(route.copyWith(order: order));

  Future<bool> generate(HedgeRoute route, {bool replan = false}) async {
    try {
      final now = DateTime.now();
      final schedule = replan
          ? _scheduler.replan(route, revisionId: _uuid.v4(), now: now)
          : _scheduler.generate(
              route,
              date: state.workspace.date,
              revisionId: _uuid.v4(),
              createdAt: now,
            );
      return updateRoute(route.copyWith(schedule: schedule));
    } catch (error) {
      return _error(error.toString());
    }
  }

  Future<List<String>> generateAll() async {
    final failures = <String>[];
    final routes = <HedgeRoute>[];
    for (final route in state.workspace.routes) {
      if (!route.participates) {
        routes.add(route);
        continue;
      }
      try {
        routes.add(
          route.copyWith(
            schedule: _scheduler.generate(
              route,
              date: state.workspace.date,
              revisionId: _uuid.v4(),
              createdAt: DateTime.now(),
            ),
          ),
        );
      } catch (error) {
        routes.add(route);
        failures.add('${route.name}: $error');
      }
    }
    if (!await _save(state.workspace.copyWith(routes: routes))) {
      failures.add('Perubahan belum tersimpan.');
    }
    return failures;
  }

  Future<bool> record(
    ScheduleRevision revision,
    Departure departure,
    String kind,
  ) async {
    if (state.workspace.events.any(
      (e) => e.departureId == departure.id && e.kind == kind,
    )) {
      return true;
    }
    return _save(
      state.workspace.copyWith(
        events: [
          ...state.workspace.events,
          DispatchEvent(
            id: _uuid.v4(),
            departureId: departure.id,
            revisionId: revision.id,
            kind: kind,
            at: DateTime.now().toUtc().toIso8601String(),
          ),
        ],
      ),
    );
  }

  Future<bool> importWorkspace(
    Workspace incoming, {
    bool replace = false,
  }) async {
    final existing = state.workspace;
    if (replace) {
      return _error(
        'Penggantian seluruh database tidak tersedia; import digabung agar histori tetap aman.',
      );
    }
    final imported = incoming.routes
        .where((r) => !existing.routes.any((e) => e.id == r.id))
        .toList();
    if (imported.isEmpty) {
      return _error('Data sudah diimpor; tidak ada rute baru.');
    }
    return _save(
      existing.copyWith(
        routes: [...existing.routes, ...imported],
        activeRouteId: imported.first.id,
        events: [
          ...existing.events,
          ...incoming.events.where(
            (e) => !existing.events.any(
              (old) =>
                  old.id == e.id ||
                  (old.departureId == e.departureId && old.kind == e.kind),
            ),
          ),
        ],
        history: [...existing.history, ...incoming.history],
      ),
    );
  }

  bool _error(String message) {
    state = AppState(state.workspace, error: message);
    return false;
  }
}

Workspace sampleWorkspace(DateTime now) {
  const numbers = [
    1000,
    1001,
    5,
    6,
    7,
    8,
    10,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    756,
    88,
    92,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    33,
    34,
    35,
    36,
    2,
    4,
    79,
    97,
    3,
  ];
  final units = numbers
      .map((n) => FleetUnit(id: 'jak115:$n', number: '$n'))
      .toList();
  var route = HedgeRoute(
    id: 'r_jak115',
    name: 'JAK.115',
    color: 0xffff9800,
    units: units,
    order: units.map((u) => u.id).toList(),
  );
  route = route.copyWith(
    schedule: const Scheduler().generate(
      route,
      date: serviceDate(now),
      revisionId: 'initial:${serviceDate(now)}',
      createdAt: now,
    ),
  );
  return Workspace(
    routes: [route],
    activeRouteId: route.id,
    date: serviceDate(now),
  );
}
