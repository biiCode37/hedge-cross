# Hybrid Cloud Sync & Dispatcher Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghadirkan sinkronisasi master data rute dan unit armada secara Hybrid Offline-First ke Supabase Cloud serta autentikasi 1-Tap Google Sign-In dengan pembatasan akses ketat (*Whitelist Guard*) untuk Petugas Driving Order (PDO) Mikrotrans Utara.

**Architecture:** Menggunakan SQLite Drift lokal sebagai *Single Source of Truth* operasional lapangan tanpa jeda jaringan, didukung *Sync Engine* dua arah (tarik dari `master_routes`/`master_units` dan kirim via `outbox`), serta gerbang autentikasi mutlak (*Strict Auth Gate*) via Google OAuth yang mencocokkan email ke tabel `authorized_dispatchers`.

**Tech Stack:** Flutter 3, Dart >=3.10.4, Flutter Riverpod 3.3.1, Drift 2.33.0, Supabase Flutter, Google Sign-In, Flutter Secure Storage.

## Global Constraints

- Wajib bekerja secara eksklusif pada branch `devmode`.
- Dilarang menjalankan build APK (`flutter build apk`) tanpa instruksi eksplisit dari pengguna.
- Semua string antarmuka menggunakan Bahasa Indonesia yang ramah lapangan.
- Komponen visual wajib mendukung Dual Theme (Dark Mode Obsidian `#070B12` dan Light Mode) serta berstandar *Thumb-First* (touch target minimal 44–52px).

---

### Task 1: Auth Domain Models & Secure Persistence

**Files:**
- Create: `lib/domain/auth_models.dart`
- Create: `test/auth_models_test.dart`

**Interfaces:**
- Produces: `AuthorizedDispatcher`, `UserRole`, `AccountStatus` enum dan metode parsing JSON.

- [ ] **Step 1: Write the failing test**

```dart
// test/auth_models_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/auth_models_test.dart`  
Expected: FAIL with "Target of URI hasn't been generated: 'package:hedge_flutter/domain/auth_models.dart'"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/domain/auth_models.dart
enum UserRole {
  superadmin,
  admin,
  pdo;

  static UserRole fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'admin':
        return UserRole.admin;
      case 'pdo':
      default:
        return UserRole.pdo;
    }
  }

  String toDbValue() => name;
}

enum AccountStatus {
  active,
  pending,
  blocked;

  static AccountStatus fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'active':
        return AccountStatus.active;
      case 'blocked':
        return AccountStatus.blocked;
      case 'pending':
      default:
        return AccountStatus.pending;
    }
  }

  String toDbValue() => name;
}

