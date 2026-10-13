import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return SupabaseAuthService(
    storage: SharedPreferencesSessionStorage(),
  );
});

final authControllerProvider = NotifierProvider<AuthController, AuthSessionState>(() {
  return AuthController();
});

class AuthController extends Notifier<AuthSessionState> {
  @override
  AuthSessionState build() {
    return const AuthSessionState(isLoading: true);
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true);
    final service = ref.read(authServiceProvider);
    final session = await service.restoreSession();
    state = session.copyWith(isLoading: false);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final service = ref.read(authServiceProvider);
    final session = await service.signInWithGoogle();
    state = session.copyWith(isLoading: false);
  }

  Future<void> requestAccess({required String email, required String name}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final service = ref.read(authServiceProvider);
    final session = await service.requestAccess(email: email, name: name);
    state = session.copyWith(isLoading: false);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final service = ref.read(authServiceProvider);
    await service.logout();
    state = const AuthSessionState(isLoading: false);
  }
}
