import '../data/sync_service.dart';

enum SyncStatus {
  synced,
  offline,
  syncing;
}

class SyncState {
  const SyncState({
    this.status = SyncStatus.offline,
    this.lastSyncedAt,
    this.pendingOutboxCount = 0,
    this.error,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final int pendingOutboxCount;
  final String? error;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    int? pendingOutboxCount,
    String? error,
  }) => SyncState(
    status: status ?? this.status,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
    error: error ?? this.error,
  );
}

class SyncController {
  SyncController(this._client, [SyncState initial = const SyncState()]) : state = initial;
  final CloudSyncClient _client;
  SyncState state;

  Future<void> syncNow({Future<void> Function(List<Map<String, dynamic>> rawRoutes)? onRoutesPulled}) async {
    state = state.copyWith(status: SyncStatus.syncing);
    try {
      final routes = await _client.pullRoutes(state.lastSyncedAt);
      if (onRoutesPulled != null && routes.isNotEmpty) {
        await onRoutesPulled(routes);
      }
      state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.offline,
        error: e.toString(),
      );
    }
  }
}