class AuthorizedDispatcher {
  const AuthorizedDispatcher({
    required this.id,
    required this.uuid,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String uuid;
  final String email;
  final String name;
  final UserRole role;
  final AccountStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAuthorized => status == AccountStatus.active;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superadmin;

  factory AuthorizedDispatcher.fromJson(Map<String, dynamic> json) {
    return AuthorizedDispatcher(
      id: (json['id'] as num).toInt(),
      uuid: json['uuid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'pdo'),
      status: AccountStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'email': email,
    'name': name,
    'role': role.toDbValue(),
    'status': status.toDbValue(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/auth_models_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/auth_models.dart test/auth_models_test.dart
git commit -m "feat(auth): add AuthorizedDispatcher domain models and tests"
```

---

### Task 2: Auth Service & Local Session Repository

**Files:**
- Create: `lib/data/auth_service.dart`
- Create: `test/auth_service_test.dart`

**Interfaces:**
- Consumes: `AuthorizedDispatcher`, `UserRole`, `AccountStatus`
- Produces: `AuthService` interface, `AuthSessionState`

- [ ] **Step 1: Write the failing test**

```dart
// test/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/data/auth_service.dart';
import 'package:hedge_flutter/domain/auth_models.dart';

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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/auth_service_test.dart`  
Expected: FAIL with "Target of URI hasn't been generated: 'package:hedge_flutter/data/auth_service.dart'"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/auth_service.dart
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
    // Implementasi konkret Supabase OAuth dicolok di SupabaseAuthService
    throw UnimplementedError();
  }

  @override
  Future<AuthSessionState> requestAccess({required String email, required String name}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {
    await _storage.clear();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/auth_service_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/auth_service.dart test/auth_service_test.dart
git commit -m "feat(auth): add AuthService interface, session state and tests"
```

---

### Task 3: Baseline Seed Catalog & SQLite Schema Sync Columns

**Files:**
- Create: `assets/data/routes_catalog.json`
- Modify: `pubspec.yaml:31-33`
- Modify: `lib/data/workspace_repository.dart:34-45`
- Create: `test/catalog_seed_test.dart`

**Interfaces:**
- Produces: `routes_catalog.json` asset bundle dan kolom sinkronisasi di `HedgeDatabase` (`server_uuid`, `synced_at`).

- [ ] **Step 1: Write the failing test**

```dart
// test/catalog_seed_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes_catalog.json has valid structure and includes default Mikrotrans routes', () {
    final file = File('assets/data/routes_catalog.json');
    expect(file.existsSync(), isTrue, reason: 'Katalog rute wajib ada di assets/data/');

    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;

    expect(json['version'], isNotNull);
    expect(json['routes'], isA<List>());
    final routes = json['routes'] as List;
    expect(routes.isNotEmpty, isTrue);

    final first = routes.first as Map<String, dynamic>;
    expect(first['code'], isNotNull);
    expect(first['name'], isNotNull);
    expect(first['units'], isA<List>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/catalog_seed_test.dart`  
Expected: FAIL with "Katalog rute wajib ada di assets/data/"

- [ ] **Step 3: Write minimal implementation**

Buat file `assets/data/routes_catalog.json`:
```json
{
  "version": 1,
  "operator": "Mikrotrans Jakarta Utara",
  "routes": [
    {
      "uuid": "r_jak115",
      "code": "JAK.115",
      "name": "Terminal Tanjung Priok - Pegangsaan Dua",
      "color": 4294940672,
      "config": {
        "start": "05:00",
        "end": "22:00",
        "headwayNormal": 10,
        "headwayPeak": 5
      },
      "units": [
        "1000", "1001", "5", "6", "7", "8", "10", "12", "13", "14",
        "15", "16", "17", "18", "19", "20", "21", "22", "756", "88"
      ]
    },
    {
      "uuid": "r_jak117",
      "code": "JAK.117",
      "name": "Terminal Tanjung Priok - Tanah Merdeka",
      "color": 4281925112,
      "config": {
        "start": "05:00",
        "end": "22:00",
        "headwayNormal": 10,
        "headwayPeak": 6
      },
      "units": [
        "201", "202", "203", "204", "205", "206", "207", "208"
      ]
    }
  ]
}
```

Daftarkan di `pubspec.yaml`:
```yaml
  assets:
    - assets/hedge-logo.jpg
    - assets/data/routes_catalog.json
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/catalog_seed_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add assets/data/routes_catalog.json pubspec.yaml test/catalog_seed_test.dart
git commit -m "feat(catalog): add routes_catalog.json and register asset in pubspec"
```

---

### Task 4: Sync Service & Outbox Sync Worker

**Files:**
- Create: `lib/data/sync_service.dart`
- Create: `lib/application/sync_controller.dart`
- Create: `test/sync_service_test.dart`

**Interfaces:**
- Consumes: `HedgeDatabase`, `AuthSessionState`
- Produces: `SyncStatus` (`synced`, `offline`, `syncing`), `SyncController`

- [ ] **Step 1: Write the failing test**

```dart
// test/sync_service_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sync_service_test.dart`  
Expected: FAIL with "Target of URI hasn't been generated"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/data/sync_service.dart
abstract interface class CloudSyncClient {
  Future<List<Map<String, dynamic>>> pullRoutes(DateTime? since);
  Future<void> pushOutbox(List<Map<String, dynamic>> items);
}

// lib/application/sync_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class SyncController extends StateNotifier<SyncState> {
  SyncController(this._client) : super(const SyncState());
  final CloudSyncClient _client;

  Future<void> syncNow() async {
    state = state.copyWith(status: SyncStatus.syncing);
    try {
      await _client.pullRoutes(state.lastSyncedAt);
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sync_service_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/sync_service.dart lib/application/sync_controller.dart test/sync_service_test.dart
git commit -m "feat(sync): implement CloudSyncClient and SyncController with tests"
```

---

### Task 5: Auth UI Components (`LoginScreen` & `PendingApprovalScreen`)

**Files:**
- Create: `lib/ui/login_screen.dart`
- Create: `lib/ui/pending_approval_screen.dart`
- Create: `test/login_screen_test.dart`

**Interfaces:**
- Consumes: `HedgeTokens`, `AuthService`, `AuthSessionState`
- Produces: `LoginScreen`, `PendingApprovalScreen`

- [ ] **Step 1: Write the failing test**

```dart
// test/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/ui/login_screen.dart';

void main() {
  testWidgets('LoginScreen displays HEDGE brand and Google Sign-In button', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onGoogleSignIn: () async {
            pressed = true;
          },
        ),
      ),
    );

    expect(find.text('HEDGE'), findsOneWidget);
    expect(find.text('Headway Generator'), findsOneWidget);
    expect(find.text('By Mikrotrans Utara'), findsOneWidget);
    expect(find.text('Masuk dengan Akun Google'), findsOneWidget);

    // Verify there is NO bypass button
    expect(find.textContaining('Mode Darurat Offline'), findsNothing);

    await tester.tap(find.text('Masuk dengan Akun Google'));
    await tester.pump();
    expect(pressed, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/login_screen_test.dart`  
Expected: FAIL with "Target of URI hasn't been generated"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/ui/login_screen.dart
import 'package:flutter/material.dart';
import 'design_system.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({
    super.key,
    required this.onGoogleSignIn,
    this.isLoading = false,
    this.errorMessage,
  });

  final Future<void> Function() onGoogleSignIn;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF9800), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.alt_route, color: Color(0xFFFF9800), size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'HEDGE',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Headway Generator',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'By Mikrotrans Utara',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onGoogleSignIn,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login, size: 22),
                  label: const Text(
                    'Masuk dengan Akun Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/login_screen_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/login_screen.dart test/login_screen_test.dart
git commit -m "feat(ui): add LoginScreen with strict thumb-first design and tests"
```

---

### Task 6: UI SyncStatusPill & AuthGate Integration

**Files:**
- Create: `lib/ui/sync_status_pill.dart`
- Create: `lib/ui/auth_gate.dart`
- Modify: `lib/ui/app.dart:55-65`
- Create: `test/sync_status_pill_test.dart`

**Interfaces:**
- Consumes: `SyncController`, `SyncState`, `AuthSessionState`
- Produces: `SyncStatusPill`, `AuthGate`

- [ ] **Step 1: Write the failing test**

```dart
// test/sync_status_pill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/sync_controller.dart';
import 'package:hedge_flutter/ui/sync_status_pill.dart';

void main() {
  testWidgets('SyncStatusPill renders green when synced and amber when offline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusPill(
            state: SyncState(status: SyncStatus.synced),
          ),
        ),
      ),
    );
    expect(find.text('Sinkron'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SyncStatusPill(
            state: SyncState(status: SyncStatus.offline, pendingOutboxCount: 2),
          ),
        ),
      ),
    );
    expect(find.text('Offline (2)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/sync_status_pill_test.dart`  
Expected: FAIL with "Target of URI hasn't been generated"

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/ui/sync_status_pill.dart
import 'package:flutter/material.dart';
import '../application/sync_controller.dart';

class SyncStatusPill extends StatelessWidget {
  const SyncStatusPill({
    super.key,
    required this.state,
    this.onTap,
  });

  final SyncState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (state.status) {
      case SyncStatus.synced:
        color = const Color(0xFF10B981);
        label = 'Sinkron';
        icon = Icons.cloud_done;
        break;
      case SyncStatus.syncing:
        color = const Color(0xFF00E5FF);
        label = 'Menyelaraskan...';
        icon = Icons.sync;
        break;
      case SyncStatus.offline:
        color = const Color(0xFFFF9800);
        label = state.pendingOutboxCount > 0 ? 'Offline (${state.pendingOutboxCount})' : 'Offline';
        icon = Icons.cloud_off;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/sync_status_pill_test.dart`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/ui/sync_status_pill.dart test/sync_status_pill_test.dart
git commit -m "feat(ui): add SyncStatusPill widget and tests"
```

---

### Task 7: Full Test Suite & Static Analysis Verification

**Files:**
- Modify: Seluruh file relevan bila ada lint feedback

- [ ] **Step 1: Run full automated test suite**

Run: `flutter test`  
Expected: All tests pass (0 failures).

- [ ] **Step 2: Run Dart code analyzer**

Run: `flutter analyze`  
Expected: "No issues found!"

- [ ] **Step 3: Commit final plan documentation & verification checkpoint**

```bash
git add docs/superpowers/plans/2026-10-13-hybrid-cloud-sync-and-auth.md
git commit -m "docs(plan): add complete implementation plan for hybrid cloud sync and auth"
```
