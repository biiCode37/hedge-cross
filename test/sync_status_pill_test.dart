import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/sync_controller.dart';
import 'package:hedge_flutter/ui/sync_status_pill.dart';

void main() {
  testWidgets('SyncStatusPill renders green when synced and amber when offline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusPill(
            state: SyncState(status: SyncStatus.synced),
          ),
        ),
      ),
    );
    expect(find.text('Sinkron'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusPill(
            state: SyncState(status: SyncStatus.offline, pendingOutboxCount: 2),
          ),
        ),
      ),
    );
    expect(find.text('Offline (2)'), findsOneWidget);
  });
}
