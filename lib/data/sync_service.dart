import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models.dart';
import '../domain/scheduler.dart';

abstract interface class CloudSyncClient {
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since);
  Future<void> pushOutbox(List<Map<String, dynamic>> items);
  Future<void> pushDrivers(String routeIdentifier, List<Driver> drivers);
  Future<int> pushAllDrivers(List<HedgeRoute> routes);
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId);
}

class FirestoreCloudSyncClient implements CloudSyncClient {
  FirestoreCloudSyncClient({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  final FirebaseFirestore? _injectedFirestore;

  FirebaseFirestore? get _firestore {
    try {
      return _injectedFirestore ?? FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since) async {
    final db = _firestore;
    if (db == null) return const [];
    try {
      Query<Map<String, dynamic>> query = db.collection('routes');
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
    final db = _firestore;
    if (db == null) return;
    try {
      final batch = db.batch();
      for (final item in items) {
        final docRef = db.collection('outbox').doc();
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
    final db = _firestore;
    if (db == null) {
      throw StateError('Firebase Cloud Firestore belum terinisialisasi.');
    }
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
        final snapshot = await db
            .collection('routes')
            .where('route_code', isEqualTo: code)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          routeDocId = snapshot.docs.first.id;
        } else {
          final snapshotId = await db
              .collection('routes')
              .where('id', isEqualTo: routeIdentifier)
              .limit(1)
              .get();
          if (snapshotId.docs.isNotEmpty) {
            routeDocId = snapshotId.docs.first.id;
          } else {
            throw StateError('Rute "$routeIdentifier" tidak ditemukan di database Cloud.');
          }
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

      await db.collection('routes').doc(routeDocId).set({
        'drivers': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreCloudSyncClient pushDrivers error: $e');
      rethrow;
    }
  }

  @override
  Future<int> pushAllDrivers(List<HedgeRoute> routes) async {
    int total = 0;
    for (final route in routes) {
      if (route.drivers.isNotEmpty) {
        await pushDrivers(route.id, route.drivers);
        total += route.drivers.length;
      }
    }
    return total;
  }

  @override
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId) async {
    final db = _firestore;
    if (db == null) return;
    try {
      String routeDocId = routeIdentifier;
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(routeIdentifier);

      DocumentSnapshot<Map<String, dynamic>>? doc;
      if (isUuid) {
        doc = await db.collection('routes').doc(routeDocId).get();
      } else {
        final code = routeIdentifier.contains('—')
            ? routeIdentifier.split('—').first.trim()
            : (routeIdentifier.contains('-')
                ? routeIdentifier.split('-').first.trim()
                : routeIdentifier.trim());
        final snapshot = await db
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

        await db.collection('routes').doc(routeDocId).set({
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
  SupabaseClient? get _supabase {
    try {
      return _client ?? Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Pemetaan statis kode rute ke UUID untuk fallback offline/saat master_routes kosong
  static const Map<String, String> _catalogRouteUuids = {
    'JAK.01': '81128634-e279-4a94-8a96-771ad974998a',
    'JAK.05': '839e4364-c4cb-4ac5-ac1e-99468bcbacf0',
    'JAK.110A': 'feae622c-a605-4323-833b-7a1e85d9090f',
    'JAK.113': 'bb786943-46f7-49f0-9e20-4ea03477b2ab',
    'JAK.115': 'd2c14c0e-0bfe-42a5-b7da-8f40fa212e8a',
    'JAK.117': '7a583fe5-1d99-40c9-a2c0-688b3d751a7f',
    'JAK.118': '63ed5228-714c-4962-87d5-035f552b784d',
    'JAK.120': '469ec84b-d65b-4ac2-94cb-356ae25e0779',
    'JAK.15': 'bcb994a0-281e-4ef2-b460-97527898f0ee',
    'JAK.29': '7c25e3e9-a5ed-4b35-9acc-6855193309b9',
    'JAK.58': 'a9732ad1-f1d8-47d5-9c92-ae6f8030a1b9',
    'JAK.60': 'cdf02d4c-c8e6-4144-a099-dc76ac2c01a2',
    'JAK.76': '6807ab0e-6745-4989-9432-d4e1231d7cb0',
    'JAK.77': 'a28444e3-501c-48f8-83d4-00cd7a243837',
    'JAK.87': '91c38d28-f0d6-475d-9423-02281ee1e7f3',
    'JAK.88': 'df769254-1cac-481a-8dcc-89a1bbdfd27e',
    'JAK.89': '4ec45c1f-5e72-46c1-b669-53d1af60ac94',
    'JAK.90': '106c6f31-52f5-40a1-be71-fbcd85dfdf9f',
  };

  @override
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since) async {
    final client = _supabase;
    if (client == null) return const [];
    try {
      var query = client
          .from('master_routes')
          .select('*, master_units(*), master_drivers(*)');

      if (since != null) {
        query = query.gt('updated_at', since.toUtc().toIso8601String());
      }

      final res = await query.order('position', ascending: true);
      final list = List<Map<String, dynamic>>.from(res as List);
      if (list.isNotEmpty) return list;

      // Fallback Cerdas: Jika master_routes belum di-seed, tarik langsung data master_drivers
      final driversRes = await client.from('master_drivers').select();
      final rawDrivers = List<Map<String, dynamic>>.from(driversRes as List);
      if (rawDrivers.isNotEmpty) {
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final d in rawDrivers) {
          final rUuid = d['route_uuid']?.toString() ?? '';
          if (rUuid.isNotEmpty) {
            grouped.putIfAbsent(rUuid, () => []).add(d);
          }
        }
        return grouped.entries.map((e) => {
          'uuid': e.key,
          'drivers': e.value,
        }).toList();
      }

      return const [];
    } catch (e) {
      debugPrint('SupabaseCloudSyncClient pullRoutes error: $e');
      rethrow;
    }
  }

  @override
  Future<void> pushOutbox(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final client = _supabase;
    if (client == null) return;
    try {
      await client.from('outbox').insert(items);
    } catch (e) {
      debugPrint('SupabaseCloudSyncClient pushOutbox error: $e');
      rethrow;
    }
  }

  @override
  Future<void> pushDrivers(String routeIdentifier, List<Driver> drivers) async {
    if (drivers.isEmpty) return;
    final client = _supabase;
    if (client == null) {
      throw StateError('Supabase Client belum terinisialisasi.');
    }
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
        try {
          final res = await client
              .from('master_routes')
              .select('uuid')
              .ilike('route_code', '$code%')
              .limit(1)
              .maybeSingle();
          if (res != null && res['uuid'] != null) {
            routeUuid = res['uuid'] as String;
          } else {
            routeUuid = _catalogRouteUuids[code] ?? routeIdentifier;
          }
        } catch (_) {
          routeUuid = _catalogRouteUuids[code] ?? routeIdentifier;
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

      await client.from('master_drivers').upsert(
        payload,
        onConflict: 'route_uuid,call_name',
      );
    } catch (e) {
      debugPrint('SupabaseCloudSyncClient pushDrivers error: $e');
      rethrow;
    }
  }

  @override
  Future<int> pushAllDrivers(List<HedgeRoute> routes) async {
    int total = 0;
    for (final route in routes) {
      if (route.drivers.isNotEmpty) {
        await pushDrivers(route.id, route.drivers);
        total += route.drivers.length;
      }
    }
    return total;
  }

  @override
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId) async {
    final client = _supabase;
    if (client == null) return;
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
        try {
          final res = await client
              .from('master_routes')
              .select('uuid')
              .ilike('route_code', '$code%')
              .limit(1)
              .maybeSingle();
          if (res != null && res['uuid'] != null) {
            routeUuid = res['uuid'] as String;
          } else {
            routeUuid = _catalogRouteUuids[code] ?? routeIdentifier;
          }
        } catch (_) {
          routeUuid = _catalogRouteUuids[code] ?? routeIdentifier;
        }
      }

      await client
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

    final existingIndex = updatedRoutes.indexWhere(
      (r) => r.id == uuid || (r.name.startsWith(code) && code != 'RUTE'),
    );

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
          : existing.units.map((u) {
              String? shift1Id = u.driverShift1Id;
              String? shift2Id = u.driverShift2Id;
              for (final d in drivers) {
                if (d.active && d.defaultUnitNumber == u.number) {
                  if (d.defaultShift == 1 && shift1Id == null) shift1Id = d.id;
                  if (d.defaultShift == 2 && shift2Id == null) shift2Id = d.id;
                }
              }
              return u.copyWith(
                driverShift1Id: shift1Id,
                driverShift2Id: shift2Id,
              );
            }).toList();

      updatedRoutes[existingIndex] = existing.copyWith(
        name: raw['route_code'] != null ? displayName : existing.name,
        color: raw['color'] != null ? color : existing.color,
        units: mergedUnits,
        order: order.isNotEmpty ? order : existing.order,
        drivers: drivers.isNotEmpty ? drivers : existing.drivers,
        config: raw['config'] != null ? config : existing.config,
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
