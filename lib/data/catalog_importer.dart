import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models.dart';
import '../domain/scheduler.dart';

Workspace catalogToWorkspace(String jsonString, DateTime now) {
  final Map<String, dynamic> data = jsonDecode(jsonString) as Map<String, dynamic>;
  final rawRoutes = (data['routes'] as List? ?? <dynamic>[]).cast<Map<String, dynamic>>();

  final routes = <HedgeRoute>[];

  for (final raw in rawRoutes) {
    final routeCode = raw['code'] as String? ?? 'RUTE';
    final routeName = raw['name'] as String? ?? routeCode;
    final displayName = '$routeCode — $routeName';
    final uuid = raw['uuid'] as String? ?? routeCode;
    final color = raw['color'] is int ? raw['color'] as int : 0xFFFF9800;

    final unitList = (raw['units'] as List? ?? <dynamic>[]).map((u) => u.toString()).toList();
    final fleetUnits = <FleetUnit>[];
    final order = <String>[];

    for (var i = 0; i < unitList.length; i++) {
      final unitNum = unitList[i];
      final unitId = '$routeCode:$unitNum';
      fleetUnits.add(FleetUnit(id: unitId, number: unitNum, active: true));
      order.add(unitId);
    }

    final rawConfig = raw['config'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final config = PlanConfig(
      start: rawConfig['start'] as String? ?? '05:00',
      end: rawConfig['end'] as String? ?? '22:00',
      rounds: 8,
      startRound: 1,
      slowFirst: false,
      peakEnabled: false,
    );

    var route = HedgeRoute(
      id: uuid,
      name: displayName,
      color: color,
      units: fleetUnits,
      order: order,
      config: config,
    );

    // Generate schedule if route has active units
    if (route.activeUnits.isNotEmpty) {
      try {
        final generated = const Scheduler().generate(
          route,
          date: serviceDate(now),
          revisionId: 'initial:${serviceDate(now)}:${route.id}',
          createdAt: now,
        );
        route = route.copyWith(schedule: generated);
      } catch (_) {
        // Fallback gracefully without schedule if constraints differ
      }
    }

    routes.add(route);
  }

  final activeId = routes.isNotEmpty ? routes.first.id : null;

  return Workspace(
    routes: routes,
    activeRouteId: activeId,
    date: serviceDate(now),
    theme: 'dark',
  );
}

Future<Workspace> loadDefaultCatalogWorkspace(DateTime now) async {
  final content = await rootBundle.loadString('assets/data/routes_catalog.json');
  return catalogToWorkspace(content, now);
}
