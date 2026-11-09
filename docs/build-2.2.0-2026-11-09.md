# Build APK HEDGE 2.2.0 (TTS Audio Independence & Papan HEDGE Kiosk Polish) — 2026-11-09

User menginstruksikan membangun APK rilis terbaru setelah implementasi independensi volume Text-To-Speech (TTS) dan penataan ulang tampilan linimasa Papan HEDGE (FIDS Kiosk). Source **2.2.0+23** selesai diverifikasi pada branch **devmode**.

---

## 1. Fitur Baru & Peningkatan pada Versi 2.2.0

1. **Independensi Volume Suara TTS (Pemisahan Saluran Audio Mandiri):**
   * Output audio Text-To-Speech (TTS) Bahasa Indonesia dan lonceng peringatan (*chime*) resmi dialihkan dari `STREAM_MUSIC` ke saluran sistem **`STREAM_ALARM`** (`AudioAttributes.USAGE_ALARM`).
   * Petugas dispatcher bebas menyetel musik santai pada volume sedang (30%–40%), sementara peringatan keberangkatan TTS HEDGE tetap berkumandang di volume maksimal (100%) tanpa saling mempengaruhi.

2. **Mekanisme Cerdas Auto-Boost & Auto-Restore Volume:**
   * Sebelum alarm berbicara, HEDGE otomatis menaikkan volume saluran alarm ke tingkat maksimal hardware perangkat.
   * Begitu kalimat selesai diucapkan atau dibatalkan, HEDGE langsung memulihkan (*restore*) volume saluran alarm ke setelan awal secara aman.

3. **Audio Ducking Otomatis Pemutar Musik:**
   * Sistem mengirimkan sinyal Audio Focus `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` pada saluran alarm.
   * Musik di latar belakang (Spotify, YouTube Music, dll.) otomatis meredam drastis (*ducked*) selama TTS berbicara, lalu pulih normal secara mulus (*smooth fade-in*).

4. **Integrasi Nama Pramudi pada Panel "Keberangkatan Berikutnya":**
   * Menambahkan badge nama Pramudi bercahaya tepat di bawah nomor kode unit (misal `KWK 222171`) dan di atas lingkaran *countdown* gauge pada komponen utama Papan HEDGE.

5. **Penggantian Label Monoton "STANDBY" dengan Nama Pramudi:**
   * Pada tabel linimasa Papan HEDGE, label teks statis `[ STANDBY ]` kini otomatis digantikan dengan nama Pramudi yang bertugas (seperti `[ 👤 Munif ]`, `[ 👤 Dede ]`, `[ 👤 Rahmat ]`).

6. **Eliminasi Tumpang Tindih & Penataan Sisi Kiri / Kanan Papan HEDGE:**
   * Nomor kode unit armada kini berdiri sendiri di baris bawahnya tanpa badge nama supir horizontal yang meluber, mengeliminasi masalah teks tertindih pada kolom hitung mundur secara permanen.
   * Lebar kolom hitung mundur diperlebar dari 68px ke 80px.
   * Kolom waktu diperlebar ke 60px dan pendaran glow `TransitRailPainter` diperhalus agar tidak meluber menutupi jam.

7. **Quality Gates & Zero Regression:**
   * Unit Test Kotlin Android (`:app:testDebugUnitTest`): **BUILD SUCCESSFUL**.
   * Flutter Test Suite (`flutter test`): **145/145 tests passed**.
   * Flutter Static Analysis (`flutter analyze`): **0 issues found**.

---

## 2. Paket APK Terverifikasi di `apks/v2.2.0/`

| Paket | Target Perangkat | Versi | Ukuran | Checksum SHA-256 |
| :--- | :--- | :--- | :--- | :--- |
| [hedge-v2.2.0.apk](file:///D:/MINE/HEDGE-FLUTTER/apks/v2.2.0/hedge-v2.2.0.apk) | Universal Android (Smartphone Dispatcher) | 2.2.0+23 | 67.7 MB (71.027.724 byte) | `8902BE4ECE6F0A8A9A1BBDE25E4E45DF3815A344774B3C77F3036D0F3E6A9C12` |

---

## 3. Checklist Verifikasi Kualitas

- [x] Perintah eksplisit build APK dari pengguna telah diterima.
- [x] `flutter build apk --release` selesai dengan exit code 0.
- [x] APK diletakkan pada folder khusus versi `apks/v2.2.0/` dengan tepat 1 file APK.
- [x] SHA-256 hash diverifikasi.
- [x] Branch aktif: `devmode`.
- [x] `flutter analyze`: **0 issues found**.
- [x] `flutter test`: **145/145 test cases passed**.
