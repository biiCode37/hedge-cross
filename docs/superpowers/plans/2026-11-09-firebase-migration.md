# Migrasi Cloud Backend HEDGE ke Google Firebase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menggantikan backend cloud Supabase dengan Google Firebase (Cloud Firestore & Firebase Auth) pada aplikasi HEDGE Flutter secara menyeluruh dengan arsitektur Offline-First yang andal, 100% gratis tanpa kartu kredit, dan anti-sleep 24/7.

**Architecture:** Mempertahankan arsitektur *Dependency Inversion* dengan mengimplementasikan `FirebaseAuthService` (menggantikan `SupabaseAuthService`) dan `FirestoreCloudSyncClient` (menggantikan `SupabaseCloudSyncClient`), menjaga SQLite lokal (`hedge_v2.sqlite`) sebagai Single Source of Truth, dan menyinkronkan data secara atomic ke koleksi Firestore (`authorized_dispatchers`, `routes`, `outbox`).

**Tech Stack:** Flutter 3.10+, Dart 3, `firebase_core`, `cloud_firestore`, `firebase_auth`, `google_sign_in`, `drift` (SQLite), `flutter_riverpod`.

## Global Constraints

- Wajib bekerja secara eksklusif pada branch `devmode`.
- DILARANG melakukan build APK kecuali jika diperintahkan secara eksplisit oleh USER.
- Selalu gunakan `pnpm` untuk tooling dan package management jika relevan.
- Kode dan penanganan error harus informatif untuk developer dan ramah bagi dispatcher di lapangan.
- Pertahankan dukungan tema kontras tinggi untuk Dark Mode dan Light Mode.
- Target `flutter analyze` adalah 0 error dan 0 warning.

---

### Task 1: Konfigurasi Android Native & Penambahan Dependency Firebase

**Files:**
- Create: `android/app/google-services.json`
- Modify: `android/build.gradle.kts`
- Modify: `android/app/build.gradle.kts`
- Modify: `pubspec.yaml:7-28`

**Interfaces:**
- Produces: Lingkungan build Android dengan plugin Google Services dan library Flutter Firebase (`firebase_core`, `cloud_firestore`, `firebase_auth`) terpasang.

- [ ] **Step 1: Buat berkas `android/app/google-services.json`**
Isi berkas konfigurasi resmi dari project `hedge-mikrotrans`:
```json
{
  "project_info": {
    "project_number": "817255308741",
    "project_id": "hedge-mikrotrans",
    "storage_bucket": "hedge-mikrotrans.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:817255308741:android:25fe405b93217ad056bfac",
        "android_client_info": {
          "package_name": "id.mikrotrans.hedge.hedge_flutter"
        }
      },
      "oauth_client": [],
      "api_key": [
        {
          "current_key": "AIzaSyBobCwA6QK-3g015kwJz73EGbdJLt6NwJs"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

- [ ] **Step 2: Tambahkan plugin `com.google.gms.google-services` ke Gradle**
Di `android/build.gradle.kts`, pastikan plugin google-services tersedia atau tambahkan di `plugins` block:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```
Dan di `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

- [ ] **Step 3: Tambahkan dependensi Firebase ke `pubspec.yaml`**
Tambahkan:
```yaml
  firebase_core: ^3.12.1
  cloud_firestore: ^5.6.5
  firebase_auth: ^5.5.1
