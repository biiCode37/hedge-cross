# Design Spec: Migrasi Cloud Database HEDGE ke Google Firebase

**Tanggal:** 2026-11-09  
**Status:** Disetujui (Approved)  
**Topik:** Migrasi Backend Cloud dari Supabase ke Google Firebase (Cloud Firestore & Firebase Auth)  
**Target Branch:** `devmode`  

---

## 1. Latar Belakang & Tujuan

Aplikasi HEDGE (Headway Generator By Mikrotrans Utara) sebelumnya menggunakan Supabase (`hedge-cross`) sebagai database cloud untuk sinkronisasi master rute, armada, pramudi, serta otentikasi whitelist dispatcher.

Namun, terdapat kendala dan kebutuhan krusial:
1. **Supabase Auto-Pause:** Proyek gratis di Supabase otomatis tertidur (*pause*) setelah 7 hari tidak ada traffic, yang berisiko membuat dispatcher di lapangan gagal sinkronisasi jika rute libur atau tidak diakses beberapa hari.
2. **Kebutuhan 100% Gratis Permanen Tanpa Kartu Kredit:** Prioritas mutlak adalah backend yang tidak memerlukan kartu kredit, bebas dari risiko lonjakan tagihan (*zero surprise billing*), dan berjalan 24/7 tanpa pernah tertidur.
3. **Google Sign-In Native di Android:** Ekosistem Google Firebase menyediakan integrasi native Android Google Sign-In yang jauh lebih stabil dan mulus tanpa alur pertukaran token yang rumit.
4. **Pertahanan Arsitektur Offline-First:** Database lokal SQLite perangkat (`hedge_v2.sqlite`) tetap menjadi *Single Source of Truth* operasional, sehingga transisi ke cloud baru tidak mengganggu kinerja dispatcher di kondisi tanpa sinyal.

---

## 2. Arsitektur & Struktur Data Cloud (Cloud Firestore)

Data SQL relasional sebelumnya dipetakan ke dalam struktur dokumen NoSQL Cloud Firestore yang efisien dan hemat kuota baca/tulis (*reads/writes*):

### 2.1 Koleksi `authorized_dispatchers` (Whitelist Pengguna)
* **ID Dokumen:** `email` (misal: `operator.jak10@gmail.com`)
* **Skema Dokumen:**
  ```json
  {
    "email": "operator.jak10@gmail.com",
    "name": "Budi Santoso",
    "role": "dispatcher",
    "status": "active",
    "is_authorized": true,
    "created_at": "TIMESTAMP",
    "updated_at": "TIMESTAMP"
  }
  ```
* **Karakteristik:** Pencarian status whitelist instan $O(1)$ berdasarkan email saat login Google berhasil.

### 2.2 Koleksi `routes` (Master Rute, Armada, dan Supir)
* **ID Dokumen:** `route_code` atau UUID rute (misal: `JAK-10`, `JAK-12`).
* **Skema Dokumen:**
  ```json
  {
    "route_code": "JAK-10",
    "route_name": "Tanah Abang — Kota",
    "color": 4294940672,
    "position": 1,
    "updated_at": "TIMESTAMP",
    "units": [
      {
        "id": "u-01",
        "number": "001",
        "active": true,
        "position": 1,
        "driver_shift1_id": "drv-01",
        "driver_shift2_id": "drv-02"
      }
    ],
    "drivers": [
      {
        "id": "drv-01",
        "full_name": "Ahmad Supardi",
        "call_name": "Supardi",
        "status": "tetap",
        "default_unit_number": "001",
        "default_shift": 1,
        "active": true
      }
    ]
  }
  ```
* **Karakteristik:** *Atomic Read* — seluruh konfigurasi rute, unit, dan supir dapat diunduh dalam 1 kali read dokumen per rute.

### 2.3 Koleksi `outbox` (Log Telemetri & Keberangkatan)
* **ID Dokumen:** Auto-generated ID.
* **Skema Dokumen:**
  ```json
  {
    "route_id": "JAK-10",
    "kind": "departed",
    "payload": {
      "departure_id": "dep-101",
      "unit_number": "001",
      "occurred_at": "2026-11-09T08:30:00Z"
    },
    "synced_at": "TIMESTAMP"
  }
  ```

