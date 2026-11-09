# Build APK HEDGE 2.1.9 (Full Driver Cloud Sync & Unit Card Search) — 2026-11-09

User menginstruksikan membangun APK rilis terbaru setelah penambahan fitur pencarian pramudi pada kartu armada serta penyempurnaan sinkronisasi total seluruh master pramudi perangkat ke **Google Firebase (Cloud Firestore)**. Source **2.1.9+22** selesai diverifikasi pada branch **devmode**.

---

## 1. Fitur Baru & Peningkatan pada Versi 2.1.9

1. **Sinkronisasi Total Seluruh Master Pramudi Perangkat (`syncAllDriversToCloud`):**
   * Tombol Cloud di lembar kerja *Kelola Pramudi* kini memindai seluruh rute di memori/database HP pengguna (`state.workspace.routes`).
   * Seluruh daftar pramudi (termasuk 71 pramudi yang ada di smartphone) langsung disetorkan secara otomatis ke koleksi `routes` masing-masing di Cloud Firebase.

2. **Respon Visual Interaktif & Modal Dialog Konfirmasi:**
   * Tombol Cloud menampilkan animasi berputar (*loading spinner*) saat pengiriman berlangsung untuk mencegah klik ganda (*double-tap*).
   * Menampilkan dialog modal (`AlertDialog`) di bagian depan layar (tidak tertutup bottom sheet) dengan laporan jumlah pasti pramudi dan rute yang berhasil disinkronkan.

3. **Pencarian Reaktif (*Search Bar*) Pemilihan Pramudi Unit:**
   * Menambahkan kotak input pencarian real-time pada modal pemilihan pramudi di setiap kartu armada (Halaman 02 Armada).
   * Dispatcher dapat mencari nama supir secara instan baik via nama panggilan (*call name*) maupun nama lengkap (*full name*), lengkap dengan tombol *clear* dan status hasil filter.

4. **Security Rules Firestore Live Anti-Blokir:**
   * Aturan keamanan Cloud Firestore untuk koleksi `routes` dan `outbox` telah diperbarui dan di-deploy ke server Google Firebase `hedge-mikrotrans` agar setoran data dari smartphone berhasil tanpa terhalang *permission denied*.

5. **Quality Gates & Zero Regression:**
   * `flutter analyze`: **0 issues found**.
   * `flutter test`: **142/142 tests passed**.

---

## 2. Paket APK Terverifikasi di `apks/v2.1.9/`

| Paket | Target Perangkat | Versi | Ukuran | Checksum SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| [hedge-v2.1.9.apk](file:///D:/MINE/HEDGE-FLUTTER/apks/v2.1.9/hedge-v2.1.9.apk) | Universal Android (Smartphone Dispatcher) | 2.1.9+22 | 71.0 MB (71.011.300 byte) | `733DB68741B0FFA4DCBF87EA3FF526355BEA469DF727B5142B328DB048326459` |

---

## 3. Checklist Verifikasi Kualitas

- [x] Perintah eksplisit build APK dari pengguna telah diterima.
- [x] `flutter build apk --release` selesai dengan exit code 0.
- [x] APK diletakkan pada folder khusus versi `apks/v2.1.9/` dengan tepat 1 file APK.
- [x] SHA-256 hash diverifikasi.
- [x] Branch aktif: `devmode`.
- [x] `flutter analyze`: **0 issues found**.
- [x] `flutter test`: **142/142 test cases passed**.
