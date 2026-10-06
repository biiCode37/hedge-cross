import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/notification_service.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/ui/alarm_permissions.dart';
import 'package:hedge_flutter/ui/design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final workspace = sampleWorkspace(DateTime.utc(2026, 10, 6));
  for (final brightness in Brightness.values) {
    testWidgets(
      'Overlay permission and TTS controls work at large text: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final calls = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(NotificationService.channel, (
              call,
            ) async {
              calls.add('${call.method}:${call.arguments}');
              if (call.method == 'status') {
                return {
                  'notifications': true,
                  'exact': true,
                  'fullScreen': true,
                  'overlay': false,
                  'speechStatus': 'Suara offline siap',
                  'alarmVolume': 7,
                  'alarmVolumeMax': 7,
                  'audioIssue': '',
                  'voice': 'id-ID-offline',
                  'pending': 12,
                };
              }
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(NotificationService.channel, null),
        );
        final service = NotificationService(android: true)..ready = true;
        await service.refreshStatus();
        expect(service.device.value.overlay, false);
        expect(service.device.value.alarmVolume, 7);
        expect(
          service.status.value,
          contains('izin tampil di atas aplikasi lain'),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: hedgeTheme(brightness),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AlarmPermissionPanel(
                    service: service,
                    workspace: () => workspace,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final overlay = find.text('Izinkan tampil di atas aplikasi lain');
        await tester.ensureVisible(overlay);
        await tester.tap(overlay);
        await tester.pump();
        expect(calls, contains('openPermission:overlay'));
        final testVoice = find.text('Uji suara TTS');
        await tester.ensureVisible(testVoice);
        await tester.tap(testVoice);
        await tester.pump();
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 750));
        }
        expect(calls, contains('testSpeech:null'));
        final stop = find.text('Hentikan uji suara');
        await tester.ensureVisible(stop);
        await tester.tap(stop);
        await tester.pump();
        expect(calls, contains('stopSpeechTest:null'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
