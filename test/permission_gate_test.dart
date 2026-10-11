import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/notification_service.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'package:hedge_flutter/ui/permission_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PermissionGate bypasses checks on non-Android platform', (
    tester,
  ) async {
    final service = NotificationService(android: false);
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: PermissionGate(
          notifications: service,
          child: const Text('MAIN_CONTENT_RENDERED'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('MAIN_CONTENT_RENDERED'), findsOneWidget);
  });

  testWidgets('PermissionGate bypasses checks when notifications service is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: const PermissionGate(
          notifications: null,
          child: Text('MAIN_CONTENT_RENDERED'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('MAIN_CONTENT_RENDERED'), findsOneWidget);
  });

  testWidgets(
    'PermissionGate blocks access when vital permissions are missing and allows opening settings',
    (tester) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NotificationService.channel, (call) async {
            calls.add('${call.method}:${call.arguments}');
            if (call.method == 'status') {
              return {
                'notifications': true,
                'exact': false,
                'fullScreen': false,
                'overlay': false,
                'speechStatus': 'Suara offline siap',
                'alarmVolume': 7,
                'alarmVolumeMax': 7,
                'audioIssue': '',
                'voice': 'id-ID-offline',
                'pending': 0,
              };
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(NotificationService.channel, null),
      );

      final service = NotificationService(android: true)..ready = true;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: hedgeTheme(Brightness.dark),
            home: PermissionGate(
              notifications: service,
              child: const Text('MAIN_CONTENT_RENDERED'),
            ),
          ),
        ),
      );

      // Verify checking state or settling into blocked state
      await tester.pumpAndSettle();

      // Child should NOT be rendered!
      expect(find.text('MAIN_CONTENT_RENDERED'), findsNothing);

      // Blocked UI elements
      expect(find.textContaining('AKSES DIBLOKIR'), findsOneWidget);
      expect(find.text('Perizinan Operasional Wajib'), findsOneWidget);
      expect(find.text('Izin Alarm Tepat (Exact Alarm)'), findsOneWidget);
      expect(find.text('Izin Alert Layar Penuh'), findsOneWidget);
      expect(find.text('Tampil di Atas Aplikasi Lain'), findsOneWidget);
      expect(find.text('PERIKSA ULANG SEMUA IZIN'), findsOneWidget);

      // Tap on fix button for exact alarm
      final fixButtons = find.text('Beri Izin Sekarang');
      expect(fixButtons, findsNWidgets(3)); // exact, fullScreen, overlay

      await tester.tap(fixButtons.first);
      await tester.pump();
      expect(calls, contains('openPermission:exact'));
    },
  );

  testWidgets('PermissionGate grants access when all 4 vital permissions are satisfied', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NotificationService.channel, (call) async {
          if (call.method == 'status') {
            return {
              'notifications': true,
              'exact': true,
              'fullScreen': true,
              'overlay': true,
              'speechStatus': 'Suara offline siap',
              'alarmVolume': 7,
              'alarmVolumeMax': 7,
              'audioIssue': '',
              'voice': 'id-ID-offline',
              'pending': 0,
            };
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NotificationService.channel, null),
    );

    final service = NotificationService(android: true)..ready = true;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: PermissionGate(
            notifications: service,
            child: const Text('MAIN_CONTENT_RENDERED'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MAIN_CONTENT_RENDERED'), findsOneWidget);
    expect(find.textContaining('AKSES DIBLOKIR'), findsNothing);
  });
}
