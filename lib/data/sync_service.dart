abstract interface class CloudSyncClient {
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since);
  Future<void> pushOutbox(List<Map<String, dynamic>> items);
}
