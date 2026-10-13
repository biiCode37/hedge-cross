import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/data/auth_service.dart';

class MockSessionStorage implements SessionStorage {
  String? _stored;
  @override
  Future<String?> read() async => _stored;
  @override
  Future<void> write(String value) async => _stored = value;
  @override
  Future<void> clear() async => _stored = null;
}

void main() {
  group('AuthService State', () {
    test('initializes with unauthenticated state when storage is empty', () async {
      final storage = MockSessionStorage();
      final service = LocalSessionAuthService(storage);

      final initial = await service.restoreSession();
      expect(initial.isAuthenticated, isFalse);
      expect(initial.user, isNull);
    });

    test('restores session when valid JSON is in storage', () async {
      final storage = MockSessionStorage();
      await storage.write(
        '{"id":1,"uuid":"uuid-1","email":"pdo@mikrotrans.id","name":"Budi","role":"pdo","status":"active"}',
      );
      final service = LocalSessionAuthService(storage);

      final session = await service.restoreSession();
      expect(session.isAuthenticated, isTrue);
      expect(session.user?.email, 'pdo@mikrotrans.id');
      expect(session.user?.isAuthorized, isTrue);
    });

    test('clears session on logout', () async {
      final storage = MockSessionStorage();
      await storage.write('{"id":1,"uuid":"u","email":"e","name":"n","role":"pdo","status":"active"}');
      final service = LocalSessionAuthService(storage);

      await service.logout();
      expect(await storage.read(), isNull);
    });
  });
}
