# HEDGE — Headway Generator

By Mikrotrans Utara. Migrasi native Android, iOS, dan Windows dari HEDGE web/PWA.

Implementasi berada di `D:/MINE/HEDGE-FLUTTER`, branch **devmode**. Flutter 3.38.5 / Dart 3.10.4. Source dan APK terbaru versi 2.0.2 (source 2.0.2+3), dibangun 2026-10-06 atas perintah eksplisit user. Lihat [laporan build](docs/build-2026-10-06.md). Build APK baru hanya dilakukan atas perintah eksplisit user. Aplikasi berada pada tahap uji internal: belum merupakan rilis produksi dan belum terhubung ke server.

## Mulai menggunakan

Android adalah target pertama. Paket siap uji tersedia di `dist/HEDGE-v2-trial-arm64.apk` (ARM64, sekitar 88.8 MiB), `dist/HEDGE-v2-trial-arm32.apk` (ARM32) dan `dist/HEDGE-v2-trial-x64.apk` (emulator x64). Checksum tersedia di `dist/SHA256SUMS.txt`. Paket asli hasil build tersedia di `build/app/outputs/flutter-apk/`. Pasang APK yang cocok dengan perangkat. Data awal JAK.115 memakai 39 unit dari default aplikasi lama; periksa armada, urutan, tanggal dan jam sebelum dipakai operasional. Tanggal dan jam jadwal menggunakan Asia/Jakarta (WIB), terlepas dari zona waktu komputer/perangkat.

1. Pilih rute dan tanggal layanan.
2. Di **Armada**, tambahkan unit dan aktifkan/nonaktifkan unit.
3. Di **Urutan**, tarik unit atau gunakan panah.
4. Di **Jadwal → Atur**, pilih jam, ritase, peak dan preferensi alarm.
5. **Buat jadwal** menghasilkan revisi tersimpan. Mengubah armada/pengaturan tidak mengubah baris revisi sebelumnya.
6. **Jadwal → ⋯ → Hitung ulang sisa hari** mempertahankan rencana yang telah lewat dan menerapkan draft terbaru pada menit berikutnya. Histori rencana bukan bukti keberangkatan aktual.
7. Ikon centang pada baris mencatat keberangkatan aktual. Tombol **Sudah Berangkat** pada alert APK 2.0.2 juga mencatat aktual; timeout hanya menutup alert.
8. **Papan** menampilkan keberangkatan gabungan atau rute aktif dan menjaga layar tetap menyala.
9. **Jadwal → ⋯ → Ekspor jadwal** menyediakan TXT, clipboard, berbagi/WhatsApp, XLSX semua rute dan PDF. Shift dan nomor ritase awal berlaku konsisten pada semua format.
10. Pengaturan menyediakan tema gelap/terang/sistem, backup JSON lengkap dengan histori, dan impor file/tempelan JSON.

Backup JSON untuk pemulihan dapat diimpor ke instalasi kosong/baru. Impor digabung berdasarkan ID, tidak menimpa rute yang sudah ada. Impor yang berisi rute dengan ID sama dianggap sudah masuk; buat backup sebelum perubahan besar.

## Design system

Nomor unit menjadi fokus pertama, lalu countdown, jam WIB, rute dan ritase. UI memakai permukaan solid obsidian/silver, amber branding dan cyan operasional; countdown menjadi amber pada 60 detik terakhir. Komponen countdown diperbarui terpisah dari daftar jadwal. Kedua tema berbagi token yang sama dengan warna teks disesuaikan untuk kontras.

Lihat [panduan design system](docs/design-system.md), [file perubahan desain](docs/design-system-changes.md), serta preview widget [dark](docs/screenshots/dispatcher-360-dark.png) dan [light](docs/screenshots/dispatcher-360-light.png). Preview menggunakan data contoh dan bukan screenshot perangkat fisik.

## Menjalankan dan memverifikasi

Perintah di bawah kompatibel dengan Git Bash / zsh:

```bash
cd /d/MINE/HEDGE-FLUTTER
git branch --show-current  # harus devmode
flutter pub get
flutter analyze
flutter test
pnpm run verify:legacy
flutter run -d windows
# Android: hanya jalankan setelah user memerintahkan build APK (flutter run juga membangun APK).
flutter devices
flutter run -d <device-id>
# Build APK hanya ketika diminta secara eksplisit oleh user.
```