---

## 3. Komponen & Abstraksi Kode (Clean Architecture)

Mengikuti prinsip *Dependency Inversion* (SOLID) yang sudah ada di repositori:

### 3.1 Layanan Autentikasi (`AuthService`)
* Mengimplementasikan `AuthService` yang didefinisikan di `lib/data/auth_service.dart`.
* Membuat kelas `FirebaseAuthService`:
  * Menggunakan `GoogleSignIn` native Android.
  * Mengonversi kredensial Google ke Firebase Auth via `FirebaseAuth.instance.signInWithCredential()`.
  * Membaca dokumen `authorized_dispatchers/{email}` di Firestore.
  * Mempertahankan fallback offline ke `SharedPreferencesSessionStorage` jika perangkat tidak terhubung ke internet.

### 3.2 Klien Sinkronisasi Cloud (`CloudSyncClient`)
* Mengimplementasikan `CloudSyncClient` yang didefinisikan di `lib/data/sync_service.dart`.
* Membuat kelas `FirestoreCloudSyncClient`:
  * `pullRoutes(DateTime? since)`: Mengambil dokumen dari koleksi `routes` yang memiliki timestamp `updated_at > since`.
  * `pushDrivers(String routeIdentifier, List<Driver> drivers)`: Mengunggah pembaruan supir ke dokumen rute terkait dengan `FieldValue.serverTimestamp()`.
  * `deleteDriverCloud(String routeIdentifier, String driverCallNameOrId)`: Menghapus supir dari daftar array/subkoleksi dokumen rute.
  * `pushOutbox(List<Map<String, dynamic>> items)`: Batch write event keberangkatan ke koleksi `outbox`.

---

## 4. Keamanan & Aturan Akses (Firestore Security Rules)

* Koleksi `authorized_dispatchers`:
  * Baca: Hanya user yang terotentikasi dan membaca dokumen miliknya sendiri (`request.auth.token.email == resource.id`), atau admin rute.
  * Tulis: Hanya admin rute, kecuali pembuatan dokumen baru berstatus `pending`.
* Koleksi `routes`:
  * Baca: Pengguna yang terotentikasi dan memiliki status `is_authorized == true`.
  * Tulis: Pengguna dengan otorisasi aktif.
* Koleksi `outbox`:
  * Tulis (Create): Pengguna dengan otorisasi aktif.

---

## 5. Penanganan Error & Ketahanan Jaringan

1. **Proteksi Offline Penuh:** Kesalahan jaringan Firestore dibungkus try/catch tanpa melempar unhandled exception. Layanan offline SQLite lokal tetap berjalan 100%.
2. **Quota Guard (Spark Plan):** Pengambilan data master hanya dilakukan berbasis delta timestamp (`since`), mencegah pembacaan ulang seluruh database secara berkala.
3. **Umpan Balik UI:** Status sinkronisasi dilaporkan melalui `SyncStatusPill` tanpa memblokir interaksi pengguna di layar.

---

## 6. Verifikasi & Quality Gates

1. **Dependency Hygiene:**
   * Menambahkan `firebase_core`, `cloud_firestore`, dan `firebase_auth` ke `pubspec.yaml` menggunakan `pnpm`.
   * Memastikan kompatibilitas versi Flutter 3.10+ / Dart 3.
2. **Static Analysis:**
   * Menjalankan `flutter analyze` dengan target **0 issues / 0 warnings**.
3. **Unit Testing:**
   * Memastikan seluruh unit test parsing domain model (`HedgeRoute`, `FleetUnit`, `Driver`) dan integrasi sync lulus 100%.
4. **Theme Testing:**
   * Memastikan seluruh elemen visual (login form, sync indicator) tetap kontras dan ergonomis di Dark Mode dan Light Mode.
5. **Branch Guard:**
   * Seluruh pekerjaan dieksekusi secara ketat di branch `devmode`.
