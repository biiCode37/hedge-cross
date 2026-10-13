import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/sync_controller.dart';
import 'package:hedge_flutter/data/sync_service.dart';

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
}