`flutter`/`dart` digunakan untuk project native. `pnpm` hanya menjalankan harness JavaScript warisan. Tidak ada npm/yarn atau server Node yang dibutuhkan oleh app.

Skrip build berikut hanya dijalankan setelah user memberi perintah eksplisit build APK. Untuk host Windows ini, build Java memerlukan direktori socket sementara yang pendek. Skrip `tool/build-android.sh` menyetel properti hanya untuk proses build tanpa mengubah konfigurasi Java global:

```bash
bash tool/build-android.sh debug
# Build lebih kecil per arsitektur (masih signing uji internal):
bash tool/build-android.sh release
```

Android: SDK 36, NDK 28.2.13676358, Java 17, minimum Android API 24 (Android 7). SDK disediakan oleh toolchain lokal, tidak disertakan di repository.

Windows memerlukan Visual Studio 2022 dengan Desktop development with C++, MSVC dan Windows SDK yang dikenali Flutter. Instalasi Build Tools 2026 di komputer ini belum dikenali sebagai toolchain yang sesuai; runner tersedia, build Windows belum terverifikasi. iOS harus dibangun di macOS dengan Xcode, signing Apple dan perangkat uji; source runner tersedia, build iOS belum terverifikasi di host Windows ini.

## Struktur

- `lib/domain`: model immutable, waktu WIB dan scheduler pure Dart, tanpa dependency Flutter.
- `lib/application`: Riverpod controller, pemisahan draft/snapshot, catatan actual/ack, adapter notifikasi.
- `lib/data`: Drift/SQLite dengan transaksi, revisi append-only, ledger, antrean outbox lokal, importer dan exporter.
- `lib/ui`: empat layar dispatcher, konfigurasi, papan gabungan dan alur data.
- `test`: karakterisasi non-peak, validasi kasus tidak aman, invariants lintas 400 kombinasi, peak, replan, SQLite restart/rollback, backup, ekspor, UI smartphone/desktop di kedua tema.
- `docs/migration`: kelima dokumen/fixture/harness analisis yang dipindahkan dari repository web.
- `docs/legacy/app.js`: salinan sumber lama yang dibekukan untuk harness. SHA-256 dan commit asal tercatat di fixture; aplikasi Flutter tidak menjalankannya.

Drift menggunakan custom SQL dalam `GeneratedDatabase`, SQLite native assets dan isolate database. Tidak diperlukan generator kode/build_runner untuk iterasi awal ini. Penyimpanan berada di application-support directory (`hedge_v2.sqlite`); raw import disimpan di subfolder `imports` sebelum validasi.

## Batas versi uji

- Semua data masih lokal. Outbox bertanda `local-only`; belum ada auth, server atau sinkronisasi antarperangkat.
- Source 2.0.2 memakai antrean alarm native Android yang menyimpan semua event masa depan dan menjadwalkan ulang dari receiver. iOS masih memakai 48 pengingat terdekat dengan replenishment ketika app aktif/resume. APK 2.0.2 sudah memuat perubahan native ini; runtime perangkat fisik belum diuji. Lihat [alarm dan batas OS](docs/alarms.md).
- Android membutuhkan izin notifikasi dan izin exact alarm untuk waktu tepat. Tanpa exact alarm, OS menggunakan waktu perkiraan. Pembatasan baterai/vendor dan kondisi perangkat tetap harus diuji di perangkat fisik.
- Peak yang menghasilkan batas waktu tidak konsisten/headway nol atau negatif ditolak; aturan versi lama yang bermasalah tidak direplikasi. Aturan konservatif ini dapat disesuaikan bersama pengguna setelah uji lapangan.
- Layanan lintas tengah malam dan keberangkatan simultan dalam satu rute belum diaktifkan. Satu unit × satu ritase dijadwalkan pada jam mulai.
- Ekspor PNG, edit nomor unit/bulk import armada, pengaturan warna rute, layar histori/recovery lengkap, pengujian perangkat fisik, CI dan signing produksi masih menjadi iterasi berikutnya. Arsip revisi sudah tersimpan dan ikut backup, tetapi belum memiliki layar penelusuran tersendiri.

Lihat [panduan alarm](docs/alarms.md), [file perubahan alarm](docs/alarm-changes.md) dan `docs/migration/implementation-status.md` untuk keputusan sementara serta bukti verifikasi. Blueprint adalah desain target; keberadaan dokumen tersebut tidak berarti semua fase telah diimplementasikan.