import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/sync_controller.dart';
import 'package:hedge_flutter/data/sync_service.dart';
import 'package:hedge_flutter/domain/models.dart';

class FakeCloudSyncClient implements CloudSyncClient {
  bool failNext = false;
  int pullCalls = 0;
  int pushCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since) async {
    pullCalls++;
    if (failNext) throw Exception('No network');
    return [
      {'uuid': 'r_jak115', 'code': 'JAK.115', 'name': 'JAK.115', 'units': []}
    ];
  }

  @override
  Future<void> pushOutbox(List<Map<String, dynamic>> items) async {
    pushCalls++;
    if (failNext) throw Exception('Push error');
  }

  final List<Driver> pushedDrivers = [];
  @override
  Future<void> pushDrivers(String routeIdentifier, List<Driver> drivers) async {
    if (failNext) throw Exception('Push drivers error');
    pushedDrivers.addAll(drivers);
  }

  @override
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId) async {
    if (failNext) throw Exception('Delete driver error');
    pushedDrivers.removeWhere((d) => d.id == driverCallNameOrId || d.callName == driverCallNameOrId);
  }
}

void main() {
  test('SyncController reflects syncing and synced state correctly', () async {
    final client = FakeCloudSyncClient();
    final controller = SyncController(client);

    expect(controller.state.status, SyncStatus.offline);

    final syncFuture = controller.syncNow();
    expect(controller.state.status, SyncStatus.syncing);

    await syncFuture;
    expect(controller.state.status, SyncStatus.synced);
    expect(client.pullCalls, 1);
  });

  test('SyncController falls back to offline on network failure', () async {
    final client = FakeCloudSyncClient()..failNext = true;
    final controller = SyncController(client);

    await controller.syncNow();
    expect(controller.state.status, SyncStatus.offline);
    expect(controller.state.pendingOutboxCount, 0);
  });

  group('mergeCloudRoutesIntoLocal', () {
    test('parses master_drivers and shiftChangeTime into route and units', () {
      final cloudRoutes = [
        {
          'uuid': 'route-uuid-1',
          'route_code': 'JAK.115',
          'route_name': 'Terminal Tanjung Priok - IGI',
          'color': 0xFF00E5FF,
          'config': {
            'start': '05:00',
            'end': '22:00',
            'shiftChangeTime': '13:30',
          },
          'master_units': [
            {'number': '540', 'position': 1, 'active': true},
            {'number': '541', 'position': 2, 'active': true},
          ],
          'master_drivers': [
            {
              'uuid': 'd-uuid-1',
              'full_name': 'Bambang Hariyanto',
              'call_name': 'Bambang',
              'status': 'tetap',
              'default_unit_number': '540',
              'default_shift': 1,
              'active': true,
            },
            {
              'uuid': 'd-uuid-2',
              'full_name': 'Rudi Hartono',
              'call_name': 'Rudi',
              'status': 'tetap',
              'default_unit_number': '540',
              'default_shift': 2,
              'active': true,
            },
            {
              'uuid': 'd-uuid-3',
              'full_name': 'Joko Susilo',
              'call_name': 'Joko',
              'status': 'cadangan',
              'default_unit_number': null,
              'default_shift': null,
              'active': true,
            },
          ],
        }
      ];

      final routes = mergeCloudRoutesIntoLocal(
        currentRoutes: const [],
        cloudRoutes: cloudRoutes,
        now: DateTime.utc(2026, 10, 18, 5, 0),
      );

      expect(routes.length, 1);
      final r = routes.first;
      expect(r.id, 'route-uuid-1');
      expect(r.config.shiftChangeTime, '13:30');
      expect(r.drivers.length, 3);
      expect(r.drivers[0].fullName, 'Bambang Hariyanto');
      expect(r.drivers[0].callName, 'Bambang');
      expect(r.drivers[2].status.name, 'cadangan');

      // Check unit 540 auto-assigned drivers
      final u540 = r.units.firstWhere((u) => u.number == '540');
      expect(u540.driverShift1Id, 'd-uuid-1');
      expect(u540.driverShift2Id, 'd-uuid-2');
    });

    test('parses nested Firestore document format with drivers and units collections directly', () {
      final firestoreRoutes = [
        {
          'uuid': 'd2c14c0e-0bfe-42a5-b7da-8f40fa212e8a',
          'route_code': 'JAK.115',
          'route_name': 'TERM.TANJUNG PRIOK - PEGANGSAAN II IGI',
          'color': 4294940672,
          'position': 1,
          'config': {
            'start': '05:00',
            'end': '22:00',
            'headwayPeak': 5,
            'headwayNormal': 10,
          },
          'units': [
            {'number': 'KWK 222157', 'position': 0, 'active': true},
          ],
          'drivers': [
            {
              'uuid': '572b68a5-c71e-4b94-9d1e-7687107778dd',
              'full_name': 'Mansyur',
              'call_name': 'Mansur',
              'status': 'tetap',
              'default_unit_number': 'KWK 222157',
              'default_shift': 1,
              'active': true,
            },
          ],
        }
      ];

      final routes = mergeCloudRoutesIntoLocal(
        currentRoutes: const [],
        cloudRoutes: firestoreRoutes,
        now: DateTime.utc(2026, 11, 9, 8, 0),
      );

      expect(routes.length, 1);
      final r = routes.first;
      expect(r.id, 'd2c14c0e-0bfe-42a5-b7da-8f40fa212e8a');
      expect(r.drivers.length, 1);
      expect(r.drivers.first.callName, 'Mansur');
      expect(r.units.first.number, 'KWK 222157');
      expect(r.units.first.driverShift1Id, '572b68a5-c71e-4b94-9d1e-7687107778dd');
    });

    test('preserves existing custom driver assignments on units when updating route', () {
      final existingRoute = HedgeRoute(
        id: 'route-uuid-1',
        name: 'JAK.115 — Terminal Tanjung Priok - IGI',
        color: 0xFF00E5FF,
        units: const [
          FleetUnit(
            id: 'JAK.115:540',
            number: '540',
            driverShift1Id: 'custom-shift1',
            driverShift2Id: 'custom-shift2',
          ),
        ],
        order: const ['JAK.115:540'],
      );

      final cloudRoutes = [
        {
          'uuid': 'route-uuid-1',
          'route_code': 'JAK.115',
          'route_name': 'Terminal Tanjung Priok - IGI',
          'color': 0xFF00E5FF,
          'master_units': [
            {'number': '540', 'position': 1, 'active': true},
          ],
          'master_drivers': [
            {
              'uuid': 'default-d1',
              'full_name': 'Default Driver',
              'call_name': 'Default',
              'status': 'tetap',
              'default_unit_number': '540',
              'default_shift': 1,
              'active': true,
            },
          ],
        }
      ];

      final routes = mergeCloudRoutesIntoLocal(
        currentRoutes: [existingRoute],
        cloudRoutes: cloudRoutes,
        now: DateTime.utc(2026, 10, 18, 5, 0),
      );

      final u = routes.first.units.first;
      expect(u.driverShift1Id, 'custom-shift1');
      expect(u.driverShift2Id, 'custom-shift2');
    });
  });
}
