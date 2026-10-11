# 02. Perbaikan & Solusi Kode — Halaman JADWAL & Papan HEDGE

Dokumen ini memuat arsitektur solusi teknis, cetak biru perbaikan kode (*code blueprint*), serta pemetaan file yang dimodifikasi untuk menyelesaikan seluruh temuan pada halaman **JADWAL** dan mode **Papan HEDGE**.

---

## 1. Arsitektur Solusi & Alur Data Baru

Perbaikan ini difokuskan pada pemulihan integritas data operasional, penyelarasan alur kerja lapangan, dan peningkatan ergonomi dispatcher dengan prinsip:
1. **Zero Data Loss & Resilience:** Armada yang belum berangkat tidak boleh hilang dari pantauan sebelum ada konfirmasi definitif.
2. **Two-Way Action Safety:** Setiap aksi pencatatan harus memiliki pengaman (*haptic/debounce*) dan mekanisme pembatalan (*Undo*).
3. **High-Contrast Legibility:** Tampilan linimasa dan gauge harus terbaca jelas baik di bawah terik matahari siang hari (Light Mode) maupun di malam hari (Dark Mode).

---

## 2. Rincian Perbaikan Kode Berdasarkan Temuan

### Solusi 1: Pembenahan Logika `selectDispatchFocus` (Mengatasi BUG-01 & BUG-02)
- **Target File:** [`lib/application/dispatch_focus.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart)
- **Konsep Solusi:**
  Hapus ketergantungan `minimum` terhadap `route.alarmDuration`. Unit pertama dalam daftar yang **belum tercatat berangkat** (`!actual.contains(departure.id)`) adalah unit yang berhak menjadi fokus. Jika waktu rencananya sudah lewat, tandai unit tersebut sebagai `due: true` dan sertakan selisih keterlambatannya (*overdue*).

```dart
// Blueprint Solusi: lib/application/dispatch_focus.dart
DispatchFocus? selectDispatchFocus(
  Workspace workspace,
  DateTime now, {
  String? routeId,
}) {
  final actual = workspace.events
      .where((e) => e.kind == 'departed')
      .map((e) => e.departureId)
      .toSet();
  final nowMs = now.toUtc().millisecondsSinceEpoch;
  DispatchFocus? result;
  var bestMs = 0;

  for (final route in workspace.routes) {
    if (routeId == null ? !route.participates : route.id != routeId) continue;
    final revision = route.schedule;
    if (revision == null) continue;
    final rows = revision.departures;
    final dayMs = plannedInstant(revision.date, 0).millisecondsSinceEpoch;

    // Cari armada pertama yang BELUM berangkat
    for (final departure in rows) {
      if (actual.contains(departure.id)) continue;

      final atMs = dayMs + departure.minute * 60000;
      final candidate = (
        route: route,
        revision: revision,
        departure: departure,
        due: atMs <= nowMs,
      );

      final tie =
          result != null &&
          atMs == bestMs &&
          '${route.id}:${departure.id}'.compareTo(
                '${result.route.id}:${result.departure.id}',
              ) < 0;

      if (result == null || atMs < bestMs || tie) {
        result = candidate;
        bestMs = atMs;
      }
      break; // Ambil armada tertunda/terdekat pertama per rute
    }
  }
  return result;
}
```

---

### Solusi 2: Penanganan Armada Terlambat pada Papan HEDGE (Mengatasi BUG-02)
- **Target File:** [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart)
- **Konsep Solusi:**
  Daftar baris pada Papan HEDGE tidak boleh mengabaikan armada hanya karena jam rencananya sudah lewat. Selama belum ada catatan `hasDeparted`, armada wajib ditampilkan dengan status **TERLAMBAT** / **BOARDING** agar supir dan penumpang tahu armada tersebut tertahan.

```dart
// Blueprint Solusi: lib/ui/board.dart
for (final route in routes) {
  final revision = route.schedule;
  if (revision == null) continue;
  for (final row in revision.departures) {
    final at = plannedInstant(revision.date, row.minute);
    // Tampilkan semua armada yang belum berangkat (termasuk yang terlambat)
    // ATAU armada yang waktu rencananya belum lewat
    if (!workspace.hasDeparted(row.id)) {
      rows.add((route: route, revision: revision, row: row, at: at));
    }
  }
}
```

---

### Solusi 3: Fitur Pembatalan Keberangkatan / Undo Record (Mengatasi BUG-03)
- **Target File:** [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart), [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)
- **Konsep Solusi:**
  1. Tambahkan fungsi `unrecord(String departureId)` di `WorkspaceController`.
  2. Saat tombol "SUDAH BERANGKAT" ditekan di kartu fokus, tampilkan SnackBar dengan tombol aksi **"BATALKAN" (Undo)** berdurasi 5 detik.
  3. Pada ubin jadwal yang sudah selesai (centang oranye), berikan kemampuan klik untuk konfirmasi batalkan catatan jika salah input.

```dart
// Blueprint Solusi: lib/application/workspace_controller.dart
Future<bool> unrecord(String departureId) async {
  final updatedEvents = state.workspace.events
      .where((e) => e.departureId != departureId)
      .toList();
  return _save(state.workspace.copyWith(events: updatedEvents));
}
```

```dart
// Blueprint SnackBar Undo: lib/ui/app.dart
if (await controller.record(focus.revision, focus.departure, 'departed')) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Keberangkatan unit ${focus.departure.unitNumber} tercatat.'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'BATALKAN',
        onPressed: () async {
          await controller.unrecord(focus.departure.id);
        },
      ),
    ),
  );
}
```

---

### Solusi 4: Koreksi Istilah Operasional & Format Overdue (Mengatasi UX-06 & UX-07)
- **Target File:** [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart), [`lib/application/dispatch_focus.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart)
- **Konsep Solusi:**
  1. Ubah label `"WAKTU TIBA"` menjadi `"WAKTU BERANGKAT"` atau `"SIAP BERANGKAT"`.
  2. Perbaiki fungsi `formatCountdown` agar ketika waktu bernilai negatif (terlambat), menampilkan durasi keterlambatan (misal `+01:30`).

