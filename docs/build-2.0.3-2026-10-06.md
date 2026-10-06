# Build APK HEDGE 2.0.3 — 2026-10-06

User memerintahkan melanjutkan pekerjaan yang terjeda dan membangun APK terbaru. Source **2.0.3+4** selesai diverifikasi dan ketiga APK debug untuk uji internal berhasil dibangun pada branch **devmode**. Paket di `dist` kini memuat overlay dan TTS pintar yang telah disepakati.

## Perubahan yang disertakan

- Overlay Android berizin untuk alert saat aplikasi lain terbuka; Activity native untuk HEDGE aktif dan layar terkunci. UI berbagi tema gelap/terang, nomor unit, countdown, tombol **Sudah Berangkat**, OFF dan timeout.
- TTS Bahasa Indonesia offline memakai kalimat dan pembacaan nomor unit yang disetujui, termasuk ketujuh contoh di [keputusan dan inventaris source](overlay-tts.md). Notifikasi channel baru tidak memutar ringtone bawaan.
- Audio memakai **volume Alarm Android**, tanpa mengubah volume sistem, sesuai pilihan B. Panel izin menyediakan status, pengaturan suara, **Uji suara TTS** dan tombol penghentian uji.
- Alarm operasional diprioritaskan di atas preview suara. Audio berhenti mengikuti timeout, OFF, aktual atau pergantian tahap persiapan.

## Paket terverifikasi

| Paket | Version code | Ukuran | SHA-256 |
| --- | --- | --- | --- |
| [ARM64](<D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm64.apk>) | 2004 | 93089728 byte (88.8 MiB) | `e1cde4b6b1422cab86bbc5005bf55fcdcc7ebd615ed24565ae91891e94dacd90` |
| [ARM32](<D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm32.apk>) | 1004 | 72292550 byte (68.9 MiB) | `01c733c37fb836976fef8d366fce53eac2a71488c1cd82da710d5ec35c49760f` |
| [x64](<D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-x64.apk>) | 4004 | 79010091 byte (75.3 MiB) | `99e3f36ad80bd70343dd1b02653a49f2b2c81429b2837a9920b43c1f5ee8ca50` |

ARM64 adalah paket utama untuk HP Android 64-bit. Pilih ARM32 untuk perangkat ARM 32-bit atau x64 untuk perangkat/emulator x86_64. Hash output build dan salinan dist cocok dengan [SHA256SUMS.txt](<D:/MINE/HEDGE-FLUTTER/dist/SHA256SUMS.txt>).

## Bukti verifikasi

- [x] `flutter build apk --debug --split-per-abi --no-pub` selesai exit 0; tahap Gradle 147.6 detik.
- [x] Semua paket: package `id.mikrotrans.hedge.hedge_flutter`, versionName **2.0.3**, label **HEDGE**, minSdk **24**, targetSdk **36**, ABI sesuai nama paket.
- [x] Version code naik dari APK 2.0.2: ARM64 **2003 → 2004**, ARM32 **1003 → 1004**, x64 **4003 → 4004**.
- [x] APK Signature Scheme v2 valid; ketiga sertifikat sama dengan APK dist 2.0.2 sebelum diganti. SHA-256 sertifikat: `8619170b6890a2118d18a5dd0347efe1ac281dbb7e104683333c614988042ac7`. Signing tetap debug/internal.
- [x] Manifest terkemas memuat AlarmActivity, AlarmReceiver, **AlarmDeliveryService**, SYSTEM_ALERT_WINDOW, USE_FULL_SCREEN_INTENT, FOREGROUND_SERVICE_MEDIA_PLAYBACK, FOREGROUND_SERVICE_SPECIAL_USE, WAKE_LOCK, tipe layanan, flags showWhenLocked/turnScreenOn dan query TTS_SERVICE.
- [x] Setiap APK memuat SQLite sesuai ABI, logo HEDGE dan dua font Roboto.
- [x] Verifikasi source final sebelum build: analyzer **No issues found**, **52/52 Flutter**, **16/16 Kotlin**, **53/53 legacy pnpm**. Source aplikasi yang lulus ini digunakan untuk build; tes tidak diulang tanpa perubahan source.
- [x] Widget panel izin/TTS gelap dan terang: **320×640, teks 160%** lulus. Tampilan overlay native pada HP tetap perlu diperiksa.
- [x] Branch kedua repository **devmode**; tidak ada commit, merge, install atau publish.
- [ ] Uji HP fisik untuk loudness, overlay di atas aplikasi lain, layar terkunci, TTS, vendor dan lifecycle. Hasil kompilasi/tes bukan bukti runtime tersebut.

## Setelah memasang APK

Buka **Pengaturan & data → Izin alarm perangkat**. Izinkan **tampil di atas aplikasi lain**, notifikasi, alarm tepat dan layar penuh. Gunakan **Uji suara TTS**; jika perlu, aktifkan suara Bahasa Indonesia offline melalui tombol pengaturan suara. Panel menampilkan volume **Alarm Android** yang digunakan HEDGE.

Uji jadwal dekat waktu sekarang ketika memakai aplikasi lain dan saat layar terkunci. Pilih durasi tampil cukup panjang agar kalimat TTS selesai. Catat model HP, versi Android serta penggunaan speaker/Bluetooth/headset jika suara masih kecil atau alert belum muncul. Matriks lengkap dan batas Force Stop ada di [panduan overlay/TTS](overlay-tts.md) dan [panduan alarm](alarms.md).

## File berubah/ditambah

- Ketiga APK dist dan [manifest checksum](<D:/MINE/HEDGE-FLUTTER/dist/SHA256SUMS.txt>).
- [Daftar lengkap 21 file source, tes dan dokumentasi perbaikan](<D:/MINE/HEDGE-FLUTTER/docs/overlay-tts.md>).
- [README](<D:/MINE/HEDGE-FLUTTER/README.md>), [panduan alarm](<D:/MINE/HEDGE-FLUTTER/docs/alarms.md>), [inventaris alarm](<D:/MINE/HEDGE-FLUTTER/docs/alarm-changes.md>), [status implementasi](<D:/MINE/HEDGE-FLUTTER/docs/migration/implementation-status.md>), [inventaris migrasi](<D:/MINE/HEDGE-FLUTTER/docs/migration/changed-files.md>) dan [laporan ini](<D:/MINE/HEDGE-FLUTTER/docs/build-2.0.3-2026-10-06.md>).
- Output asli: `build/app/outputs/flutter-apk/app-{arm64-v8a|armeabi-v7a|x86_64}-debug.apk`. APK universal lama `app-debug.apk` tidak diperbarui oleh split build; gunakan paket dist di atas.

## Menjalankan verifikasi

Git Bash / zsh:

```bash
cd /d/MINE/HEDGE-FLUTTER
git branch --show-current
pnpm run verify:legacy
(cd dist && sha256sum -c SHA256SUMS.txt)
flutter analyze --no-pub
flutter test --no-pub
```

Build berikutnya tetap hanya ketika user memerintahkan secara eksplisit:

```bash
bash tool/build-android.sh debug
```
