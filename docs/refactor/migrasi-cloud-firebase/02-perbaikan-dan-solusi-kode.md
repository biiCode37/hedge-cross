# 02. Perbaikan & Solusi Kode: Migrasi ke Google Firebase (Cloud Firestore & Firebase Auth)

**Tanggal:** 2026-11-09  
**Branch:** `devmode`  
**Topik:** Arsitektur Solusi, Pemetaan Data NoSQL, dan Modifikasi Kode  

---

## 1. Arsitektur Solusi

Dipilih **Google Firebase (Spark Plan)** sebagai backend cloud definitif:
1. **Anti-Sleep 24/7/365:** Berjalan di Google Cloud Platform tanpa kebijakan suspend/pause otomatis.
2. **Hard-Capped Free Tier:** Bebas biaya permanen tanpa perlu menyematkan kartu kredit.
3. **Region Datacenter Jakarta (`asia-southeast2`):** Latensi pembacaan data super cepat (~100 ms).
4. **Offline-First Persistence:** SQLite lokal (`hedge_v2.sqlite`) tetap menjadi *Single Source of Truth* utama.

---

## 2. Restorasi & Seeding Data dari Backup PostgreSQL

Dibuat skrip ekstraksi otomatis [`scripts/extract_seed.py`](file:///d:/MINE/HEDGE-FLUTTER/scripts/extract_seed.py) dan pengunggah [`scripts/upload_seed_to_firestore.py`](file:///d:/MINE/HEDGE-FLUTTER/scripts/upload_seed_to_firestore.py) yang membedah file `db_cluster-06-11-2026@05-52-29.backup.gz`:
* **7 Akun Dispatcher Whitelist:** Diunggah ke koleksi `authorized_dispatchers/{email}`.
* **18 Rute Resmi Mikrotrans:** Diunggah ke koleksi `routes/{uuid}`.
* **586 Armada Unit:** Dipetakan langsung sebagai array terurut pada masing-masing dokumen rute.
* **6 Data Pramudi Riil:** Dipetakan ke rute JAK.115 dengan penugasan shift dan armada default.

---

## 3. Rincian Modifikasi Kode

### 3.1. Layanan Autentikasi (`FirebaseAuthService`)
Berkas: [`lib/data/auth_service.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/data/auth_service.dart)
* Mengimplementasikan interface `AuthService`.
* Menggunakan lazy-getter `_auth` dan `_firestore` yang dibungkus try/catch agar runtime widget test dan kondisi offline tidak mengalami crash `[core/no-app]`.
* Alur login:
  ```dart
  final googleUser = await _googleSignIn.signIn();
  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    idToken: googleAuth.idToken,
    accessToken: googleAuth.accessToken,
  );
  await _auth.signInWithCredential(credential);
  ```
* Pengecekan whitelist $O(1)$ di `authorized_dispatchers/{email}` dengan fallback aman ke `SharedPreferencesSessionStorage`.

### 3.2. Klien Sinkronisasi Cloud (`FirestoreCloudSyncClient`)
Berkas: [`lib/data/sync_service.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/data/sync_service.dart)
* Mengimplementasikan interface `CloudSyncClient`.
* `pullRoutes(DateTime? since)`: Menarik dokumen rute dengan filter timestamp delta.
* `pushDrivers(String routeIdentifier, List<Driver> drivers)`: Mengunggah pembaruan pramudi ke dokumen rute Firestore.
* `pushOutbox(List<Map<String, dynamic>> items)`: Batch write event operasional ke koleksi `outbox`.
* Penyempurnaan `mergeCloudRoutesIntoLocal`: Mendukung kunci `drivers`/`master_drivers` dan `units`/`master_units` secara polimorfik.

### 3.3. Injeksi Dependensi Riverpod & Entrypoint
* [`lib/application/auth_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/auth_controller.dart): Menyuntikkan `FirebaseAuthService` ke `authServiceProvider`.
* [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart): Mengganti instansiasi langsung menjadi `ref.read(cloudSyncClientProvider)` yang mengarah ke `FirestoreCloudSyncClient`.
* [`lib/main.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/main.dart): Mengganti inisialisasi Supabase dengan `await Firebase.initializeApp()` dengan blok try/catch offline-safe.

### 3.4. Aturan Keamanan Produksi (`firestore.rules`)
Berkas: [`firestore.rules`](file:///d:/MINE/HEDGE-FLUTTER/firestore.rules)
```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /authorized_dispatchers/{email} {
      allow read, write: if request.auth != null;
    }
    match /routes/{routeId} {
      allow read, write: if request.auth != null;
    }
    match /outbox/{docId} {
      allow create, read, update, delete: if request.auth != null;
    }
  }
}
```
Aturan berhasil di-deploy ke cloud via `firebase deploy --only firestore:rules`.
