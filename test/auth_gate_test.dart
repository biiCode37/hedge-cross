import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/auth_controller.dart';
import 'package:hedge_flutter/data/auth_service.dart';
import 'package:hedge_flutter/domain/auth_models.dart';
import 'package:hedge_flutter/ui/auth_gate.dart';

void main() {
  group('AuthGate Widget', () {
    testWidgets('renders LoginScreen when session is unauthenticated', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _TestAuthController(
              const AuthSessionState(isLoading: false),
            )),
          ],
          child: const MaterialApp(
            home: AuthGate(
              child: Text('HOME_CONTENT'),
            ),
          ),
        ),
      );

      expect(find.text('HEDGE'), findsOneWidget);
      expect(find.text('Masuk dengan Akun Google'), findsOneWidget);
      expect(find.text('HOME_CONTENT'), findsNothing);
    });

    testWidgets('renders PendingApprovalScreen when account status is pending', (tester) async {
      const pendingUser = AuthorizedDispatcher(
        id: 1,
        uuid: 'u-1',
        email: 'pending@mikrotrans.id',
        name: 'Andi Dispatcher',
        role: UserRole.pdo,
        status: AccountStatus.pending,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _TestAuthController(
              const AuthSessionState(user: pendingUser, isLoading: false),
            )),
          ],
          child: const MaterialApp(
            home: AuthGate(
              child: Text('HOME_CONTENT'),
            ),
          ),
        ),
      );

      expect(find.text('Akses Terbatas'), findsOneWidget);
      expect(find.text('pending@mikrotrans.id'), findsOneWidget);
      expect(find.text('HOME_CONTENT'), findsNothing);
    });

    testWidgets('renders child content when user is authorized', (tester) async {
      const activeUser = AuthorizedDispatcher(
        id: 1,
        uuid: 'u-1',
        email: 'active.pdo@mikrotrans.id',
        name: 'Budi Santoso',
        role: UserRole.pdo,
        status: AccountStatus.active,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _TestAuthController(
              const AuthSessionState(user: activeUser, isLoading: false),
            )),
          ],
          child: const MaterialApp(
            home: AuthGate(
              child: Text('HOME_CONTENT'),
            ),
          ),
        ),
      );

      expect(find.text('HOME_CONTENT'), findsOneWidget);
      expect(find.text('Masuk dengan Akun Google'), findsNothing);
    });
  });
}

class _TestAuthController extends AuthController {
  _TestAuthController(this._initial);
  final AuthSessionState _initial;

  @override
  AuthSessionState build() => _initial;
}
