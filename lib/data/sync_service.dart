import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models.dart';
import '../domain/scheduler.dart';

abstract interface class CloudSyncClient {
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since);
  Future<void> pushOutbox(List<Map<String, dynamic>> items);
  Future<void> pushDrivers(String routeIdentifier, List<Driver> drivers);
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId);
}

class FirestoreCloudSyncClient implements CloudSyncClient {
  FirestoreCloudSyncClient({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('routes');
      if (since != null) {
        query = query.where('updated_at', isGreaterThan: since.toUtc().toIso8601String());
      }
      final snapshot = await query.orderBy('position').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uuid'] ??= doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('FirestoreCloudSyncClient pullRoutes error: $e');
      rethrow;
    }
  }

  @override
  Future<void> pushOutbox(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    try {
      final batch = _firestore.batch();
      for (final item in items) {
        final docRef = _firestore.collection('outbox').doc();
        final payload = Map<String, dynamic>.from(item);
        payload['synced_at'] = FieldValue.serverTimestamp();
        batch.set(docRef, payload);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreCloudSyncClient pushOutbox error: $e');
      rethrow;
    }
  }

  @override
  Future<void> pushDrivers(String routeIdentifier, List<Driver> drivers) async {
    if (drivers.isEmpty) return;
    try {
      String routeDocId = routeIdentifier;
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(routeIdentifier);

      if (!isUuid) {
        final code = routeIdentifier.contains('—')
            ? routeIdentifier.split('—').first.trim()
            : (routeIdentifier.contains('-')
                ? routeIdentifier.split('-').first.trim()
                : routeIdentifier.trim());
        final snapshot = await _firestore
            .collection('routes')
            .where('route_code', isEqualTo: code)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          routeDocId = snapshot.docs.first.id;
        } else {
          debugPrint('pushDrivers: Route document tidak ditemukan untuk $routeIdentifier');
          return;
        }
      }

      final payload = drivers.map((d) {
        return <String, dynamic>{
          'id': d.id,
          'uuid': d.id,
          'route_uuid': routeDocId,
          'full_name': d.fullName,
          'call_name': d.callName,
          'status': d.status == DriverStatus.cadangan ? 'cadangan' : 'tetap',
          'default_unit_number': d.defaultUnitNumber,
          'default_shift': d.defaultShift,
          'active': d.active,
        };
      }).toList();

      await _firestore.collection('routes').doc(routeDocId).set({
        'drivers': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreCloudSyncClient pushDrivers error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId) async {
    try {
      String routeDocId = routeIdentifier;
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(routeIdentifier);

      DocumentSnapshot<Map<String, dynamic>>? doc;
      if (isUuid) {
        doc = await _firestore.collection('routes').doc(routeDocId).get();
      } else {
        final code = routeIdentifier.contains('—')
            ? routeIdentifier.split('—').first.trim()
            : (routeIdentifier.contains('-')
                ? routeIdentifier.split('-').first.trim()
                : routeIdentifier.trim());
        final snapshot = await _firestore
            .collection('routes')
            .where('route_code', isEqualTo: code)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          doc = snapshot.docs.first;
          routeDocId = doc.id;
        }
      }

      if (doc != null && doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawDrivers = ((data['drivers'] ?? data['master_drivers']) as List? ?? <dynamic>[])
            .cast<Map<String, dynamic>>();
        final filtered = rawDrivers.where((d) {
          final idMatch = d['id']?.toString() == driverCallNameOrId ||
              d['uuid']?.toString() == driverCallNameOrId;
          final callNameMatch = d['call_name']?.toString() == driverCallNameOrId;
          return !idMatch && !callNameMatch;
        }).toList();

        await _firestore.collection('routes').doc(routeDocId).set({
          'drivers': filtered,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FirestoreCloudSyncClient deleteDriverCloud error: $e');
    }
  }
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
          .select('*, master_units(*), master_drivers(*)');

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

  @override
  Future<void> pushDrivers(String routeIdentifier, List<Driver> drivers) async {
    if (drivers.isEmpty) return;
    try {
      String routeUuid = routeIdentifier;
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(routeIdentifier);
      if (!isUuid) {
        final code = routeIdentifier.contains('—')
            ? routeIdentifier.split('—').first.trim()
            : (routeIdentifier.contains('-')
                ? routeIdentifier.split('-').first.trim()
                : routeIdentifier.trim());
        final res = await _supabase
            .from('master_routes')
            .select('uuid')
            .ilike('route_code', '$code%')
            .limit(1)
            .maybeSingle();
        if (res != null && res['uuid'] != null) {
          routeUuid = res['uuid'] as String;
        } else {
          debugPrint('pushDrivers: Route UUID tidak ditemukan untuk $routeIdentifier');
          return;
        }
      }

      final payload = drivers.map((d) {
        final map = <String, dynamic>{
          'route_uuid': routeUuid,
          'full_name': d.fullName,
          'call_name': d.callName,
          'status': d.status == DriverStatus.cadangan ? 'cadangan' : 'tetap',
          'default_unit_number': d.defaultUnitNumber,
          'default_shift': d.defaultShift,
          'active': d.active,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };
        if (RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(d.id)) {
          map['uuid'] = d.id;
        }
        return map;
      }).toList();

      await _supabase.from('master_drivers').upsert(
        payload,
        onConflict: 'route_uuid,call_name',
      );
    } catch (e) {
      debugPrint('SupabaseCloudSyncClient pushDrivers error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId) async {
    try {
      String routeUuid = routeIdentifier;
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(routeIdentifier);
      if (!isUuid) {
        final code = routeIdentifier.contains('—')
            ? routeIdentifier.split('—').first.trim()
            : (routeIdentifier.contains('-')
                ? routeIdentifier.split('-').first.trim()
                : routeIdentifier.trim());
        final res = await _supabase
            .from('master_routes')
            .select('uuid')
            .ilike('route_code', '$code%')
            .limit(1)
            .maybeSingle();
        if (res != null && res['uuid'] != null) {
          routeUuid = res['uuid'] as String;
        } else {
          return;
        }
      }

      await _supabase
          .from('master_drivers')
          .delete()
          .eq('route_uuid', routeUuid)
          .or('uuid.eq.$driverCallNameOrId,call_name.eq.$driverCallNameOrId');
    } catch (e) {
      debugPrint('SupabaseCloudSyncClient deleteDriverCloud error: $e');
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

    final rawDrivers = ((raw['drivers'] ?? raw['master_drivers']) as List? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    final drivers = <Driver>[];
    for (final d in rawDrivers) {
      final dUuid = d['uuid'] as String? ?? (d['id']?.toString() ?? '');
      final fullName = d['full_name'] as String? ?? '';
      final callName = d['call_name'] as String? ?? fullName;
      final statusStr = d['status'] as String? ?? 'tetap';
      final status = statusStr.toLowerCase() == 'cadangan'
          ? DriverStatus.cadangan
          : DriverStatus.tetap;
      final defaultUnit = d['default_unit_number'] as String?;
      final defaultShift = d['default_shift'] as int?;
      final active = d['active'] as bool? ?? true;

      drivers.add(Driver(
        id: dUuid,
        routeId: uuid ?? code,
        fullName: fullName,
        callName: callName,
        status: status,
        defaultUnitNumber: defaultUnit,
        defaultShift: defaultShift,
        active: active,
      ));
    }

    final rawUnits = ((raw['units'] ?? raw['master_units']) as List? ?? <dynamic>[])
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

      String? shift1Id;
      String? shift2Id;
      for (final d in drivers) {
        if (d.active && d.defaultUnitNumber == numStr) {
          if (d.defaultShift == 1) shift1Id = d.id;
          if (d.defaultShift == 2) shift2Id = d.id;
        }
      }

      fleetUnits.add(FleetUnit(
        id: unitId,
        number: numStr,
        active: active,
        driverShift1Id: shift1Id,
        driverShift2Id: shift2Id,
      ));
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
      shiftChangeTime: rawConfig['shiftChangeTime'] as String? ?? '13:00',
    );

    final existingIndex = updatedRoutes.indexWhere((r) => r.id == uuid || r.name.startsWith(code));

    if (existingIndex >= 0) {
      final existing = updatedRoutes[existingIndex];
      // Keep existing unit driver assignments if present
      final mergedUnits = fleetUnits.isNotEmpty
          ? fleetUnits.map((u) {
              final exUnit = existing.units.where((e) => e.id == u.id).firstOrNull;
              if (exUnit != null && (exUnit.driverShift1Id != null || exUnit.driverShift2Id != null)) {
                return u.copyWith(
                  driverShift1Id: exUnit.driverShift1Id,
                  driverShift2Id: exUnit.driverShift2Id,
                );
              }
              return u;
            }).toList()
          : existing.units;

      updatedRoutes[existingIndex] = existing.copyWith(
        name: displayName,
        color: color,
        units: mergedUnits,
        order: order.isNotEmpty ? order : existing.order,
        drivers: drivers.isNotEmpty ? drivers : existing.drivers,
        config: config,
      );
    } else {
      var newRoute = HedgeRoute(
        id: uuid ?? code,
        name: displayName,
        color: color,
        units: fleetUnits,
        order: order,
        drivers: drivers,
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
