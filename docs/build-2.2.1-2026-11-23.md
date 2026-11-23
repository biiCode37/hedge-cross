# Build APK HEDGE 2.2.1 (Pengalihan Cloud Backend ke Supabase & Sinkronisasi 69 Pramudi) — 2026-11-23

User menginstruksikan membangun APK rilis terbaru setelah implementasi pengalihan cloud backend kembali ke **Supabase PostgreSQL** (`mkffwfvaxuqifflpeaib.supabase.co`), migrasi 69 data pramudi riil JAK.115, serta penyesuaian fallback sinkronisasi offline-first. Source **2.2.1+24** selesai diverifikasi pada branch **devmode**.

---

## 1. Fitur Baru & Peningkatan pada Versi 2.2.1

1. **Pengalihan Runtime Cloud Backend ke Supabase PostgreSQL:**
   * Runtime cloud resmi dialihkan kembali menggunakan Supabase (`https://mkffwfvaxuqifflpeaib.supabase.co`) dengan kunci publishable resmi.
   * `SupabaseCloudSyncClient` dan `SupabaseAuthService` aktif sebagai penyedia layanan cloud utama pada `lib/main.dart`, `AuthController`, dan `WorkspaceController`.
   * Dependensi Firebase dipertahankan dalam mode *dormant* di `pubspec.yaml` untuk menjaga kestabilan build Android native.

2. **Migrasi Lengkap 69 Data Pramudi Riil JAK.115:**
   * Seluruh 69 data pramudi riil (58 supir tetap dan 11 supir cadangan) berhasil dimigrasikan dari Firestore ke tabel `master_drivers` Supabase dengan pemetaan rute, armada KWK, dan shift yang presisi.

3. **Mekanisme Fallback Sinkronisasi Cerdas (Offline-First):**
   * Menambahkan fallback cerdas pada `SyncService.pullRoutes()`: apabila `master_routes` di cloud kosong, sinkronisasi otomatis melakukan kueri langsung ke `master_drivers` untuk mengumpulkan data pramudi dan memetakannya ke rute lokal `JAK.115`.
   * Proteksi `mergeCloudRoutesIntoLocal()` ditingkatkan agar tidak menimpa nama dan konfigurasi rute lokal ketika payload cloud hanya berupa stub driver.

4. **Kestabilan Build Android Gradle & NDK:**
   * Penanganan lisensi otomatis Android SDK NDK (`28.2.13676358` dan `27.0.12077973`), Build-Tools 35, serta Platforms 34, 35, 36.
   * Penyesuaian `android/app/build.gradle.kts` agar Gradle menegosiasikan versi NDK tertinggi yang kompatibel dengan plugin `jni`.

5. **Quality Gates & Zero Regression:**
   * Flutter Static Analysis (`flutter analyze`): **0 issues found**.
   * Flutter Test Suite (`flutter test`): **145/145 tests passed** (100% pass).
   * Gradle Release Build (`flutter build apk --release`): **BUILD SUCCESSFUL**.

---

## 2. Paket APK Terverifikasi di `apks/v2.2.1/`

| Paket | Target Perangkat | Versi | Ukuran | Checksum SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| [hedge-v2.2.1.apk](file:///D:/MINE/HEDGE-FLUTTER/apks/v2.2.1/hedge-v2.2.1.apk) | Universal Android (Smartphone Dispatcher) | 2.2.1+24 | 69.3 MB (72.666.124 byte) | `2B312670C407174409264F52D2AC258C4F8461CC7D1536E9DA69E9D0E966E386` |

---

## 3. Checklist Verifikasi Kualitas

- [x] Perintah eksplisit build APK dari pengguna telah diterima.
- [x] `flutter build apk --release` selesai dengan exit code 0.
- [x] APK diletakkan pada folder khusus versi `apks/v2.2.1/` dengan tepat 1 file APK.
- [x] SHA-256 hash diverifikasi: `2B312670C407174409264F52D2AC258C4F8461CC7D1536E9DA69E9D0E966E386`.
- [x] Branch aktif: `devmode`.
- [x] `flutter analyze`: **0 issues found**.
- [x] `flutter test`: **145/145 test cases passed**.
