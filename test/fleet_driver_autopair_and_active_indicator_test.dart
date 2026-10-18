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
  testWidgets('Tombol Pasangkan Bawaan otomatis memasangkan driver tetap ke unit bawaan', (tester) async {
    final repo = TestWorkspaceRepository();
    final units = [
      const FleetUnit(id: 'u1', number: 'KWK 222153', active: true),
      const FleetUnit(id: 'u2', number: 'KWK 222154', active: true),
    ];
    final drivers = [
      const Driver(
        id: 'd1',
        routeId: 'r_test',
        fullName: 'Tachmidi',
        callName: 'Tahmidi',
        status: DriverStatus.tetap,
        defaultUnitNumber: 'KWK 222153',
        defaultShift: 1,
      ),
      const Driver(
        id: 'd2',
        routeId: 'r_test',
        fullName: 'Zaenuri',
        callName: 'Zaenuri',
        status: DriverStatus.tetap,
        defaultUnitNumber: 'KWK 222153',
        defaultShift: 2,
      ),
    ];

    final route = HedgeRoute(
      id: 'r_test',
      name: 'JAK.115',
      color: 0xffff9800,
      units: units,
      order: ['u1', 'u2'],
      drivers: drivers,
    );
    final workspace = Workspace(
      routes: [route],
      activeRouteId: route.id,
      date: '2026-10-18',
      theme: 'dark',
    );
    repo.stored = workspace;

    // Saat jam 09:00 (Pagi / Shift 1)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          initialWorkspaceProvider.overrideWithValue(workspace),
          clockProvider.overrideWith((ref) => Stream.value(DateTime.utc(2026, 10, 18, 9, 0))),
        ],
        child: const HedgeApp(bypassAuth: true),
      ),
    );
    await tester.pumpAndSettle();

    // Navigasi ke Halaman 02 Armada
    await tester.tap(find.text('Armada'));
    await tester.pumpAndSettle();

    // Pastikan tombol Pasangkan Bawaan ada
    final autoPairBtn = find.byKey(const ValueKey('auto-pair-drivers-btn'));
    expect(autoPairBtn, findsOneWidget);

    // Tekan tombol Pasangkan Bawaan
    await tester.ensureVisible(autoPairBtn);
    await tester.pumpAndSettle();
    await tester.tap(autoPairBtn);
    await tester.pumpAndSettle();

    // Verifikasi supir Tahmidi dan Zaenuri langsung muncul terpasang pada unit KWK 222153
    expect(find.text('Tahmidi'), findsOneWidget);
    expect(find.text('Zaenuri'), findsOneWidget);

    // Verifikasi ada indikator aktif
    expect(find.text('●'), findsWidgets);
  });

  testWidgets('Indikator shift aktif berganti antara Pagi dan Siang sesuai jam', (tester) async {
    final repo = TestWorkspaceRepository();
    final units = [
      const FleetUnit(
        id: 'u1',
        number: '222153',
        active: true,
        driverShift1Id: 'd1',
        driverShift2Id: 'd2',
      ),
    ];
    final drivers = [
      const Driver(
        id: 'd1',
        routeId: 'r_test',
        fullName: 'Tahmidi',
        callName: 'Tahmidi',
        status: DriverStatus.tetap,
      ),
      const Driver(
        id: 'd2',
        routeId: 'r_test',
        fullName: 'Zaenuri',
        callName: 'Zaenuri',
        status: DriverStatus.tetap,
      ),
    ];

    final route = HedgeRoute(
      id: 'r_test',
      name: 'JAK.115',
      color: 0xffff9800,
      units: units,
      order: ['u1'],
      drivers: drivers,
      config: const PlanConfig(shiftChangeTime: '13:00'),
    );
    final workspace = Workspace(
      routes: [route],
      activeRouteId: route.id,
      date: '2026-10-18',
      theme: 'dark',
    );
    repo.stored = workspace;

    // Tes 1: Jam 14:00 (Siang / Shift 2)
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          initialWorkspaceProvider.overrideWithValue(workspace),
          clockProvider.overrideWith((ref) => Stream.value(DateTime(2026, 10, 18, 14, 0))),
        ],
        child: const HedgeApp(bypassAuth: true),
      ),
    );
    await tester.pumpAndSettle();

    // Navigasi ke Halaman 02 Armada
    await tester.tap(find.text('Armada'));
    await tester.pumpAndSettle();

    expect(find.text('Tahmidi'), findsOneWidget);
    expect(find.text('Zaenuri'), findsOneWidget);
    expect(find.text('●'), findsOneWidget);
  });
}
