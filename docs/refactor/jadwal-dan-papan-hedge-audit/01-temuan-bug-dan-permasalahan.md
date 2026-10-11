# 01. Temuan Bug & Permasalahan — Halaman JADWAL & Papan HEDGE

Dokumen ini memuat laporan investigasi teknis mendalam mengenai kekurangan, bug logika, celah keamanan data operasional, serta defisiensi UI/UX pada halaman **JADWAL** dan mode **Papan HEDGE (FIDS)** di aplikasi HEDGE (Headway Generator by Mikrotrans Utara).

---

## 1. Ringkasan Eksekutif Temuan

Hasil audit menyeluruh terhadap kode sumber menemukan **16 permasalahan teridentifikasi**, yang diklasifikasikan ke dalam 4 tingkatan keparahan:
1. **Kritis / Fatal (5 Temuan):** Bug logika data flow dan kegagalan pemunculan alert dialog fullscreen keberangkatan yang berpotensi merusak integritas jadwal operasional angkot di lapangan.
2. **Defisiensi UX & Alur Kerja Lapangan (6 Temuan):** Friksi ergonomis yang memperlambat dan membingungkan dispatcher saat kondisi ramai penumpang/armada.
3. **Aksesibilitas & Dual-Theme Contrast (3 Temuan):** Masalah keterbacaan di bawah sinar matahari langsung pada Light Mode serta ambiguasi screen-reader TalkBack.
4. **Performa & Konsumsi Baterai (2 Temuan):** Beban rendering 60 FPS dan kalkulasi layout ganda (*IntrinsicHeight*) yang berpotensi memicu *jank* dan boros baterai pada Android *entry-level*.

---

## 2. Analisis Mendalam: Kategori Kritis & Cacat Logika

