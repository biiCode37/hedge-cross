# Build APK HEDGE 2.0.4 (TTS Lifecycle Audio Recovery Update) — 2026-10-10

User menginstruksikan membangun APK terbaru setelah penyelesaian perbaikan menyeluruh pada siklus hidup audio TTS (*Text-to-Speech*) dan pemulihan fokus audio di lingkungan Android native. Source **2.0.4+7** selesai diverifikasi dan ketiga APK split-per-abi berhasil dibangun pada branch **devmode**. Paket di `dist` memuat seluruh perbaikan pemulihan audio, ketahanan foreground service, dan pembaruan antarmuka.

---

## Fitur Baru & Peningkatan yang Disertakan

1. **Pemulihan Siklus Hidup Audio TTS & Service State Machine**:
   - Menghilangkan *race condition* saat mematikan dan menghidupkan kembali fitur suara alarm: service lama yang sedang dalam proses `stopSelf()` ditandai dengan flag `stopping` sehingga `sync()` segera menyalakan instance service baru yang bersih via `startForegroundService()`.
   - Mengatur ulang `foregroundTypes = -1` saat `stopForeground()` dipanggil agar izin eksekusi foreground audio playback di Android 14+ (SDK 34) selalu diperbarui dengan valid.
   - Mekanisme *retry* inisialisasi engine TTS otomatis setelah 1 detik bila proses pelepasan (*unbind*) IPC mesin suara sebelumnya belum tuntas.
   - Isolasi ducking transien audio focus: suara pengumuman armada tidak lagi terputus di tengah jalan akibat bunyi notifikasi WhatsApp, chat, atau nada ketik keyboard HP.
   - Penghapusan kunci kegagalan pemutaran dari set `attempted` agar alarm dapat dicoba ulang pada siklus berikutnya.
   - Pembukaan kembali kunci `spoken` untuk alarm aktif yang suaranya baru saja diaktifkan kembali oleh pengguna melalui menu pengaturan.

2. **Sinkronisasi Tindakan Native Proaktif**:
   - Sinkronisasi tindakan native (`_syncNativeAlarms()`) dieksekusi secara proaktif sebelum membuka dialog pengaturan rute dan secara periodik setiap menit berjalan, mencegah rute terkunci permanen di status *disabled* native pasca penekanan tombol OFF.

3. **Penyempurnaan Antarmuka & UX**:
   - Klarifikasi label konfigurasi audio menjadi *"TTS Bahasa Indonesia mengikuti volume Media/Speaker Android"*.

---

## Paket APK Terverifikasi di `dist/`

| Paket | Target Perangkat | Ukuran | SHA-256 |
| --- | --- | --- | --- |
| [ARM64](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm64.apk) | Android 64-bit (Utama / HP Dispatcher) | 122.9 MB (122,905,365 byte) | `473131202d7051c1c9ece67f723ed480c4fcf3ddb140ba21390662af574e5ce2` |
| [ARM32](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm32.apk) | Android 32-bit (HP Lama / Tablet Entry) | 102.1 MB (102,108,183 byte) | `c5677fe962ac0f0f58a26eda87be5dedb141b3bf6ca740759f8aeac2d9b6302b` |
| [x64](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-x64.apk) | Emulator / Android x86_64 | 108.8 MB (108,825,732 byte) | `589bf13b01ef0a31e25c47b5a275491f92568edf552e6e07d8fc8a471c0e4a4d` |

Hash keluaran build diverifikasi cocok dengan [`dist/SHA256SUMS.txt`](file:///D:/MINE/HEDGE-FLUTTER/dist/SHA256SUMS.txt).

---

## Checklist Verifikasi Kualitas

- [x] Perintah eksplisit build APK dari pengguna telah diterima.
- [x] `flutter build apk --debug --split-per-abi --no-pub` selesai dengan exit code 0.
- [x] SHA-256 checksums diverifikasi cocok dengan `dist/SHA256SUMS.txt`.
- [x] Branch aktif: `devmode`.
- [x] `flutter analyze`: **0 issues found**.
- [x] `flutter test`: **66/66 test cases passed**.
- [x] `pnpm run verify:legacy`: **53/53 legacy oracle cases PASS**.
- [x] `./gradlew :app:testDebugUnitTest`: **BUILD SUCCESSFUL**.
