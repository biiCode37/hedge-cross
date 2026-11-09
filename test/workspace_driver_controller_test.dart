import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/data/sync_service.dart';
import 'package:hedge_flutter/data/workspace_repository.dart';
import 'package:hedge_flutter/domain/models.dart';

class MockWorkspaceRepository implements WorkspaceRepository {
  Workspace? stored;
  @override
  Future<Workspace?> load() async => stored;
  @override
  Future<void> save(Workspace workspace) async {
    stored = workspace;
  }
  @override
  Future<void> close() async {}
}

class MockCloudSyncClient implements CloudSyncClient {
  final List<Driver> pushed = [];
  @override
  Future<void> pushDrivers(String routeIdentifier, List<Driver> drivers) async {
    pushed.addAll(drivers);
  }
  @override
  Future<int> pushAllDrivers(List<HedgeRoute> routes) async {
    for (final r in routes) {
      pushed.addAll(r.drivers);
    }
    return pushed.length;
  }
  @override
  Future<void> deleteDriverCloud(String routeIdentifier, String driverCallNameOrId) async {}
  @override
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since) async => [];
  @override
  Future<void> pushOutbox(List<Map<String, dynamic>> items) async {}
}

void main() {
  group('WorkspaceController Driver Operations', () {
    late MockWorkspaceRepository repo;
    late ProviderContainer container;
    late WorkspaceController controller;
    late HedgeRoute initialRoute;

    setUp(() {
      repo = MockWorkspaceRepository();
      initialRoute = HedgeRoute(
        id: 'r1',
        name: 'JAK.115',
        color: 0xFF00E5FF,
        units: const [
          FleetUnit(id: 'u1', number: '540', driverShift1Id: 'd1', driverShift2Id: 'd2', active: true),
          FleetUnit(id: 'u2', number: '001', driverShift1Id: 'd3', driverShift2Id: 'd4', active: true),
        ],
        order: const ['u1', 'u2'],
        drivers: const [
          Driver(id: 'd1', routeId: 'r1', fullName: 'Bambang Hariyanto', callName: 'Bambang', defaultUnitNumber: '540', defaultShift: 1),
          Driver(id: 'd2', routeId: 'r1', fullName: 'Rudi Suherman', callName: 'Rudi', defaultUnitNumber: '540', defaultShift: 2),
          Driver(id: 'd3', routeId: 'r1', fullName: 'Agus Santoso', callName: 'Agus', defaultUnitNumber: '001', defaultShift: 1),
          Driver(id: 'd4', routeId: 'r1', fullName: 'Joko Widodo', callName: 'Joko', defaultUnitNumber: '001', defaultShift: 2),
          Driver(id: 'd5', routeId: 'r1', fullName: 'Dedi Mulyadi', callName: 'Dedi', status: DriverStatus.cadangan),
        ],
      );
      final workspace = Workspace(
        routes: [initialRoute],
        activeRouteId: 'r1',
        date: '2026-10-18',
      );
      repo.stored = workspace;

      container = ProviderContainer(
        overrides: [
          initialWorkspaceProvider.overrideWithValue(workspace),
          repositoryProvider.overrideWithValue(repo),
        ],
      );

      controller = container.read(workspaceProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('addDriver menambahkan driver baru ke route', () async {
      const newDriver = Driver(
        id: 'd6',
        routeId: 'r1',
        fullName: 'Hendra Setiawan',
        callName: 'Hendra',
        status: DriverStatus.cadangan,
      );

      final ok = await controller.addDriver(initialRoute, newDriver);
      expect(ok, isTrue);

      final route = container.read(workspaceProvider).workspace.activeRoute!;
      expect(route.drivers.length, 6);
      expect(route.drivers.any((d) => d.id == 'd6'), isTrue);
    });

    test('updateDriver memperbarui data driver yang ada', () async {
      final updated = initialRoute.drivers.first.copyWith(callName: 'Pak Bambang');
      final ok = await controller.updateDriver(initialRoute, updated);
      expect(ok, isTrue);

      final route = container.read(workspaceProvider).workspace.activeRoute!;
      expect(route.drivers.firstWhere((d) => d.id == 'd1').callName, 'Pak Bambang');
    });

    test('deleteDriver menghapus driver dan membersihkan assignment di unit', () async {
      final ok = await controller.deleteDriver(initialRoute, 'd1');
      expect(ok, isTrue);

      final route = container.read(workspaceProvider).workspace.activeRoute!;
      expect(route.drivers.any((d) => d.id == 'd1'), isFalse);
      expect(route.units.firstWhere((u) => u.id == 'u1').driverShift1Id, isNull);
    });

    test('swapUnitDrivers menukar driverShift1Id dan driverShift2Id khusus unit tersebut', () async {
      final ok = await controller.swapUnitDrivers(initialRoute, 'u1');
      expect(ok, isTrue);

      final route = container.read(workspaceProvider).workspace.activeRoute!;
      final u1 = route.units.firstWhere((u) => u.id == 'u1');
      expect(u1.driverShift1Id, 'd2');
      expect(u1.driverShift2Id, 'd1');

      // Unit u2 tidak boleh berubah
      final u2 = route.units.firstWhere((u) => u.id == 'u2');
      expect(u2.driverShift1Id, 'd3');
      expect(u2.driverShift2Id, 'd4');
    });

    test('rollAllDrivers menukar driverShift1Id dan driverShift2Id pada semua unit rute', () async {
      final ok = await controller.rollAllDrivers(initialRoute);
      expect(ok, isTrue);

      final route = container.read(workspaceProvider).workspace.activeRoute!;
      final u1 = route.units.firstWhere((u) => u.id == 'u1');
      expect(u1.driverShift1Id, 'd2');
      expect(u1.driverShift2Id, 'd1');

      final u2 = route.units.firstWhere((u) => u.id == 'u2');
      expect(u2.driverShift1Id, 'd4');
      expect(u2.driverShift2Id, 'd3');
    });

    test('autoPairDefaultDrivers memasangkan supir tetap bawaan ke unitnya secara otomatis', () async {
      // Buat unit baru tanpa supir
      final routeUnassigned = initialRoute.copyWith(
        units: const [
          FleetUnit(id: 'u1', number: '540', active: true),
          FleetUnit(id: 'u2', number: '001', active: true),
        ],
      );

      final ok = await controller.autoPairDefaultDrivers(routeUnassigned);
      expect(ok, isTrue);

      final route = container.read(workspaceProvider).workspace.activeRoute!;
      final u1 = route.units.firstWhere((u) => u.id == 'u1');
      expect(u1.driverShift1Id, 'd1');
      expect(u1.driverShift2Id, 'd2');

      final u2 = route.units.firstWhere((u) => u.id == 'u2');
      expect(u2.driverShift1Id, 'd3');
      expect(u2.driverShift2Id, 'd4');
    });

    test('syncAllDriversToCloud mengirim seluruh pramudi dari semua rute', () async {
      final syncClient = MockCloudSyncClient();
      final localContainer = ProviderContainer(
        overrides: [
          initialWorkspaceProvider.overrideWithValue(repo.stored!),
          repositoryProvider.overrideWithValue(repo),
          cloudSyncClientProvider.overrideWithValue(syncClient),
        ],
      );
      final localController = localContainer.read(workspaceProvider.notifier);
      final res = await localController.syncAllDriversToCloud(initialRoute);
      expect(res.success, isTrue);
      expect(res.totalDrivers, 5);
      expect(res.totalRoutes, 1);
      expect(syncClient.pushed.length, 5);
      localContainer.dispose();
    });
  });
}
