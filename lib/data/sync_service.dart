import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models.dart';
import '../domain/scheduler.dart';

abstract interface class CloudSyncClient {
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since);
  Future<void> pushOutbox(List<Map<String, dynamic>> items);
}

class SupabaseCloudSyncClient implements CloudSyncClient {
  SupabaseCloudSyncClient({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;
  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @override
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since) async {
    try {
      var query = _supabase
          .from('master_routes')
          .select('*, master_units(*)');

      if (since != null) {
        query = query.gt('updated_at', since.toUtc().toIso8601String());
      }

      final res = await query.order('position', ascending: true);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('SupabaseCloudSyncClient pullRoutes error: $e');
      rethrow;
    }
  }

  @override
  Future<void> pushOutbox(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    try {
      await _supabase.from('outbox').insert(items);
    } catch (e) {
      debugPrint('SupabaseCloudSyncClient pushOutbox error: $e');
      rethrow;
    }
  }
}

List<HedgeRoute> mergeCloudRoutesIntoLocal({
  required List<HedgeRoute> currentRoutes,
  required List<Map<String, dynamic>> cloudRoutes,
  required DateTime now,
}) {
  if (cloudRoutes.isEmpty) return currentRoutes;

  final updatedRoutes = <HedgeRoute>[...currentRoutes];

  for (final raw in cloudRoutes) {
    final uuid = raw['uuid'] as String?;
    final code = raw['route_code'] as String? ?? 'RUTE';
    final name = raw['route_name'] as String? ?? code;
    final displayName = '$code — $name';
    final color = raw['color'] is int ? raw['color'] as int : 0xFFFF9800;

    final rawUnits = (raw['master_units'] as List? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    // Sort by position
    rawUnits.sort((a, b) {
      final posA = a['position'] as int? ?? 0;
      final posB = b['position'] as int? ?? 0;
      return posA.compareTo(posB);
    });

    final fleetUnits = <FleetUnit>[];
    final order = <String>[];

    for (final u in rawUnits) {
      final numStr = u['number'] as String? ?? '';
      final unitId = '$code:$numStr';
      final active = u['active'] as bool? ?? true;
      fleetUnits.add(FleetUnit(id: unitId, number: numStr, active: active));
      if (active) order.add(unitId);
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

    final existingIndex = updatedRoutes.indexWhere((r) => r.id == uuid || r.name.startsWith(code));

    if (existingIndex >= 0) {
      final existing = updatedRoutes[existingIndex];
      // Keep existing schedule if valid
      updatedRoutes[existingIndex] = existing.copyWith(
        name: displayName,
        color: color,
        units: fleetUnits.isNotEmpty ? fleetUnits : existing.units,
        order: order.isNotEmpty ? order : existing.order,
        config: config,
      );
    } else {
      var newRoute = HedgeRoute(
        id: uuid ?? code,
        name: displayName,
        color: color,
        units: fleetUnits,
        order: order,
        config: config,
      );
      if (newRoute.activeUnits.isNotEmpty) {
        try {
          final schedule = const Scheduler().generate(
            newRoute,
            date: serviceDate(now),
            revisionId: 'initial:${serviceDate(now)}:${newRoute.id}',
            createdAt: now,
          );
          newRoute = newRoute.copyWith(schedule: schedule);
        } catch (_) {}
      }
      updatedRoutes.add(newRoute);
    }
  }

  return updatedRoutes;
}
