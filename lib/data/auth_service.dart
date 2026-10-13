import 'dart:convert';
import '../domain/auth_models.dart';

abstract interface class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class AuthSessionState {
  const AuthSessionState({this.user, this.token, this.error});
  final AuthorizedDispatcher? user;
  final String? token;
  final String? error;

  bool get isAuthenticated => user != null && user!.isAuthorized;
  bool get isPendingApproval => user != null && user!.status == AccountStatus.pending;
  bool get isBlocked => user != null && user!.status == AccountStatus.blocked;
}

abstract interface class AuthService {
  Future<AuthSessionState> restoreSession();
  Future<AuthSessionState> signInWithGoogle();
  Future<AuthSessionState> requestAccess({required String email, required String name});
  Future<void> logout();
}

class LocalSessionAuthService implements AuthService {
  LocalSessionAuthService(this._storage);
  final SessionStorage _storage;

  @override
  Future<AuthSessionState> restoreSession() async {
    try {
      final raw = await _storage.read();
      if (raw == null || raw.isEmpty) return const AuthSessionState();
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final user = AuthorizedDispatcher.fromJson(map);
      return AuthSessionState(user: user);
    } catch (e) {
      return AuthSessionState(error: e.toString());
    }
  }

  @override
  Future<AuthSessionState> signInWithGoogle() async {
    throw UnimplementedError('Gunakan implementasi SupabaseAuthService untuk live Google Sign-In.');
  }

  @override
  Future<AuthSessionState> requestAccess({required String email, required String name}) async {
    throw UnimplementedError('Gunakan implementasi SupabaseAuthService untuk request access.');
  }

  @override
  Future<void> logout() async {
    await _storage.clear();
  }
}
