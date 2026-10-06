# File perubahan alarm — source 2.0.2+3

Implementasi di D:/MINE/HEDGE-FLUTTER pada branch **devmode**, 2026-10-05. Source versi 2.0.2+3. **Tidak ada build APK** pada sesi implementasi 2026-10-05; paket dist/output versi 2.0.1 tetap sama dan belum memuat perubahan alarm.

Tombol alert **Sudah Berangkat** mencatat aktual dan mempertahankan fitur alarm untuk keberangkatan berikutnya. Timeout 1–300 detik menutup instance tanpa mencatat aktual. Pengaturan alarm per rute berlaku segera setelah disimpan. Background/lock/process death ditangani antrean serta Activity native Android, dengan batas izin, heads-up dan Force Stop sebagaimana dijelaskan dalam [panduan alarm](<D:/MINE/HEDGE-FLUTTER/docs/alarms.md>).

| File | Perubahan |
| --- | --- |
| [AGENTS.md](<D:/MINE/HEDGE-FLUTTER/AGENTS.md>) | Aturan build APK hanya atas perintah eksplisit user |
| [pubspec.yaml](<D:/MINE/HEDGE-FLUTTER/pubspec.yaml>) | Versi source 2.0.2+3; dependency Dart tetap |
| [lib/domain/models.dart](<D:/MINE/HEDGE-FLUTTER/lib/domain/models.dart>) | Preferensi alarm per rute dengan pembacaan data lama |
| [lib/domain/alarm_plan.dart](<D:/MINE/HEDGE-FLUTTER/lib/domain/alarm_plan.dart>) | Plan seluruh event masa depan dan validasi/idempotensi tindakan native |
| [lib/application/workspace_controller.dart](<D:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart>) | Penyimpanan tindakan native dan preferensi pada clone rute |
| [lib/application/notification_service.dart](<D:/MINE/HEDGE-FLUTTER/lib/application/notification_service.dart>) | Bridge native Android, status izin dan rekonsiliasi antrean |
| [lib/main.dart](<D:/MINE/HEDGE-FLUTTER/lib/main.dart>) | Simpan tindakan ke SQLite sebelum mengakui antrean Android saat startup |
| [lib/ui/configuration.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart>) | Pilihan tahap/tampilan/suara/getaran, lead dan durasi auto-close |
| [lib/ui/alarm_permissions.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/alarm_permissions.dart>) | Panel status izin dan tautan ke pengaturan Android |
| [lib/ui/data_actions.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/data_actions.dart>) | Integrasi panel izin ke pengaturan/data |
| [lib/ui/alarm_overlay.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart>) | Fallback layar penuh saat app aktif dengan timeout dan tombol aktual/OFF |
| [lib/ui/app.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/app.dart>) | Rekonsiliasi saat resume, integrasi overlay dan aksi banner |
| [lib/ui/dispatch_components.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart>) | Jam WIB tetap terbaca pada alert 320 px dengan teks 160% |
| [android/app/build.gradle.kts](<D:/MINE/HEDGE-FLUTTER/android/app/build.gradle.kts>) | Dependency JUnit untuk unit test Kotlin |
| [android/app/src/main/AndroidManifest.xml](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/AndroidManifest.xml>) | Izin full-screen/getaran, Activity dan receiver native |
| [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt>) | MethodChannel alarm dan pemantauan foreground |
| [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimeline.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimeline.kt>) | Pemilihan due, expiry, prioritas, pengamanan OFF dan aktual |
| [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt>) | Plan durable, AlarmManager, notification/full-screen intent, receiver dan tindakan |
| [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt>) | Layar native dengan showWhenLocked/turnScreenOn, tema, timeout, Sudah Berangkat dan OFF |
| [android/app/src/main/res/values/styles.xml](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/res/values/styles.xml>) | Theme Activity alarm |
| [android/app/src/main/res/values-night/styles.xml](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/res/values-night/styles.xml>) | Theme Activity alarm untuk night resources |
| [android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimelineTest.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimelineTest.kt>) | 8 unit test antrean, waktu, expiry, OFF, aktual dan delivery terlambat |
| [test/alarm_test.dart](<D:/MINE/HEDGE-FLUTTER/test/alarm_test.dart>) | 10 test plan, storage/backup, bridge Android, konfigurasi dan alert kedua tema |
| [test/design_system_test.dart](<D:/MINE/HEDGE-FLUTTER/test/design_system_test.dart>) | Finder panel fokus disesuaikan ketika overlay alert tampil |
| [README.md](<D:/MINE/HEDGE-FLUTTER/README.md>) | Source versus APK lama serta instruksi build eksplisit saja |
| [docs/alarms.md](<D:/MINE/HEDGE-FLUTTER/docs/alarms.md>) | Pengaturan, arsitektur, batas Android dan matriks uji fisik |
| [docs/alarm-changes.md](<D:/MINE/HEDGE-FLUTTER/docs/alarm-changes.md>) | Inventaris perubahan sesi alarm ini |
| [docs/design-system.md](<D:/MINE/HEDGE-FLUTTER/docs/design-system.md>) | Pemisahan durasi fokus panel dengan durasi alert penuh |
| [docs/migration/implementation-status.md](<D:/MINE/HEDGE-FLUTTER/docs/migration/implementation-status.md>) | Bukti final 2.0.2 tanpa build APK |
| [docs/migration/changed-files.md](<D:/MINE/HEDGE-FLUTTER/docs/migration/changed-files.md>) | Inventaris semua source/dokumen migrasi |

Aturan yang sama juga ditambahkan ke [AGENTS.md repository web](<D:/MINE/HEDGE/AGENTS.md>). File source web app.js tidak berubah.

Verifikasi: analyzer tanpa issue; **50 Flutter test**, **8 Kotlin test**, **53 karakterisasi legacy pnpm** lulus. Kotlin dikompilasi tanpa assemble/package APK. Tema gelap/terang diuji pada alert 320×640 dengan teks 160%. Kedua repository tetap devmode. Belum ada uji runtime HP fisik atau build APK fitur ini. [Status lengkap](<D:/MINE/HEDGE-FLUTTER/docs/migration/implementation-status.md>).

Update **2026-10-06**: setelah perintah eksplisit user, APK 2.0.2 dibangun dan menggantikan paket dist 2.0.1. Source aplikasi tetap sama. Lihat [hasil dan verifikasi build](<D:/MINE/HEDGE-FLUTTER/docs/build-2026-10-06.md>).

Source berikutnya **2.0.3+4** menambahkan overlay/TTS sesuai keputusan user; lihat [perubahan terbaru](<D:/MINE/HEDGE-FLUTTER/docs/overlay-tts.md>). APK 2.0.2 belum diperbarui pada sesi ini.

## APK 2.0.3 — 2026-10-06

Perbaikan [overlay dan TTS](<D:/MINE/HEDGE-FLUTTER/docs/overlay-tts.md>) sudah disertakan dalam ketiga APK dist 2.0.3 setelah perintah build terbaru user. [Laporan build, checksum dan file yang diperbarui](<D:/MINE/HEDGE-FLUTTER/docs/build-2.0.3-2026-10-06.md>) merupakan status terbaru; bagian sebelumnya adalah riwayat implementasi/build 2.0.2.
