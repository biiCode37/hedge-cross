# 02. Perbaikan & Solusi Kode: Pengalihan Runtime ke Supabase & Migrasi Pramudi

**Tanggal:** 2026-11-23  
**Branch:** `devmode`  
**Topik:** Migrasi Data Pramudi ke Supabase dan Pengalihan Runtime Provider  

---

## 1. Migrasi Data Pramudi ke Supabase (`master_drivers`)

Dilakukan ekstraksi data 69 pramudi dari dokumen rute JAK.115 Firestore dan dilakukan pengiriman secara batch menggunakan mekanisme `upsert` pada Supabase PostgREST:
* **Target Endpoint:** `https://mkffwfvaxuqifflpeaib.supabase.co/rest/v1/master_drivers?on_conflict=route_uuid,call_name`
* **Header:** `Prefer: resolution=merge-duplicates,return=representation`
* **Hasil:** 69 data pramudi riil (58 tetap, 11 cadangan) berhasil di-upsert dan terintegrasi ke dalam tabel `master_drivers`, menjadikan total data pramudi di Supabase sebanyak 70 baris.

---

## 2. Rincian Modifikasi Kode

### 2.1. Penyesuaian `SupabaseCloudSyncClient`
Berkas: [`lib/data/sync_service.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/data/sync_service.dart)

1. **Lazy Supabase Instance:**
   Menjadikan `_supabase` aman terhadap kondisi runtime test/offline dengan try-catch agar tidak menyebabkan unhandled exception ketika Supabase belum terinisialisasi.
2. **Katalog Statis UUID Fallback:**
   Menambahkan `_catalogRouteUuids` yang memetakan seluruh 18 kode rute mikrotrans (JAK.01 s/d JAK.120) ke UUID resminya.
3. **Fallback Cerdas di `pullRoutes`:**
   Jika query ke `master_routes` menghasilkan `[]`, klien secara otomatis melakukan query langsung ke tabel `master_drivers`, mengelompokkan pramudi per `route_uuid`, dan mengembalikannya ke layer aplikasi.
4. **Proteksi di `mergeCloudRoutesIntoLocal`:**
   Mencegah penimpaan metadata rute lokal (`name`, `color`, `config`) apabila data cloud hanya menyuplai payload pramudi (`raw['route_code'] == null`).
   Melakukan auto-pairing otomatis untuk unit yang belum memiliki supir berdasarkan `defaultUnitNumber` pramudi.

### 2.2. Pengalihan Provider Dependensi
1. **Entrypoint Utama ([`lib/main.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/main.dart)):**
   Mengganti inisialisasi Firebase dengan inisialisasi Supabase:
   ```dart
   await Supabase.initialize(
     url: 'https://mkffwfvaxuqifflpeaib.supabase.co',
     publishableKey: 'sb_publishable_g0BlvGNUb-uK98bvgc0gmQ_ahCSH3xD',
   );
   ```
2. **Klien Sinkronisasi Cloud ([`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart)):**
   Mengalihkan `cloudSyncClientProvider` dari `FirestoreCloudSyncClient` ke `SupabaseCloudSyncClient`.
3. **Layanan Autentikasi ([`lib/application/auth_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/auth_controller.dart)):**
   Mengalihkan `authServiceProvider` dari `FirebaseAuthService` ke `SupabaseAuthService`.

### 2.3. Pemeliharaan Dependensi Firebase
Dependensi `firebase_core`, `cloud_firestore`, dan `firebase_auth` di [`pubspec.yaml`](file:///d:/MINE/HEDGE-FLUTTER/pubspec.yaml) tidak dihapus melainkan dibiarkan *dormant* sesuai instruksi pengguna, mencegah potensi error pada kompilasi Gradle native Android.
