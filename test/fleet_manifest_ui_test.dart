import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/data/workspace_repository.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/app.dart';

class TestWorkspaceRepository implements WorkspaceRepository {
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
  testWidgets('Halaman 02 Armada UI Test: Tanpa prefix Unit, split operator & auto-increment selection', (tester) async {
    final repo = TestWorkspaceRepository();
    final units = [
      const FleetUnit(id: 'u1', number: 'KLM 540', active: true),
      const FleetUnit(id: 'u2', number: 'KWK-001', active: false),
      const FleetUnit(id: 'u3', number: '1865', active: true),
    ];
    final route = HedgeRoute(
      id: 'r_test',
      name: 'JAK.01',
      color: 0xffff9800,
      units: units,
      order: ['u1', 'u2', 'u3'],
    );
    final workspace = Workspace(
      routes: [route],
      activeRouteId: route.id,
      date: '2026-10-17',
      theme: 'dark',
    );
    repo.stored = workspace;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          initialWorkspaceProvider.overrideWithValue(workspace),
          clockProvider.overrideWith((ref) => Stream.value(DateTime.utc(2026, 10, 17, 7, 0))),
        ],
        child: const HedgeApp(bypassAuth: true),
      ),
    );
    await tester.pumpAndSettle();

    // Navigasi ke Halaman 02 Armada
    await tester.tap(find.text('Armada'));
    await tester.pumpAndSettle();

    // 1. Verifikasi tidak ada teks "Unit KLM 540" atau "Unit KWK-001"
    expect(find.text('Unit KLM 540'), findsNothing);
    expect(find.text('Unit KWK-001'), findsNothing);
    expect(find.text('Unit 1865'), findsNothing);

    // 2. Verifikasi operator dan nomor body terpisah
    expect(find.text('KLM'), findsOneWidget);
    expect(find.text('540'), findsOneWidget);
    expect(find.text('KWK'), findsOneWidget);
    expect(find.text('001'), findsOneWidget);
    expect(find.text('1865'), findsOneWidget);

    // 3. Verifikasi seleksi unit dengan auto-increment [1], [2], [3]
    // Klik unit u2 ('001') -> harus dapat [1]
    await tester.tap(find.byKey(const ValueKey('unit-card-u2')));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    // Klik unit u1 ('540') -> harus dapat [2]
    await tester.tap(find.byKey(const ValueKey('unit-card-u1')));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    // Tekan "Aktifkan"
    await tester.tap(find.text('Aktifkan'));
    await tester.pumpAndSettle();

    // Verifikasi unit u2 dan u1 berhasil diaktifkan dengan urutan seleksi [u2, u1] di depan rotasi
    final updatedRoute = repo.stored!.routes.first;
    expect(updatedRoute.units.firstWhere((u) => u.id == 'u2').active, isTrue);
    expect(updatedRoute.order.first, 'u2');
    expect(updatedRoute.order[1], 'u1');
  });

  testWidgets('Halaman 02 Armada UI Test: Tanpa subtitle Aktif untuk jadwal baru, bar supir tandem & swap', (tester) async {
    final repo = TestWorkspaceRepository();
    const d1 = Driver(
      id: 'd1',
      routeId: 'r_test',
      fullName: 'Bambang Hariyanto',
      callName: 'Bambang',
      status: DriverStatus.tetap,
    );
    const d2 = Driver(
      id: 'd2',
      routeId: 'r_test',
      fullName: 'Rudi Suherman',
      callName: 'Rudi',
      status: DriverStatus.tetap,
    );

    final units = [
      const FleetUnit(
        id: 'u1',
        number: '540',
        active: true,
        driverShift1Id: 'd1',
        driverShift2Id: 'd2',
      ),
      const FleetUnit(
        id: 'u2',
        number: '541',
        active: false,
      ),
    ];

    final route = HedgeRoute(
      id: 'r_test',
      name: 'JAK.01',
      color: 0xffff9800,
      units: units,
      order: ['u1', 'u2'],
      drivers: const [d1, d2],
    );

    final workspace = Workspace(
      routes: [route],
      activeRouteId: route.id,
      date: '2026-10-18',
      theme: 'dark',
    );
    repo.stored = workspace;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          initialWorkspaceProvider.overrideWithValue(workspace),
          clockProvider.overrideWith((ref) => Stream.value(DateTime.utc(2026, 10, 18, 7, 0))),
        ],
        child: const HedgeApp(bypassAuth: true),
      ),
    );
    await tester.pumpAndSettle();

    // Navigasi ke Halaman 02 Armada
    await tester.tap(find.text('Armada'));
    await tester.pumpAndSettle();

    // 1. Verifikasi teks "Aktif untuk jadwal baru" TIDAK DITEMUKAN sama sekali
    expect(find.text('Aktif untuk jadwal baru'), findsNothing);

    // 2. Verifikasi slot tandem supir muncul untuk unit u1 (Bambang & Rudi)
    expect(find.textContaining('Bambang'), findsOneWidget);
    expect(find.textContaining('Rudi'), findsOneWidget);

    // 3. Verifikasi tombol header "Kelola Pramudi" dan "Rolling Shift"
    expect(find.text('Kelola Pramudi'), findsOneWidget);
    expect(find.text('Rolling Shift'), findsOneWidget);

    // 4. Verifikasi tombol swap supir ⇄ bekerja
    final swapBtn = find.byKey(const ValueKey('swap-drivers-u1'));
    expect(swapBtn, findsOneWidget);
    await tester.tap(swapBtn);
    await tester.pumpAndSettle();

    // Verifikasi state supir di repo telah ditukar
    final updatedUnit = repo.stored!.routes.first.units.firstWhere((u) => u.id == 'u1');
    expect(updatedUnit.driverShift1Id, 'd2');
    expect(updatedUnit.driverShift2Id, 'd1');
  });
}

