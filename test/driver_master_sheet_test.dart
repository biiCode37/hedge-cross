import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/data/workspace_repository.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'package:hedge_flutter/ui/driver_master_sheet.dart';

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
  testWidgets('DriverMasterSheet renders driver list and allows filtering', (tester) async {
    final repo = TestWorkspaceRepository();
    const d1 = Driver(
      id: 'd1',
      routeId: 'r1',
      fullName: 'Bambang Hariyanto',
      callName: 'Bambang',
      status: DriverStatus.tetap,
      defaultUnitNumber: '540',
      defaultShift: 1,
    );
    const d2 = Driver(
      id: 'd2',
      routeId: 'r1',
      fullName: 'Agus Santoso',
      callName: 'Agus',
      status: DriverStatus.cadangan,
    );

    final route = HedgeRoute(
      id: 'r1',
      name: 'JAK.115',
      color: 0xFF00E5FF,
      units: const [],
      order: const [],
      drivers: const [d1, d2],
    );

    final workspace = Workspace(
      routes: [route],
      activeRouteId: 'r1',
      date: '2026-10-18',
    );
    repo.stored = workspace;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          initialWorkspaceProvider.overrideWithValue(workspace),
        ],
        child: MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: Scaffold(
            body: DriverMasterSheet(route: route),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifikasi kedua supir tampil di awal (filter: 'Semua')
    expect(find.text('Bambang Hariyanto'), findsOneWidget);
    expect(find.text('Agus Santoso'), findsOneWidget);
    expect(find.text('TETAP'), findsOneWidget);
    expect(find.text('CADANGAN'), findsOneWidget);

    // 2. Filter 'Tetap'
    await tester.tap(find.text('Tetap'));
    await tester.pumpAndSettle();

    expect(find.text('Bambang Hariyanto'), findsOneWidget);
    expect(find.text('Agus Santoso'), findsNothing);

    // 3. Filter 'Cadangan'
    await tester.tap(find.text('Cadangan'));
    await tester.pumpAndSettle();

    expect(find.text('Bambang Hariyanto'), findsNothing);
    expect(find.text('Agus Santoso'), findsOneWidget);

    // 4. Kembali ke 'Semua' dan coba pencarian
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'bambang');
    await tester.pumpAndSettle();

    expect(find.text('Bambang Hariyanto'), findsOneWidget);
    expect(find.text('Agus Santoso'), findsNothing);
  });
}