```dart
// Blueprint Solusi: lib/application/dispatch_focus.dart
String formatCountdown(Duration duration) {
  final isNegative = duration.isNegative;
  final absSeconds = duration.inSeconds.abs();
  final h = absSeconds ~/ 3600;
  final m = absSeconds % 3600 ~/ 60;
  final s = absSeconds % 60;
  final prefix = isNegative ? '+' : '';
  return '$prefix${h > 0 ? '${h.toString().padLeft(2, '0')}:' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
```

---

### Solusi 5: Interaksi Cepat Dispatch di Papan HEDGE (Mengatasi UX-05)
- **Target File:** [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart)
- **Konsep Solusi:**
  Berikan parameter `onDispatch` pada `DepartureFocusPanel` di dalam `BoardScreen`, serta tambahkan kemampuan tap pada ubin linimasa dengan konfirmasi modal cepat. Dispatcher yang menggunakan mode Kiosk tablet tidak perlu keluar layar hanya untuk mencatat angkot berangkat.

---

### Solusi 6: Perbaikan Kontras Light Mode (Mengatasi A11Y-11 & A11Y-12)
- **Target File:** [`lib/ui/schedule_timeline.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/schedule_timeline.dart), [`lib/ui/dispatch_components.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart)
- **Konsep Solusi:**
  1. Pada Light Mode, warna rel garis putus-putus transit menggunakan `#94A3B8` (slate-400) atau `p.border.withValues(alpha: 0.9)` tanpa alpha 0.4 yang berlebihan, sehingga rasio kontras mencapai > 3:1.
  2. Track lingkaran gauge countdown pada Light Mode menggunakan `p.border` (`#CBD5E1`) atau `p.raised` bergaris tegas, bukan `p.focusSurface` (`#EAF5FC`) yang menyatu dengan putih.

