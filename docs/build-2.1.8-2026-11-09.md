# Build APK HEDGE 2.1.8 (Google Firebase Cloud Migration) — 2026-11-09

User menginstruksikan membangun APK rilis terbaru setelah keberhasilan migrasi total backend cloud dari Supabase ke **Google Firebase (Cloud Firestore & Firebase Auth)**. Source **2.1.8+21** selesai diverifikasi pada branch **devmode** dan seluruh data master resmi berhasil diinjeksikan.

---

## 1. Fitur Baru & Peningkatan pada Versi 2.1.8

1. **Backend Cloud Google Firebase (Anti-Sleep & 100% Gratis Permanen):**
   * Menggantikan Supabase dengan Google Firebase Spark Plan.
   * Region Datacenter Jakarta (`asia-southeast2`) dengan latensi super cepat (~100 ms).
   * Tidak akan pernah di-pause otomatis walau tidak ada aktivitas selama 7 hari.
   * Zero surprise billing: tidak memerlukan kartu kredit sama sekali.

2. **Injeksi Data Master Penuh dari Backup:**
   * 7 Akun dispatcher whitelist (`biicode37@gmail.com`, `muhammadabyn37@gmail.com`, dsb).
   * 18 Rute resmi Mikrotrans Jakarta Utara (JAK.01 s.d. JAK.120).
   * 586 Armada unit terhubung ke rute masing-masing.
   * 6 Data pramudi riil lapangan lengkap dengan shift dan unit default.

3. **Google Sign-In Native & Security Rules:**
   * Login Google native terhubung langsung dengan Firebase Auth.
   * Aturan keamanan Firestore production membatasi akses data hanya untuk dispatcher berstatus whitelist aktif.

4. **Arsitektur Offline-First & Zero Regression:**
   * Tetap menggunakan SQLite lokal (`hedge_v2.sqlite`) sebagai single source of truth saat offline.
   * 142 dari 142 unit & widget tests lulus 100%.
   * `flutter analyze` 0 issues / 0 warnings.

---

## 2. Paket APK Terverifikasi di `apks/v2.1.8/`

| Paket | Target Perangkat | Versi | Ukuran | Checksum SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| [hedge-v2.1.8.apk](file:///D:/MINE/HEDGE-FLUTTER/apks/v2.1.8/hedge-v2.1.8.apk) | Universal Android (Smartphone Dispatcher) | 2.1.8+21 | 70.9 MB (70.945.612 byte) | `B1B84C0DFF3C55972A3A860C7E36664546801FC4A8400B1133D3B12641928863` |

---

## 3. Checklist Verifikasi Kualitas

- [x] Perintah eksplisit build APK dari pengguna telah diterima.
- [x] `flutter build apk --release` selesai dengan exit code 0.
- [x] APK diletakkan pada folder khusus versi `apks/v2.1.8/` dengan tepat 1 file APK.
- [x] SHA-256 hash diverifikasi.
- [x] Branch aktif: `devmode`.
- [x] `flutter analyze`: **0 issues found**.
- [x] `flutter test`: **142/142 test cases passed**.