### TEMUAN-01 (KRITIS): Bug Drop-Off 8 Detik pada `selectDispatchFocus`
- **File Terdampak:** [`lib/application/dispatch_focus.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart#L30-L65)
- **Akar Masalah (Root Cause):**
  Logika pencarian armada aktif mengaitkan batas toleransi waktu keterlambatan (`holdMs`) secara langsung dengan `route.alarmDuration` (default: 8 detik):
  ```dart
  final holdMs = route.alarmDuration.clamp(1, 60) * 1000;
  final minimum = nowMs - dayMs - holdMs;
  var low = 0;
  var high = rows.length;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (rows[middle].minute * 60000 <= minimum) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  ```
- **Kondisi Pemicu Kegagalan:**
  1. Unit 01 memiliki jadwal keberangkatan pukul 07:00:00 WIB.
  2. Armada tertahan di pintu keluar shelter selama 10 detik karena antrean angkot lain.
  3. Pada pukul 07:00:10 WIB (hanya 10 detik setelah waktu jadwal), nilai `minimum` menjadi `07:00:02`.
  4. Binary search menggeser indeks `low` melompati Unit 01!
  5. `DepartureFocusPanel` seketika melompat ke Unit 02 (jadwal 07:10:00).
- **Dampak Fatal di Lapangan:**
  Dispatcher yang melihat angkot meluncur keluar shelter pada detik ke-10 refleks menekan tombol besar **"SUDAH BERANGKAT"**. Tanpa disadari, tombol tersebut telah mencatat **Unit 02 berangkat 10 menit lebih cepat**, sementara Unit 01 tertinggal dalam status tak tercatat. Integritas data headway dan laporan harian langsung rusak seketika.

---

### TEMUAN-02 (KRITIS): Armada Terlambat Lenyap dari Papan HEDGE (FIDS Kiosk)
- **File Terdampak:** [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart#L47-L52)
- **Akar Masalah (Root Cause):**
  Penyaringan baris keberangkatan pada Papan HEDGE mengeliminasi armada yang waktu rencananya sudah lewat, kecuali armada tersebut berstatus sebagai armada fokus saat itu:
  ```dart
  if (!workspace.hasDeparted(row.id) &&
      (!at.isBefore(now.toUtc()) || row.id == focus?.departure.id)) {
    rows.add((route: route, revision: revision, row: row, at: at));
  }
  ```
- **Kondisi Pemicu Kegagalan:**
  Menggabungkan Temuan-01: Begitu keterlambatan melewati 8 detik, unit tersebut bukan lagi `focus`. Seketika itu pula `!at.isBefore(now.toUtc())` bernilai false dan `row.id == focus?.departure.id` bernilai false.
- **Dampak Fatal di Lapangan:**
  Armada yang belum berangkat dan sedang terlambat lenyap secara gaib dari layar monitor Papan HEDGE. Penumpang dan pengemudi di shelter tidak dapat melihat status armada tersebut sama sekali.

---

### TEMUAN-03 (KRITIS): Ketiadaan Fitur Pembatalan / Undo Catatan Keberangkatan
- **File Terdampak:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart#L518), [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart#L236)
- **Akar Masalah (Root Cause):**
  Tombol `SlideAwayDispatchAction` mengeksekusi pencatatan langsung ke penyimpanan lokal secara permanen tanpa dialog konfirmasi dan tanpa mekanisme pembalikan (*undo/rollback*).
  Model `Workspace` dan controller tidak menyediakan method `undoRecord` atau `deleteEvent`.
- **Dampak Fatal di Lapangan:**
  Sentuhan tidak sengaja pada saku atau saat ponsel berguncang mencatat keberangkatan yang keliru. Dispatcher tidak memiliki tombol untuk membatalkannya. Satu-satunya cara perbaikan saat ini adalah ekspor file JSON, manipulasi manual string data mentah, dan impor ulang.

---

### TEMUAN-04 (KRITIS): Jebakan "Layanan Selesai" Palsu Akibat Rollover Tanggal
- **File Terdampak:** [`lib/domain/models.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart#L21-L30), [`lib/application/dispatch_focus.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart#L30)
- **Akar Masalah (Root Cause):**
  Nilai `workspace.date` tersimpan statis sebagai string tanggal (misal `"2026-10-09"`). Ketika aplikasi dibiarkan terbuka atau dibuka keesokan paginya (misal `"2026-10-10"` pukul 05:00 WIB), `workspace.date` tidak melakukan auto-rollover ke hari ini.
  `plannedInstant(revision.date, ...)` menghitung waktu kemarin (24 jam yang lalu).
- **Dampak Lapangan:**
  Di awal shift pagi buta, kartu fokus di halaman Jadwal menampilkan **"Layanan selesai"** dan Papan HEDGE menampilkan **"Tidak ada keberangkatan mendatang"**. Dispatcher pemula mengira aplikasi error atau jadwal terhapus.

---

### TEMUAN-16 (KRITIS): Tidak Munculnya Alert Dialog Fullscreen Keberangkatan di Android
- **File Terdampak:**  
  - [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart#L56)  
  - [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt#L158-L194)  
  - [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt#L22)  
  - [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt#L25)
- **Akar Masalah (Root Cause):**
  1. **Flutter In-App Overlay Dibungkam di Android:**  
     Di `lib/ui/app.dart` baris 56:
     ```dart
     if (notifications?.isAndroid != true) const ForegroundAlarmOverlay(),
     ```
     Pada ekosistem Android, Flutter `ForegroundAlarmOverlay` **tidak pernah di-render sama sekali**. Flutter menyerahkan 100% pemunculan dialog visual kepada native Android (`AlarmActivity`).
  2. **Pembatasan Ketat Izin OS Android (Android 10+ & Android 14+):**  
     - Android 10+ melarang peluncuran Activity dari background/service (*Background Activity Starts Restriction*).
     - Android 14+ membatasi `USE_FULL_SCREEN_INTENT`. Tanpa persetujuan eksplisit pengguna via pengaturan sistem, `builder.setFullScreenIntent(...)` dibatalkan secara diam-diam oleh OS.
     - `AlarmDeliveryService.kt` dan `AlarmOverlay.kt` mewajibkan izin `Settings.canDrawOverlays(context)` (`SYSTEM_ALERT_WINDOW` / "Tampilkan di atas aplikasi lain"). Jika izin ini belum diaktifkan oleh pengguna, service menghentikan proses (*return*) dan overlay mati total.
  3. **Masa Berlaku Kedaluwarsa Hanya 8 Detik:**  
     Di `AlarmTimeline.kt`, filter `visible(c)` memeriksa `it.expiresAt > now` di mana `expiresAt = shownAt + 8000ms`. Begitu ada latensi eksekusi intent 8 detik, `events.isEmpty()` terjadi seketika, dan `AlarmActivity.kt` langsung menutup diri (`finish(); return`).
  4. **Ketiadaan Fallback In-App Modal Dialog:**  
     Ketika dispatcher sedang membuka aplikasi (misal sedang memantau halaman Jadwal atau Papan HEDGE), tidak ada dialog in-app lokal Flutter yang muncul sebagai cadangan jika `AlarmActivity` native gagal atau terhalang oleh sistem operasi.
- **Dampak Fatal di Lapangan:**  
  Dispatcher tidak menerima peringatan visual dialog layar penuh saat jam keberangkatan tiba. Hanya ada suara audio TTS (jika menyala) tanpa dialog visual interaktif di layar untuk mencatat armada langsung. Peringatan darurat visual menjadi tidak berfungsi.

---

## 3. Analisis Defisiensi UX & Alur Kerja Lapangan

### TEMUAN-05: Papan HEDGE Bersifat Pasif Penuh (Zero-Interaction Trap)
- **File Terdampak:** [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart#L151)
- **Deskripsi:** Di layar Papan HEDGE, widget `DepartureFocusPanel` dipanggil tanpa parameter `onDispatch`. Ubin linimasa `CyberBoardTimelineTile` juga tidak memiliki event sentuhan (*onTap*).
- **Dampak:** Pada tablet yang dipasang di pos dispatcher dengan layar tetap menyala (*wakelock*), dispatcher tidak bisa menandai keberangkatan langsung dari layar tersebut. Mereka terpaksa keluar layar (Back) -> masuk tab Jadwal -> klik berangkat -> buka lagi Papan HEDGE (4 langkah interaksi ekstra setiap 5-10 menit).

---

### TEMUAN-06: Kerancuan Label "WAKTU TIBA" pada Jadwal Keberangkatan
- **File Terdampak:** [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart#L583), [`test/board_screen_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/board_screen_test.dart#L112)
- **Deskripsi:** Ketika hitung mundur mencapai nol (`due == true`), label penunjuk waktu berganti menjadi `"WAKTU TIBA"`.
- **Dampak:** HEDGE adalah sistem generator keberangkatan (*departure generator*) di titik awal terminal. Menyebut waktu keberangkatan yang telah jatuh tempo sebagai "Waktu Tiba" (Arrival) menimbulkan kerancuan fatal bagi supir dan dispatcher (disangka jadwal angkot tiba dari rute luar).

---

### TEMUAN-07: Timer Membeku pada "00:00" Tanpa Indikator Keterlambatan
- **File Terdampak:** [`lib/application/dispatch_focus.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart#L81)
- **Deskripsi:** Fungsi `formatCountdown` menggunakan `.clamp(0, 999999)`. Begitu waktu rencana terlewat, angka detik dipatok ke 0 (`00:00`).
- **Dampak:** Dispatcher kehilangan visibilitas mengenai berapa menit sebuah unit telah terlambat (+01:30, +04:15).

---

### TEMUAN-08: Tidak Ada Fitur Lompat / Auto-Scroll ke Jadwal Aktif
- **File Terdampak:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart#L490)
- **Deskripsi:** `CustomScrollView` selalu memuat posisi awal dari jam 05:00 pagi. Pada siang/sore hari (keberangkatan ke-50 ke atas), dispatcher harus melakukan scroll manual berulang-ulang untuk melihat armada yang sedang standby di linimasa.

---

### TEMUAN-09: Inkonsistensi Filter Ritase dengan Telemetri Bar & Kartu Fokus
- **File Terdampak:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart#L497-L508, #L515)
- **Deskripsi:** Saat pengguna memilih "Ritase 2" melalui dropdown filter, bar telemetri di atas tetap menginformasikan Ritase 1 (sesuai unit fokus), dan kartu fokus tetap menampilkan unit Ritase 1. Layar terpecah dalam dua konteks berbeda tanpa penjelas visual.

---

### TEMUAN-10: Indikasi Headway Palsu pada Keberangkatan Terakhir
- **File Terdampak:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart#L504-L507)
- **Deskripsi:** Jika unit fokus adalah keberangkatan penutup hari itu (`nextGap == null`), sistem fallback mengambil `nextGap` dari armada pertama:
  ```dart
  headwayMinutes: focus?.departure.nextGap ?? (revision.departures.isNotEmpty ? (revision.departures.first.nextGap ?? 3) : 3)
  ```
- **Dampak:** Di layar tertulis "Headway 3m" pada perjalanan terakhir malam hari, padahal tidak ada armada berikutnya di belakangnya.

---

## 4. Analisis Aksesibilitas & Dual-Theme Contrast

### TEMUAN-11: Kontras Rel Transit Hilang pada Light Mode
- **File Terdampak:** [`lib/ui/schedule_timeline.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/schedule_timeline.dart#L441), [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart#L396)
- **Deskripsi:** Garis rel digambar menggunakan warna `railColor.withValues(alpha: 0.4)`. Pada Light Mode, `railColor` adalah `#CBD5E1` (abu-abu muda). Penurunan transparansi 40% di atas kanvas putih menghasilkan warna pudar `#EAEEF3` dengan rasio kontras hanya ~1.15:1.
- **Dampak:** Di bawah terik matahari terminal, garis rel vertikal tidak dapat dilihat sama sekali oleh mata manusia.

---

### TEMUAN-12: Track Lingkaran Countdown Tidak Tampak pada Light Mode
- **File Terdampak:** [`lib/ui/dispatch_components.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart#L521)
- **Deskripsi:** Jalur lingkaran gauge (`trackColor`) menggunakan warna `p.focusSurface` (`#EAF5FC`) di atas kartu latar putih (`#FFFFFF`). Rasio kontras hanya 1.08:1 (di bawah batas minimum WCAG 3:1).

---

### TEMUAN-13: Ambiguitas Aksesibilitas TalkBack & Duplikasi Touch Target
- **File Terdampak:** [`lib/ui/schedule_timeline.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/schedule_timeline.dart#L84, #L347)
- **Deskripsi:** Kontainer baris dan tombol centang di sebelah kanan sama-sama memiliki trigger aksi `onRecord`. Pembaca layar TalkBack membaca dua elemen interaktif berturut-turut untuk satu fungsi yang identik tanpa label unit yang terstandarisasi.

---

## 5. Analisis Performa & Efisiensi Baterai

### TEMUAN-14: Overhead `IntrinsicHeight` pada Setiap Baris Linimasa
- **File Terdampak:** [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart#L339), [`lib/ui/schedule_timeline.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/schedule_timeline.dart#L37)
- **Deskripsi:** Menggunakan `IntrinsicHeight` di dalam ubin daftar dinamis memicu *speculative double-pass layout* pada engine Flutter. Hal ini memperlambat proses rendering pada daftar panjang (50-100 baris) di smartphone Android *entry-level*.

---

### TEMUAN-15: Beban Animasi 60 FPS Tanpa Henti pada Kartu Fokus
- **File Terdampak:** [`lib/ui/dispatch_components.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart#L68-L305)
- **Deskripsi:** `AnimatedBuilder` mengulang animasi *pulse* (1400ms) tanpa jeda yang membungkus banyak layer `BoxShadow` dan `CustomPaint`. Pada ponsel dispatcher yang menyala seharian di terminal, ini memicu konsumsi baterai berlebih dan panas perangkat.

---

## 6. Tabel Matriks Ringkasan Temuan

| ID | Komponen / Lokasi | Tingkat Keparahan | Dampak terhadap Dispatcher / Sistem |
|---|---|---|---|
| **BUG-01** | `dispatch_focus.dart` | **Kritis** | Unit telat >8s hilang dari fokus; tombol mencatat unit berikutnya secara keliru |
| **BUG-02** | `board.dart` | **Kritis** | Unit terlambat lenyap seketika dari papan informasi FIDS |
| **BUG-03** | `workspace_controller.dart` | **Kritis** | Tidak ada fungsi *Undo* jika terjadi salah pencet tombol berangkat |
| **BUG-04** | `models.dart` & `app.dart` | **Kritis** | Rollover tanggal tidak otomatis; pagi hari muncul "Layanan selesai" |
| **BUG-16** | `app.dart`, `AlarmEngine.kt`, `AlarmActivity.kt` | **Kritis** | Dialog fullscreen keberangkatan tidak muncul (terblokir izin Android & Flutter overlay mati) |
| **UX-05** | `board.dart` | **Tinggi** | Papan HEDGE pasif total; harus ganti-ganti halaman untuk dispatch |
| **UX-06** | `board.dart` | **Sedang** | Istilah salah "WAKTU TIBA" pada jadwal keberangkatan |
| **UX-07** | `dispatch_focus.dart` | **Sedang** | Hitung mundur stuck di 00:00 tanpa indikator waktu keterlambatan |
| **UX-08** | `app.dart` | **Sedang** | Tidak ada auto-scroll ke unit aktif di halaman Jadwal |
| **UX-09** | `app.dart` | **Rendah** | Filter ritase tidak sinkron dengan telemetry bar & focus card |
| **UX-10** | `app.dart` | **Rendah** | Keberangkatan terakhir menampilkan headway palsu 3m |
| **A11Y-11** | `schedule_timeline.dart` | **Sedang** | Rel linimasa nyaris transparan pada tema terang (Light Mode) |
| **A11Y-12** | `dispatch_components.dart` | **Sedang** | Gauge track lingkaran tidak terlihat di bawah matahari (Light Mode) |
| **A11Y-13** | `schedule_timeline.dart` | **Rendah** | Duplikasi touch target TalkBack pada baris jadwal |
| **PERF-14** | `schedule_timeline.dart` | **Rendah** | `IntrinsicHeight` membebani layout pipeline saat fast-scrolling |
| **PERF-15** | `dispatch_components.dart` | **Rendah** | Animasi berulang tanpa throttle memboroskan baterai dispatcher |