---

### Solusi 7: Sinkronisasi Filter Ritase & Telemetri Bar (Mengatasi UX-09 & UX-10)
- **Target File:** [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart), [`lib/ui/telemetry_bar.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/telemetry_bar.dart)
- **Konsep Solusi:**
  1. Jika `roundFilter != null`, `FleetTelemetryPillBar` menampilkan nomor ritase yang sedang difilter.
  2. Jika `nextGap == null`, tampilkan label `'Terakhir'` alih-alih angka dummy `'3m'`.

---

### Solusi 8: Penanganan Alert Dialog Fullscreen Keberangkatan & Fallback In-App (Mengatasi BUG-16)
- **Target File:**  
  - [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart)  
  - [`lib/ui/alarm_overlay.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart)  
  - [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt)  
  - [`android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimeline.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimeline.kt)
- **Konsep Solusi:**
  1. **Aktifkan In-App Overlay di Flutter saat Foreground:**  
     Ubah `app.dart` agar `ForegroundAlarmOverlay` **tetap aktif** saat aplikasi sedang dibuka di foreground Android (tidak hanya non-Android). Dengan demikian, jika dispatcher sedang menatap layar Jadwal atau Papan HEDGE, dialog modal keberangkatan langsung muncul di atas layar secara mulus (*zero OS permission blocking*).
     ```dart
     // Blueprint Solusi: lib/ui/app.dart
     builder: (context, child) => Stack(
       children: [
         child!,
         const ForegroundAlarmOverlay(), // Selalu aktif di foreground app untuk garansi visual
       ],
     ),
     ```
  2. **Perpanjang Window Validitas Alarm Native (Grace Period):**  
     Pada `AlarmTimeline.kt`, hilangkan pemangkasan kaku 8 detik untuk dialog fullscreen saat armada belum dikonfirmasi berangkat. Berikan batas toleransi aktif (misal 60-120 detik) agar `AlarmActivity` tidak langsung `finish()` akibat sedikit keterlambatan siklus intent.
  3. **Banner Audit Izin Fullscreen Intent & Overlay:**  
     Pada halaman Jadwal, tampilkan pill/banner peringatan jika izin Android `USE_FULL_SCREEN_INTENT` atau `SYSTEM_ALERT_WINDOW` belum diberikan oleh pengguna, dengan tombol satu ketukan menuju menu pengaturan sistem Android terkait.

---

## 3. Rencana Implementasi & Pemetaan File

| File yang Dimodifikasi | Perubahan Utama |
|---|---|
| [`lib/application/dispatch_focus.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/dispatch_focus.dart) | Hapus drop-off 8 detik; dukung format keterlambatan `+mm:ss` |
| [`lib/application/workspace_controller.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart) | Tambah method `unrecord(departureId)` untuk membatalkan catatan keberangkatan |
| [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart) | Tampilkan armada terlambat; ganti "WAKTU TIBA"; aktifkan tombol dispatch di FIDS |
| [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart) | Aktifkan `ForegroundAlarmOverlay` di Android; aksi Undo pada SnackBar; sinkronisasi filter ritase & telemetri; auto-rollover tanggal |
| [`lib/ui/alarm_overlay.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart) | Dukung aksi catat berangkat instan & tema kontras tinggi |
| [`lib/ui/schedule_timeline.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/schedule_timeline.dart) | Perbaiki kontras rel Light Mode; perbaiki semantik aksesibilitas TalkBack |
| [`lib/ui/dispatch_components.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart) | Perbaiki kontras track gauge Light Mode; optimasi pembungkus animasi |
| [`android/app/src/main/kotlin/.../AlarmTimeline.kt`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmTimeline.kt) | Perpanjang masa berlaku aktif event fullscreen agar tidak prematur `finish()` |
| [`test/board_screen_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/board_screen_test.dart) | Perbarui ekspektasi label "WAKTU BERANGKAT" dan pengujian unit terlambat |
