# 02. Perbaikan & Solusi Kode: Penyelarasan Sertifikat OAuth, Penguncian Keystore, & Pemulihan Whitelist

**Tanggal:** 2026-11-24  
**Branch:** `devmode`  
**Topik:** Solusi Komprehensif Skala Industri terhadap Masalah Login Google Sign-In & Whitelist Dispatcher

---

## 1. Arsitektur Solusi Multi-Dimensi

Untuk menjamin *Zero-Regression* dan keandalan login seumur hidup aplikasi, diterapkan 4 pilar perbaikan:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   ARSITEKTUR PERBAIKAN LOGIN HEDGE                     │
└────────────────────────────────────────────────────────────────────────┘
                                    │
    ┌───────────────────────────────┼───────────────────────────────┐
    ▼                               ▼                               ▼
[1. Pendaftaran SHA-1]      [2. Penguncian Keystore]       [3. Konfigurasi OAuth & Auth]
Firebase Management API:    android/app/                   - Unduh google-services.json
- SHA-1 Baru Didaftarkan    hedge_debug.keystore           - Update serverClientId resmi
- SHA-256 Baru Didaftarkan  build.gradle.kts dikunci       - Pemulihan FirebaseAuthService
```

---

## 2. Rincian Perbaikan yang Dilakukan

### 2.1. Pendaftaran SHA-1 & SHA-256 Baru ke Firebase Console via API
Menggunakan Firebase Management API resmi, sidik jari keystore aktif telah didaftarkan ke proyek `hedge-mikrotrans` (`817255308741`):
* **SHA-1:** `71:FF:E7:43:2E:9B:E6:F8:BE:7D:85:5B:49:53:F9:0E:87:D5:A6:74` (`sha/c94d18ea9ce85c21`)
* **SHA-256:** `BC:E4:37:10:E3:9F:80:D9:8D:1A:06:2F:6C:58:3C:4B:B9:8C:42:AD:F4:45:ED:B3:F8:DD:F0:93:E5:D3:CA:A5` (`sha/af0427956a43ba4a`)
* **Status:** Aktif berdampingan dengan sertifikat lama `49:78:...` sehingga backward-compatible.

### 2.2. Penguncian Keystore Permanen di Repositori (`hedge_debug.keystore`)
1. Menyalin keystore aktif ke `android/app/hedge_debug.keystore`.
2. Memperbarui `android/app/build.gradle.kts` agar mengunci penandatanganan release dan debug ke keystore tersebut:
```kotlin
    signingConfigs {
        create("hedgeRelease") {
            storeFile = file("hedge_debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("hedgeRelease")
        }
        debug {
            signingConfig = signingConfigs.getByName("hedgeRelease")
        }
    }
```

### 2.3. Pembaruan Berkas `android/app/google-services.json`
Mengunduh konfigurasi terbaru langsung dari Firebase yang memuat pemetaan klien:
* Klien Android (`client_type: 1`) dengan hash `71ffe7432e9be6f8be7d855b4953f90e87d5a674`.
* Web Client ID (`client_type: 3`): `817255308741-ahol6ca8618rojo8o4nst5gs8hsuka25.apps.googleusercontent.com`.

### 2.4. Penyelarasan `serverClientId` & Pemulihan Whitelist Dispatcher
1. **`lib/data/auth_service.dart`:**
   * Memperbarui default `serverClientId` pada `FirebaseAuthService` dan `SupabaseAuthService` ke Web Client ID resmi `817255308741-ahol6ca8618rojo8o4nst5gs8hsuka25.apps.googleusercontent.com`.
   * Menambahkan normalisasi email `toLowerCase()` pada kedua service.
2. **`lib/application/auth_controller.dart`:**
   * Menghubungkan provider `authServiceProvider` kembali ke `FirebaseAuthService` agar memvalidasi 7 akun dispatcher resmi yang sudah terdaftar aktif di Firestore.
   * Sinkronisasi data rute, armada, dan pramudi tetap ditangani secara penuh oleh Supabase (`SupabaseCloudSyncClient`).
