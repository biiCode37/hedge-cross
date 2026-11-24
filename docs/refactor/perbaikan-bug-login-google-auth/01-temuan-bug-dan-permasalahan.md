# 01. Temuan Bug & Analisis Akar Masalah: Kegagalan Login Google Sign-In pada APK Rilis

**Tanggal:** 2026-11-24  
**Branch:** `devmode`  
**Gejala Utama:** Muncul kotak merah bertuliskan *"Gagal masuk dengan Google: PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)"* saat menekan tombol "Masuk dengan Akun Google", mengakibatkan semua akun dispatcher tidak dapat login.

---

## 1. Analisis Akar Masalah (Root Cause Analysis)

Melalui investigasi forensik mendalam terhadap binary APK `v2.2.0` vs `v2.2.1`, konfigurasi Android Gradle, dan Google Cloud/Firebase API, ditemukan **3 akar masalah utama**:

### Root Cause 1: Perubahan SHA-1 Fingerprint Penandatangan APK (Sertifikat Berubah)
1. Sertifikat penandatangan pada APK rilis sebelumnya (`v2.2.0`) memiliki sidik jari:
   * **SHA-1:** `49:78:77:EC:A7:BC:FD:5B:EF:F3:7B:F6:23:A6:E9:20:9A:F3:F5:64`
   * **SHA-256:** `86:19:17:0B:68:90:A2:11:8D:18:A5:DD:03:47:EF:E1:AC:28:1D:BB:7E:10:46:83:33:3C:61:49:88:04:2A:C7`
2. Pada saat kompilasi APK `v2.2.1` kemarin (2026-11-23 18:11 WIB), proses instalasi ulang Android SDK/NDK menyebabkan Gradle membuat file `~/.android/debug.keystore` baru secara acak dengan sidik jari:
   * **SHA-1 Baru:** `71:FF:E7:43:2E:9B:E6:F8:BE:7D:85:5B:49:53:F9:0E:87:D5:A6:74`
   * **SHA-256 Baru:** `BC:E4:37:10:E3:9F:80:D9:8D:1A:06:2F:6C:58:3C:4B:B9:8C:42:AD:F4:45:ED:B3:F8:DD:F0:93:E5:D3:CA:A5`
3. Sidik jari baru ini **belum terdaftar** di OAuth 2.0 Client ID Android pada Google Cloud / Firebase Console. Ketika dispatcher menekan tombol login di perangkat HP, Google Play Services mendeteksi ketidakcocokan sertifikat dan langsung menolak permintaan dengan `ApiException: 10` (`DEVELOPER_ERROR`).

---

### Root Cause 2: Keystore Penandatangan Tidak Dikunci (Dynamic Environment Hazard)
Pada berkas `android/app/build.gradle.kts`:
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```
Konfigurasi ini bergantung pada file `debug.keystore` lokal sistem operasi (`$HOME/.android/debug.keystore`) yang bersifat sementara. Jika file tersebut terhapus atau dibuat ulang di lingkungan build lain, kunci sertifikat berubah dan merusak integrasi Google OAuth secara otomatis.

---

### Root Cause 3: Ketidakcocokan Web Client ID & Otorisasi Whitelist
1. **Hardcoded Client ID Tidak Valid:**
   Pada kode Dart (`lib/data/auth_service.dart` dan `lib/application/auth_controller.dart`), nilai default `serverClientId` disetel ke `1066127378433-k4iqcmqeepbqdcg8agu2tnhqvq85vj3k.apps.googleusercontent.com` (proyek eksternal yang bukan milik Firebase `hedge-mikrotrans`). Padahal Web Client ID resmi proyek adalah `817255308741-ahol6ca8618rojo8o4nst5gs8hsuka25.apps.googleusercontent.com`.
2. **Kekosongan OAuth Client di `google-services.json`:**
   Berkas `android/app/google-services.json` di repositori sebelumnya memiliki array `"oauth_client": []` kosong, sehingga tidak memuat mapping klien Android dan Web Client ID untuk Google Play Services.
3. **Pengalihan Whitelist ke Supabase RLS:**
   Pengalihan ke `SupabaseAuthService` kemarin menyebabkan pembacaan `authorized_dispatchers` gagal karena kebijakan RLS Supabase hanya mengizinkan role `authenticated`, sementara user belum terotentikasi di Supabase. Padahal 7 data akun dispatcher whitelist aktif berada di koleksi `authorized_dispatchers` Cloud Firestore yang terhubung langsung dengan Google Sign-In.
