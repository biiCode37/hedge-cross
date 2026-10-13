import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_models.dart';

abstract interface class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SharedPreferencesSessionStorage implements SessionStorage {
  static const _key = 'hedge_auth_user_session';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class AuthSessionState {
  const AuthSessionState({
    this.user,
    this.token,
    this.error,
    this.isLoading = false,
  });

  final AuthorizedDispatcher? user;
  final String? token;
  final String? error;
  final bool isLoading;

  bool get isAuthenticated => user != null && user!.isAuthorized;
  bool get isPendingApproval => user != null && user!.status == AccountStatus.pending;
  bool get isBlocked => user != null && user!.status == AccountStatus.blocked;

  AuthSessionState copyWith({
    AuthorizedDispatcher? user,
    String? token,
    String? error,
    bool? isLoading,
    bool clearError = false,
  }) => AuthSessionState(
    user: user ?? this.user,
    token: token ?? this.token,
    error: clearError ? null : (error ?? this.error),
    isLoading: isLoading ?? this.isLoading,
  );
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

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({
    required SessionStorage storage,
    SupabaseClient? client,
    GoogleSignIn? googleSignIn,
    String? serverClientId = '1066127378433-k4iqcmqeepbqdcg8agu2tnhqvq85vj3k.apps.googleusercontent.com',
  })  : _storage = storage,
        _client = client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: serverClientId,
            );

  final SessionStorage _storage;
  final SupabaseClient? _client;
  final GoogleSignIn _googleSignIn;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  @override
  Future<AuthSessionState> restoreSession() async {
    try {
      // 1. Coba baca sesi lokal terlebih dahulu (Offline-First)
      final raw = await _storage.read();
      AuthorizedDispatcher? localUser;
      if (raw != null && raw.isNotEmpty) {
        try {
          localUser = AuthorizedDispatcher.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          );
        } catch (_) {}
      }

      // 2. Jika ada sesi online Supabase, verifikasi kembali status whitelist
      final currentSession = _supabase.auth.currentSession;
      final email = currentSession?.user.email ?? localUser?.email;

      if (email != null && email.isNotEmpty) {
        try {
          final res = await _supabase
              .from('authorized_dispatchers')
              .select()
              .eq('email', email)
              .maybeSingle();

          if (res != null) {
            final freshUser = AuthorizedDispatcher.fromJson(res);
            if (freshUser.isAuthorized) {
              await _storage.write(jsonEncode(freshUser.toJson()));
            } else {
              await _storage.clear();
            }
            return AuthSessionState(
              user: freshUser,
              token: currentSession?.accessToken,
            );
          }
        } catch (e) {
          debugPrint('Gagal sync status whitelist online, memakai sesi lokal: $e');
        }
      }

      // 3. Fallback ke sesi lokal jika offline
      if (localUser != null) {
        return AuthSessionState(user: localUser);
      }

      return const AuthSessionState();
    } catch (e) {
      return AuthSessionState(error: e.toString());
    }
  }

  @override
  Future<AuthSessionState> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthSessionState(error: 'Masuk dengan Google dibatalkan.');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        return const AuthSessionState(error: 'Gagal mendapatkan token autentikasi Google.');
      }

      // Autentikasi ke Supabase menggunakan ID token Google
      AuthResponse? authRes;
      try {
        authRes = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken ?? '',
          accessToken: accessToken,
        );
      } catch (authError) {
        debugPrint('Catatan auth Supabase: $authError');
      }

      final email = googleUser.email.trim();
      final name = googleUser.displayName?.trim() ?? 'Petugas';

      // Periksa email di tabel authorized_dispatchers
      final record = await _supabase
          .from('authorized_dispatchers')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (record != null) {
        final dispatcher = AuthorizedDispatcher.fromJson(record);
        if (dispatcher.isAuthorized) {
          await _storage.write(jsonEncode(dispatcher.toJson()));
          return AuthSessionState(
            user: dispatcher,
            token: authRes?.session?.accessToken,
          );
        } else if (dispatcher.isBlocked) {
          return AuthSessionState(
            user: dispatcher,
            error: 'Akun Anda (${dispatcher.email}) dinonaktifkan oleh administrator.',
          );
        } else {
          return AuthSessionState(user: dispatcher);
        }
      }

      // Jika belum terdaftar, buat akun baru berstatus 'pending'
      try {
        final inserted = await _supabase
            .from('authorized_dispatchers')
            .insert({
              'email': email,
              'name': name,
              'role': 'pdo',
              'status': 'pending',
            })
            .select()
            .single();

        final pendingUser = AuthorizedDispatcher.fromJson(inserted);
        return AuthSessionState(user: pendingUser);
      } catch (_) {
        final fallbackPending = AuthorizedDispatcher(
          id: 0,
          uuid: '',
          email: email,
          name: name,
          role: UserRole.pdo,
          status: AccountStatus.pending,
        );
        return AuthSessionState(user: fallbackPending);
      }
    } catch (e) {
      return AuthSessionState(error: 'Gagal masuk dengan Google: $e');
    }
  }

  @override
  Future<AuthSessionState> requestAccess({
    required String email,
    required String name,
  }) async {
    try {
      final res = await _supabase
          .from('authorized_dispatchers')
          .upsert({
            'email': email.trim(),
            'name': name.trim(),
            'role': 'pdo',
            'status': 'pending',
          }, onConflict: 'email')
          .select()
          .single();

      final user = AuthorizedDispatcher.fromJson(res);
      return AuthSessionState(user: user);
    } catch (e) {
      return AuthSessionState(error: 'Gagal mengajukan permohonan akses: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _storage.clear();
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
