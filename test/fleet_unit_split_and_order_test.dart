import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
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

void main() {
  group('splitUnitNumber Parser Tests', () {
    test('Memisahkan kode operator spasi angka nomor body', () {
      final res = splitUnitNumber('KLM 540');
      expect(res.operator, 'KLM');
      expect(res.number, '540');
    });

    test('Memisahkan kode operator strip angka nomor body', () {
      final res = splitUnitNumber('KWK-001');
      expect(res.operator, 'KWK');
      expect(res.number, '001');
    });

    test('Memisahkan kode operator titik angka nomor body', () {
      final res = splitUnitNumber('TSU.102');
      expect(res.operator, 'TSU');
      expect(res.number, '102');
    });

    test('Memisahkan kode operator huruf bersambung spasi angka', () {
      final res = splitUnitNumber('JAK 12');
      expect(res.operator, 'JAK');
      expect(res.number, '12');
    });

    test('Unit nomor murni angka tanpa prefix operator', () {
      final res = splitUnitNumber('1865');
      expect(res.operator, '');
      expect(res.number, '1865');
    });

    test('Unit nomor pendek angka saja', () {
      final res = splitUnitNumber('26');
      expect(res.operator, '');
      expect(res.number, '26');
    });

    test('Handling spasi berlebih pada input unit', () {
      final res = splitUnitNumber('   KWK   448   ');
      expect(res.operator, 'KWK');
      expect(res.number, '448');
    });
  });

  group('WorkspaceController setUnitsActive Order Tests', () {
    test('Mengaktifkan unit-unit dengan urutan seleksi [1, 2, 3] menempatkannya di depan rotasi', () async {
      final repo = MockWorkspaceRepository();
      final units = [
        const FleetUnit(id: 'u1', number: 'KLM 540', active: false),
        const FleetUnit(id: 'u2', number: 'KWK 001', active: false),
        const FleetUnit(id: 'u3', number: 'TSU 102', active: false),
        const FleetUnit(id: 'u4', number: 'JAK 12', active: true),
      ];
      final initialRoute = HedgeRoute(
        id: 'r1',
        name: 'JAK.01',
        color: 0xffff9800,
        units: units,
        order: ['u4', 'u1', 'u2', 'u3'],
      );
      final workspace = Workspace(
        routes: [initialRoute],
        activeRouteId: 'r1',
        date: '2026-10-17',
      );
      repo.stored = workspace;

      final container = ProviderContainer(
        overrides: [
          initialWorkspaceProvider.overrideWithValue(workspace),
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(workspaceProvider.notifier);

      // Dispatcher menandai u3 sebagai [1], lalu u1 sebagai [2]
      final selectedOrder = ['u3', 'u1'];
      final success = await controller.setUnitsActive(initialRoute, selectedOrder, true);

      expect(success, isTrue);
      final updatedRoute = container.read(workspaceProvider).workspace.activeRoute!;

      // Unit u3 dan u1 harus aktif
      expect(updatedRoute.units.firstWhere((u) => u.id == 'u3').active, isTrue);
      expect(updatedRoute.units.firstWhere((u) => u.id == 'u1').active, isTrue);

      // Urutan rotasi harus menempatkan [u3, u1] di depan, disusul unit lain [u4, u2]
      expect(updatedRoute.order, ['u3', 'u1', 'u4', 'u2']);

      // activeUnits harus mencakup u3, u1, u4 sesuai urutan order baru
      final activeIds = updatedRoute.activeUnits.map((u) => u.id).toList();
      expect(activeIds, ['u3', 'u1', 'u4']);
    });

    test('Menonaktifkan unit mengeluarkannya dari route.order', () async {
      final repo = MockWorkspaceRepository();
      final units = [
        const FleetUnit(id: 'u1', number: 'KLM 540', active: true),
        const FleetUnit(id: 'u2', number: 'KWK 001', active: true),
        const FleetUnit(id: 'u3', number: 'TSU 102', active: true),
      ];
      final initialRoute = HedgeRoute(
        id: 'r1',
        name: 'JAK.01',
        color: 0xffff9800,
        units: units,
        order: ['u1', 'u2', 'u3'],
      );
      final workspace = Workspace(
        routes: [initialRoute],
        activeRouteId: 'r1',
        date: '2026-10-17',
      );
      repo.stored = workspace;

      final container = ProviderContainer(
        overrides: [
          initialWorkspaceProvider.overrideWithValue(workspace),
          repositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(workspaceProvider.notifier);

      final success = await controller.setUnitsActive(initialRoute, ['u2'], false);
      expect(success, isTrue);

      final updatedRoute = container.read(workspaceProvider).workspace.activeRoute!;
      expect(updatedRoute.units.firstWhere((u) => u.id == 'u2').active, isFalse);
      expect(updatedRoute.order, ['u1', 'u3']);
    });
  });
}
