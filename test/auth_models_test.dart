import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/auth_models.dart';

void main() {
  group('AuthorizedDispatcher Model', () {
    test('serializes and deserializes correctly', () {
      final json = {
        'id': 1,
        'uuid': 'd3b07384-d113-4e44-b26a-93108c4547b7',
        'email': 'budi.pdo@gmail.com',
        'name': 'Budi Santoso',
        'role': 'pdo',
        'status': 'active',
        'created_at': '2026-10-13T10:00:00Z',
        'updated_at': '2026-10-13T10:00:00Z',
      };

      final user = AuthorizedDispatcher.fromJson(json);

      expect(user.id, 1);
      expect(user.uuid, 'd3b07384-d113-4e44-b26a-93108c4547b7');
      expect(user.email, 'budi.pdo@gmail.com');
      expect(user.name, 'Budi Santoso');
      expect(user.role, UserRole.pdo);
      expect(user.status, AccountStatus.active);
      expect(user.isAuthorized, isTrue);

      final serialized = user.toJson();
      expect(serialized['email'], 'budi.pdo@gmail.com');
      expect(serialized['role'], 'pdo');
      expect(serialized['status'], 'active');
    });

    test('isAuthorized only returns true when status is active', () {
      const pending = AuthorizedDispatcher(
        id: 2,
        uuid: 'uuid-pending',
        email: 'andi@gmail.com',
        name: 'Andi',
        role: UserRole.pdo,
        status: AccountStatus.pending,
      );
      expect(pending.isAuthorized, isFalse);

      const blocked = AuthorizedDispatcher(
        id: 3,
        uuid: 'uuid-blocked',
        email: 'deni@gmail.com',
        name: 'Deni',
        role: UserRole.pdo,
        status: AccountStatus.blocked,
      );
      expect(blocked.isAuthorized, isFalse);
    });
  });
}
