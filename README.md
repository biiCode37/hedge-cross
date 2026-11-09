# HEDGE — Headway Generator

By Mikrotrans Utara. Migrasi native Android, iOS, dan Windows dari HEDGE web/PWA.

Implementasi berada di `D:/MINE/HEDGE-FLUTTER`, branch **devmode**. Flutter 3.38.5 / Dart 3.10.4. Source dan APK terbaru **2.1.8+21 / 2.1.8** memuat integrasi backend cloud **Google Firebase (Cloud Firestore & Firebase Auth)** yang anti-sleep 24/7 dan 100% gratis permanen. Paket APK release terbaru dibangun pada 2026-11-09 setelah perintah eksplisit user. Lihat [paket dan bukti build terbaru](docs/build-2.1.8-2026-11-09.md).

## Mulai Menggunakan

Android adalah target utama di lapangan. Paket APK siap instalasi tersedia di [`apks/v2.1.8/hedge-v2.1.8.apk`](apks/v2.1.8/hedge-v2.1.8.apk) (sekitar 70.9 MB, SHA-256 terverifikasi di dokumen build). Pasang APK langsung ke smartphone dispatcher Android.

Data awal mencakup 18 rute resmi Mikrotrans Jakarta Utara (JAK.01 s.d. JAK.120) dengan 586 armada unit dan data pramudi riil yang tersinkronisasi otomatis via Cloud Firestore. Tanggal dan jam jadwal menggunakan Asia/Jakarta (WIB), terlepas dari zona waktu komputer/perangkat.

1. **Login 1-Ketukan Google:** Masuk menggunakan akun Google dispatcher yang telah terdaftar di whitelist.
2. Pilih rute dan tanggal layanan di Cockpit.
3. Di **Armada**, kelola status armada unit dan penugasan pramudi (Shift 1 & Shift 2).
4. Di **Urutan**, atur rotasi unit dengan drag-and-drop atau panah urutan.
5. Di **Jadwal → Atur**, pilih jam operasional, interval ritase, headway jam sibuk (peak) dan preferensi alarm TTS.
6. **Buat jadwal** menghasilkan revisi tersimpan di database SQLite lokal (`hedge_v2.sqlite`).
7. **Jadwal → ⋯ → Hitung ulang sisa hari** mempertahankan rencana yang telah lewat dan menerapkan draft terbaru pada menit berikutnya.
8. Tombol **Sudah Berangkat** pada alert headway atau ikon centang pada baris mencatat aktual keberangkatan armada secara real-time.
9. **Papan** menampilkan keberangkatan gabungan atau rute aktif dan menjaga layar smartphone tetap menyala (*wakelock*).
10. **Jadwal → ⋯ → Ekspor jadwal** menyediakan format TXT, clipboard WhatsApp, XLSX semua rute, dan PDF.
11. Pengaturan menyediakan tema gelap/terang/sistem, manajemen pramudi, backup/restore JSON, dan pemantauan sinkronisasi cloud.

## Arsitektur Data (Offline-First Hybrid)

- **Database Lokal (Perangkat):** Drift / SQLite (`hedge_v2.sqlite`) dalam mode WAL (*Write-Ahead Logging*). Berfungsi sebagai *Single Source of Truth* utama di perangkat, menjamin operasional tetap instan dan berjalan 100% lancar walau tanpa sinyal internet di terminal atau garasi.
- **Database Cloud (Server):** Google Cloud Firestore (Project `hedge-mikrotrans`, Region `asia-southeast2` Jakarta). Mengelola sinkronisasi master rute, armada, pramudi, antrean outbox, dan whitelist dispatcher tanpa risiko suspend/sleep otomatis.
- **Autentikasi:** Native Google Sign-In terintegrasi dengan Firebase Authentication dan pemeriksaan whitelist izin akses $O(1)$ di koleksi `authorized_dispatchers`.

## Design System

Nomor unit menjadi fokus visual pertama, diikuti countdown headway, jam WIB, rute, dan ritase. UI memakai permukaan *Deep Obsidian Surface*, aksen *Amber Glow* `#FF9800`, dan *Electric Cyan* `#00E5FF`. Countdown otomatis berubah amber pada 60 detik terakhir sebelum waktu keberangkatan.

Lihat [panduan design system](docs/design-system.md) serta dokumen spesifikasi terkait.

## Menjalankan dan Memverifikasi

Perintah di bawah kompatibel dengan Git Bash / zsh:

```bash
cd /d/MINE/HEDGE-FLUTTER
git branch --show-current  # Wajib 'devmode'
flutter pub get
flutter analyze           # Verifikasi 0 issues
flutter test              # Verifikasi 142/142 test lulus
flutter run -d windows    # Uji coba desktop Windows
```

> **Catatan Build APK:**  
> Build APK hanya dilakukan jika ada instruksi eksplisit dari pengguna sesuai aturan operasional repositori.

## Struktur Kode

- `lib/domain`: model data immutable (`HedgeRoute`, `FleetUnit`, `Driver`), waktu WIB, dan algoritma scheduler pure Dart.
- `lib/application`: state management Riverpod (`WorkspaceController`, `AuthController`, `SyncController`), adapter notifikasi audio & alarm.
- `lib/data`: Drift/SQLite repository, `FirebaseAuthService`, `FirestoreCloudSyncClient`, export/import service.
- `lib/ui`: antarmuka Cockpit F-35, Board, Configuration sheet, Master Pramudi, Login, dan Guard Whitelist.
- `test`: 142 skenario pengujian unit dan widget di kedua tema (Dark & Light).
- `docs/refactor/`: catatan teknis investigasi masalah, solusi arsitektur, verifikasi pengujian, dan analogi non-teknis.
- `apks/`: arsip paket APK resmi per versi folder (misal `apks/v2.1.8/hedge-v2.1.8.apk`).
