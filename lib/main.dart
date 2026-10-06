import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/workspace_controller.dart';
import 'application/notification_service.dart';
import 'data/workspace_repository.dart';
import 'ui/app.dart';
import 'domain/alarm_plan.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final repository = await LocalWorkspaceRepository.open();
    var workspace = await repository.load();
    if (workspace == null) {
      workspace = sampleWorkspace(DateTime.now());
      await repository.save(workspace);
    }
    final notifications = NotificationService();
    await notifications.initialize();
    final native = acceptedNativeAlarmActions(
      workspace,
      await notifications.readNativeActions(),
    );
    if (native.isNotEmpty) {
      workspace = applyNativeAlarmActions(workspace, native);
      await repository.save(workspace);
      await notifications.acceptNativeActions(native);
    }
    runApp(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repository),
          initialWorkspaceProvider.overrideWithValue(workspace),
        ],
        child: HedgeApp(notifications: notifications),
      ),
    );
    await notifications.reconcile(workspace);
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storage, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Data HEDGE belum bisa dibuka',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  Text('$error'),
                  const SizedBox(height: 16),
                  const Text(
                    'Database tidak direset. Tutup aplikasi dan periksa penyimpanan perangkat atau gunakan salinan backup untuk pemulihan.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
