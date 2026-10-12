# 02. Perbaikan & Solusi Kode — Transformasi Cockpit MFD Console

Dokumen ini memuat arsitektur solusi teknis, detail komponen UI/UX baru, dan modifikasi kode yang diimplementasikan pada [`lib/ui/configuration.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart) dan suite pengujian terkait.

---

## 1. Arsitektur Solusi & Pendekatan Desain

Untuk memecahkan kendala input manual dan linearitas form lama, antarmuka ditransformasikan secara menyeluruh menjadi **Cockpit MFD (Multi-Function Display) Console** bertema *Cyber-Transit*:

```
+-------------------------------------------------------------+
| [=] AVIONICS CONFIG CONSOLE             (x) TUTUP           |
| Multi-Function Display // Parameter Operasional Armada      |
+-------------------------------------------------------------+
| [ OPERASIONAL ]    | [ PEAK HOURS ]    | [ DISPATCH ALARM ] |
+-------------------------------------------------------------+
|                                                             |
| >>> SEGMEN OPERASIONAL:                                     |
|                                                             |
| +-[ JAM DINAS OPERASIONAL ]-------------------------------+ |
| | [ Jam Mulai Dinas ]           [ Jam Selesai Dinas ]     | |
| | (i) 05:00 [TAP UBAH]          (i) 22:00 [TAP UBAH]      | |
| +---------------------------------------------------------+ |
|                                                             |
| +-[ RITME INTERVAL & HEADWAY ]----------------------------+ |
| | Headway Operasional Reguler:                            | |
| | [-]  [  12  ] Menit  [+]                                | |
| | Waktu Istirahat per Putaran:                            | |
| | [-]  [  15  ] Menit  [+]                                | |
| +---------------------------------------------------------+ |
|                                                             |
| [SIMPAN KE DATABASE]              [RESET DEFAULT]           |
+-------------------------------------------------------------+
```

### Pilar Utama Solusi:
1. **Modern Time Picker Dial (`CockpitTimeTile`):**
   - Menghilangkan sepenuhnya input ketik titik dua manual `:`.
   - Menggantinya dengan kartu ubin telemetri interaktif yang membuka dialog dial visual jam 24 format (`showTimePicker(initialEntryMode: TimePickerEntryMode.dial)`).
   - Dilengkapi theming konsisten (`ThemeData` lokal dengan warna Obsidian `#070B12`, Cyan `#00E5FF`, dan Amber `#FF9800`).

2. **Digital Stepper Taktil (`CockpitDigitalStepper`):**
   - Komponen stepper dengan tombol digital `[-]` dan `[+]` berukuran ergonomis (touch-target >44px).
   - Menjaga kompatibilitas dengan tetap menanamkan `TextFormField` di tengah nilai stepper untuk parsing `FormState` dan pengujian otomatis.
   - Mendukung rentang min-max serta kelipatan step.

3. **Segmented Multi-Function Display Navigation (`CockpitMfdSegmentSelector`):**
   - Mengelompokkan konfigurasi menjadi 3 modul kerja terfokus:
     - `OPERASIONAL`: Jam dinas, headway reguler, istirahat rit, dan target rit.
     - `PEAK HOURS`: Jam sibuk pagi & sore beserta headway kompresi peak.
     - `DISPATCH ALARM`: Banner & audio alert, durasi peringatan, toleransi, dan target per putaran.
   - Eliminasi *Quick Preset Chips* sesuai arahan eksplisit pengguna untuk menjaga kerapian konsol.

4. **Cockpit Instrument Frame (`CockpitFrame`):**
   - Membungkus setiap kelompok input dengan garis tepi HUD beraksen sudut (*corner tech brackets*) dan label instrumen monospaced.

---

## 2. Rincian Modifikasi Kode

### A. [`lib/ui/configuration.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart)
1. **Enum Segmentasi MFD:**
   ```dart
   enum CockpitConfigSegment {
     operational,
     peakHours,
     dispatchAlarm,
   }
   ```
2. **Widget `CockpitTimeTile`:**
   - Menangani tap pengguna, membaca jam/menit dari `TextEditingController`, memunculkan `showTimePicker` bertema Cyber-Transit, dan memformat hasilnya kembali ke format `HH:mm`.
   ```dart
   final picked = await showTimePicker(
     context: context,
     initialTime: initialTime,
     initialEntryMode: TimePickerEntryMode.dial,
     builder: (context, child) => Theme(
       data: theme.copyWith(
         colorScheme: isDark
             ? const ColorScheme.dark(
                 primary: Color(0xFF00E5FF),
                 onPrimary: Color(0xFF070B12),
                 surface: Color(0xFF0C1017),
                 onSurface: Color(0xFFE2E8F0),
               )
             : const ColorScheme.light(
                 primary: Color(0xFF0091EA),
                 onPrimary: Colors.white,
                 surface: Color(0xFFF1F5F9),
                 onSurface: Color(0xFF0F172A),
               ),
       ),
       child: child!,
     ),
   );
   ```

3. **Widget `CockpitDigitalStepper`:**
   - Menyediakan tombol `[-]` dan `[+]` dengan callback `decrement` dan `increment`.
   - Mengupdate nilai controller secara reaktif dan memicu validasi form.

4. **Widget `CockpitMfdSegmentSelector`:**
   - Tombol tab segmentasi horizontal beraksen Obsidian-Cyan dengan indikator aktif glow amber/cyan.

5. **Penyempurnaan Teks & Unifikasi Alert:**
   - Mengubah teks opsi mode alert menjadi: *"Layar Penuh (Universal Cockpit HUD)"* dan *"Banner Notifikasi Standar"*.

### B. [`test/alarm_test.dart`](file:///d:/MINE/HEDGE-FLUTTER/test/alarm_test.dart)
- Memperbarui pengujian widget `Configuration saves alarm controls without rebuilding schedule`:
  - Mengetuk tab MFD `DISPATCH ALARM` sebelum mencari kontrol alarm.
  - Mengetuk opsi `Banner notifikasi` lalu menggulir ke stepper `duration` dengan batas scroll yang aman dan presisi.