```
Jalankan `flutter pub get` untuk mengunduh package.

- [ ] **Step 4: Commit perubahan Task 1**
```bash
git add android/ pubspec.yaml pubspec.lock
git commit -m "chore: setup firebase android configuration and dependencies"
```

---

### Task 2: Implementasi `FirebaseAuthService`

**Files:**
- Modify: `lib/data/auth_service.dart`
- Test: `test/auth_service_test.dart`

**Interfaces:**
- Consumes: `SessionStorage`, `GoogleSignIn`, `FirebaseAuth`, `FirebaseFirestore`.
- Produces: `FirebaseAuthService` yang mengimplementasikan antarmuka `AuthService` (`restoreSession()`, `signInWithGoogle()`, `requestAccess()`, `logout()`).

- [ ] **Step 1: Tulis unit test untuk verifikasi mapping status `AuthorizedDispatcher`**
Buat test di `test/auth_service_test.dart` yang memverifikasi bahwa parser dokumen Firestore membaca status `active`, `pending`, dan `blocked` secara tepat ke `AuthSessionState`.

- [ ] **Step 2: Jalankan test untuk memastikan test gagal atau memverifikasi struktur awal**
```bash
flutter test test/auth_service_test.dart
```

- [ ] **Step 3: Implementasikan kelas `FirebaseAuthService` di `lib/data/auth_service.dart`**
Implementasikan:
1. `restoreSession()`: Membaca `SessionStorage` lokal (offline-first). Jika online, verifikasi status dokumen di `authorized_dispatchers/{email}`.
2. `signInWithGoogle()`: Menjalankan `_googleSignIn.signIn()`, membuat `GoogleAuthProvider.credential()`, login via `FirebaseAuth.instance.signInWithCredential()`, lalu membaca dokumen `authorized_dispatchers/{email}`.
3. `requestAccess()`: Menulis dokumen pendaftaran baru ke Firestore `authorized_dispatchers` dengan status `pending`.
4. `logout()`: Memanggil `_auth.signOut()`, `_googleSignIn.signOut()`, dan menghapus `_storage.clear()`.

- [ ] **Step 4: Jalankan unit test kembali**
```bash
flutter test test/auth_service_test.dart
```

- [ ] **Step 5: Commit perubahan Task 2**
```bash
git add lib/data/auth_service.dart test/auth_service_test.dart
git commit -m "feat: implement FirebaseAuthService with offline-first whitelist check"
```

---

### Task 3: Implementasi `FirestoreCloudSyncClient`

**Files:**
- Modify: `lib/data/sync_service.dart`
- Test: `test/sync_service_test.dart`

**Interfaces:**
- Consumes: `FirebaseFirestore`, domain model `HedgeRoute`, `FleetUnit`, `Driver`.
- Produces: `FirestoreCloudSyncClient` yang mengimplementasikan antarmuka `CloudSyncClient` (`pullRoutes()`, `pushDrivers()`, `deleteDriverCloud()`, `pushOutbox()`).

- [ ] **Step 1: Tulis unit test untuk `FirestoreCloudSyncClient` data mapping**
Buat test di `test/sync_service_test.dart` yang menguji serialisasi payload rute, supir, dan outbox agar kompatibel dengan format Firestore.

- [ ] **Step 2: Implementasikan `FirestoreCloudSyncClient` di `lib/data/sync_service.dart`**
Implementasikan method:
1. `pullRoutes(DateTime? since)`: Membaca koleksi Firestore `routes` (filter `updated_at > since` jika ada).
2. `pushDrivers(String routeIdentifier, List<Driver> drivers)`: Mengupdate array/subkoleksi `drivers` di dokumen `routes/{routeIdentifier}` dengan timestamp server.
3. `deleteDriverCloud(String routeIdentifier, String driverCallNameOrId)`: Menghapus supir dari dokumen rute di Firestore.
4. `pushOutbox(List<Map<String, dynamic>> items)`: Batch write ke koleksi `outbox`.

- [ ] **Step 3: Jalankan unit test sync**
```bash
flutter test test/sync_service_test.dart
```

- [ ] **Step 4: Commit perubahan Task 3**
```bash
git add lib/data/sync_service.dart test/sync_service_test.dart
git commit -m "feat: implement FirestoreCloudSyncClient for route and driver sync"
```

---

### Task 4: Inisialisasi Firebase & Penyambungan Dependency Injection di `lib/main.dart`

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/application/sync_controller.dart`
- Modify: `lib/application/auth_controller.dart`

**Interfaces:**
- Consumes: `FirebaseAuthService`, `FirestoreCloudSyncClient`, `Firebase.initializeApp()`.
- Produces: Aplikasi berjalan penuh dengan backend cloud Firebase dan fallback offline aktif.

- [ ] **Step 1: Ganti inisialisasi Supabase dengan `Firebase.initializeApp()` di `lib/main.dart`**
Inisialisasi Firebase secara aman:
```dart
try {
  await Firebase.initializeApp();
} catch (e) {
  debugPrint('Catatan inisialisasi Firebase (offline fallback aktif): $e');
}
```

- [ ] **Step 2: Update provider di Riverpod**
Inject `FirebaseAuthService` ke provider auth dan `FirestoreCloudSyncClient` ke provider sync:
```dart
final authServiceProvider = Provider<AuthService>((ref) {
  return FirebaseAuthService(
    storage: SharedPreferencesSessionStorage(),
  );
});

final cloudSyncClientProvider = Provider<CloudSyncClient>((ref) {
  return FirestoreCloudSyncClient();
});
```

- [ ] **Step 3: Jalankan analisa statis**
```bash
flutter analyze
```
Pastikan menghasilkan 0 errors dan 0 warnings.

- [ ] **Step 4: Commit perubahan Task 4**
```bash
git add lib/main.dart lib/application/
git commit -m "feat: wire Firebase services into main entrypoint and Riverpod providers"
```

---

### Task 5: Deploy Aturan Keamanan Firestore & Verifikasi Menyeluruh

**Files:**
- Create: `firestore.rules`
- Test: Seluruh unit test suite

**Interfaces:**
- Produces: Aturan keamanan Firestore ter-deploy ke cloud `hedge-mikrotrans` dan quality gates terpenuhi.

- [ ] **Step 1: Buat berkas `firestore.rules`**
```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /authorized_dispatchers/{email} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /outbox/{docId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
    }
  }
}
```

- [ ] **Step 2: Deploy rules ke Firebase via MCP / Firebase CLI**
```bash
firebase deploy --only firestore:rules
```

- [ ] **Step 3: Jalankan seluruh test suite dan lint**
```bash
flutter test
flutter analyze
```

- [ ] **Step 4: Commit perubahan Task 5**
```bash
git add firestore.rules
git commit -m "chore: add and deploy firestore security rules"
```
