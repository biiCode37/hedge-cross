# Perubahan design system HEDGE 2.0.1

Implementasi keputusan brainstorming pada branch devmode, D:/MINE/HEDGE-FLUTTER. Tidak ada perubahan source produksi di D:/MINE/HEDGE dan tidak ada commit/merge/publish.

| File | Perubahan |
| --- | --- |
| [lib/ui/design_system.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/design_system.dart>) | Baru: token warna, dua palette, tipografi, spacing, bentuk, touch target, komponen Material dan tema calendar/input. |
| [lib/ui/dispatch_components.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart>) | Baru: panel nomor unit/countdown bersama, timer consumer dan baris jadwal. |
| [lib/application/dispatch_focus.dart](<D:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart>) | Baru: fokus keberangkatan stabil, hold saat due, pemilihan dengan binary search dan format countdown. |
| [lib/ui/app.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/app.dart>) | Tema terpusat, identitas tiga baris, hierarki jadwal, daftar sliver, tick terpisah dan reduced motion. |
| [lib/ui/board.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/board.dart>) | Panel fokus konsisten, nomor unit lebih besar daripada timer/jam, countdown per baris dan layout dapat scroll. |
| [lib/ui/configuration.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart>) | Tinggi sheet memperhitungkan keyboard dan safe area. |
| [test/design_system_test.dart](<D:/MINE/HEDGE-FLUTTER/test/design_system_test.dart>) | Baru: kontras, fokus/actual/ack, format sub-detik, urgency, identitas widget antar-tick dan navigasi teks 160%. |
| [test/widget_test.dart](<D:/MINE/HEDGE-FLUTTER/test/widget_test.dart>) | Preview data contoh sebelum keberangkatan, font asli dimuat sekali untuk capture. |
| [pubspec.yaml](<D:/MINE/HEDGE-FLUTTER/pubspec.yaml>) | Versi 2.0.1+2; dependency tetap. |
| [README.md](<D:/MINE/HEDGE-FLUTTER/README.md>) | Ringkasan perilaku desain, versi dan tautan preview. |
| [docs/design-system.md](<D:/MINE/HEDGE-FLUTTER/docs/design-system.md>) | Baru: keputusan, token peran, hierarki, interaksi, strategi performa dan cara verifikasi. |
| [docs/design-system-changes.md](<D:/MINE/HEDGE-FLUTTER/docs/design-system-changes.md>) | Baru: inventaris perubahan sesi desain. |
| [docs/migration/implementation-status.md](<D:/MINE/HEDGE-FLUTTER/docs/migration/implementation-status.md>) | Bukti pengujian dan build versi desain terbaru. |
| [docs/migration/changed-files.md](<D:/MINE/HEDGE-FLUTTER/docs/migration/changed-files.md>) | Inventaris project diperbarui agar mencakup file baru. |

Preview yang diperbarui:

- [Dispatcher 360 dark](<D:/MINE/HEDGE-FLUTTER/docs/screenshots/dispatcher-360-dark.png>)
- [Dispatcher 360 light](<D:/MINE/HEDGE-FLUTTER/docs/screenshots/dispatcher-360-light.png>)
- [Dispatcher 1200 dark](<D:/MINE/HEDGE-FLUTTER/docs/screenshots/dispatcher-1200-dark.png>)
- [Dispatcher 1200 light](<D:/MINE/HEDGE-FLUTTER/docs/screenshots/dispatcher-1200-light.png>)

Pengujian: `flutter analyze --no-pub` tanpa masalah; `flutter test --no-pub` 40/40 lulus; `pnpm run verify:legacy` 53/53 lulus. Teks 160% diuji dengan ukuran viewport 320×640 pada keempat tab dan papan. Tick countdown tidak membangun ulang widget baris jadwal yang sama. Tidak ada klaim FPS/baterai/alarms dari perangkat fisik.

Paket APK dan checksum disimpan di dist setelah build. Versi dan pemeriksaan paket dicatat di implementation-status.md. Ini masih signing debug untuk pengujian internal.