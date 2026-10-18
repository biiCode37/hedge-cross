# Perbaikan Arsitektur & Solusi Kode: Master Data Pramudi, Penugasan Shift & Integrasi Suara Alarm TTS

## 1. Arsitektur Solusi Menyeluruh

Untuk menghadirkan integrasi kru pramudi yang fleksibel, robust, dan ergonomis bagi dispatcher lapangan, solusi diimplementasikan secara berlapis mulai dari layer Domain, Scheduler, State Management, UI/UX Cockpit, Android Kotlin Native TTS Engine, hingga Sinkronisasi Supabase Cloud:

```
┌────────────────────────────────────────────────────────┐
│               HEDGE Cyberpunk Cockpit                  │
│  [Halaman 02 Armada]  [DriverMasterSheet]  [Config TTS]│
└──────────────────────────┬─────────────────────────────┘
                           │ Interaksi Pengguna & Dispatcher
┌──────────────────────────▼─────────────────────────────┐
│                 WorkspaceController                    │
│   addDriver() | swapUnitDrivers() | rollAllDrivers()   │
└──────────────────────────┬─────────────────────────────┘
                           │ State Dispatcher
┌──────────────────────────▼─────────────────────────────┐
│             Domain Scheduler (Engine Jadwal)           │
│   Pagi (< shiftChangeTime)  -> driverShift1Id          │
│   Siang (>= shiftChangeTime) -> driverShift2Id         │
└─────────────┬───────────────────────────┬──────────────┘
              │ Event Alarm               │ Cloud Sync
┌─────────────▼──────────────┐ ┌──────────▼──────────────┐
│ Kotlin Native TTS Engine   │ │ Supabase Cloud Database │
│ AlarmSpeechText.kt         │ │ master_drivers table    │
│ Smart Fallback Sanitizer   │ │ (RLS & Cascade Delete)  │
└────────────────────────────┘ └─────────────────────────┘
```

---

## 2. Rincian Implementasi Kode per Layer

### A. Lapisan Domain (`lib/domain/models.dart` & `alarm_plan.dart`)
1. **Entitas `Driver` & `DriverStatus`:**
   ```dart
   enum DriverStatus { tetap, cadangan }

   class Driver {
     final String id;
     final String routeId;
     final String fullName;
     final String callName;
     final DriverStatus status;
     final String? defaultUnitNumber;
     final int? defaultShift; // 1 = Pagi, 2 = Siang
     final bool active;
     ...
   }
   ```
2. **Ekstensi `FleetUnit` & `PlanConfig`:**
   - `FleetUnit` dilengkapi slot: `driverShift1Id` (pagi) dan `driverShift2Id` (siang).
   - `PlanConfig` menyimpan konfigurasi jam aplusan independen per rute: `shiftChangeTime` (default: `'13:00'`).
3. **Penyematan Identitas Supir pada Jadwal & Alarm:**
   - Atribut `driverName` ditambahkan pada entitas `Departure` dan `AlarmEvent`.

---

### B. Otomasi Penugasan Shift di `lib/domain/scheduler.dart`
Dalam siklus pembuatan jadwal (`generate`) maupun penyesuaian operasional (`replan`), supir yang bertugas dipetakan secara akurat:
```dart
final shiftMinutes = parseTimeToMinutes(config.shiftChangeTime);
final isMorningShift = departureMinute < shiftMinutes;
final activeDriverId = isMorningShift ? unit.driverShift1Id : unit.driverShift2Id;
final driver = route.drivers.firstWhereOrNull((d) => d.id == activeDriverId);
final driverName = driver?.callName ?? '';
```
Kaidah ini menjamin armada unit yang sama secara otomatis memanggil nama supir pagi sebelum waktu aplusan, dan berganti memanggil supir siang begitu melewati jam aplusan.

---

### C. Mesin Text-to-Speech Cerdas di Android Kotlin (`AlarmSpeechText.kt`)
Di sisi native Android, pemrosesan variabel `{pramudi}` dilengkapi mekanisme *regex smart-sanitizer* untuk menjamin kelancaran intonasi lafal pengeras suara:
```kotlin
fun format(template: String, unitSpoken: String, driverSpoken: String, secondsSpoken: String): String {
    var result = template
        .replace("{unit}", unitSpoken)
        .replace("{pramudi}", driverSpoken)
        .replace("{detik}", secondsSpoken)

    // Bersihkan spasi ganda, koma ganda atau koma gantung ketika nama supir kosong
    result = result.replace(Regex("\\s*,\\s*"), ", ")
        .replace(Regex("\\s*\\.\\s*"), ". ")
        .replace(Regex("^([,\\s.-]+)"), "")
        .replace(Regex("(,(\\s*,)+)"), ",")
        .replace(Regex("\\s+"), " ")
        .trim()
    return result
}
```
Hasil: Jika `{pramudi}` bernilai `"Bambang"`, template `"Unit {unit}, {pramudi}, saatnya berangkat."` dilafalkan `"Unit 540, Bambang, saatnya berangkat."`. Jika supir belum ditentukan, kalimat dibersihkan menjadi `"Unit 540, saatnya berangkat."` tanpa jeda koma janggal.

---

### D. State Management & Aksi Cepat di `WorkspaceController`
Metode baru yang terintegrasi pada `lib/application/workspace_controller.dart`:
- `addDriver(route, driver)`: Menambahkan supir ke rute aktif.
- `updateDriver(route, driver)`: Memperbarui profil supir (nama, status, unit bawaan).
- `deleteDriver(route, driverId)`: Menghapus supir dan mengosongkan referensi slotnya di unit.
- `setUnitDrivers(route, unitId, {shift1Id, shift2Id})`: Menugaskan supir per shift pada unit.
- `swapUnitDrivers(route, unitId)`: Menukar instan supir pagi $\leftrightarrow$ siang khusus unit tersebut.
- `rollAllDrivers(route)`: Menukar instan supir pagi $\leftrightarrow$ siang di seluruh unit aktif rute.
- `autoPairDefaultDrivers(route)`: Memasangkan supir berstatus tetap ke unit bawaannya secara otomatis.

---

### E. UI/UX Ergonomis & Responsif di Halaman 02 Armada
1. **Pembersihan Subtitle Redundan:**
   - Teks `"Aktif untuk jadwal baru"` dihapus sepenuhnya dari `lib/ui/app.dart`.
2. **Bar Tandem Supir Responsif di `CockpitManifestCard`:**
   - Baris supir dipindahkan ke properti `bottom` pada kartu armada berbingkai chamfered cockpit.
   - Slot chip pagi `☀️ Pagi: [Nama Panggilan]`, tombol swap `IconButton(Icons.swap_horiz)`, dan slot chip siang `🌙 Siang: [Nama Panggilan]` merentang di lebar penuh kartu dengan `TextOverflow.ellipsis`.
3. **Header Aksi Adaptif Bebas Overflow:**
   - Menggunakan `LayoutBuilder` dengan breakpoint 500px dan `SingleChildScrollView(scrollDirection: Axis.horizontal)` pada tombol aksi (`Kelola Pramudi` dan `Rolling Shift`).
   - Mencegah total terjadinya `RenderFlex overflow` pada layar sempit 320px–360px maupun mode pembesaran teks aksesibilitas (scale factor 1.6).
4. **Modal Lembar Kerja Master Pramudi (`lib/ui/driver_master_sheet.dart`):**
   - Panel modal sliding dengan palette warna Cyberpunk Obsidian/Cyan/Amber.
   - Filter tab: `Semua`, `Tetap`, `Cadangan`.
   - Dialog interaktif Tambah/Edit Pramudi dengan validasi data lengkap.

---

### F. Integrasi Chip Suara & HUD Display
1. **Chip Variabel `{pramudi}` di Konfigurasi Suara (`lib/ui/configuration.dart`):**
   - Menambahkan chip `+ {pramudi}` ke selector template alarm, serta memperbarui preset `ringkas` menjadi:
     `"Unit {unit}, {pramudi}, bersiap berangkat."` dan `"Unit {unit}, {pramudi}, berangkat sekarang."`.
2. **Badge Supir di HUD Fullscreen Alert (`lib/ui/alarm_overlay.dart`):**
   - Menampilkan badge monospaced `PRAMUDI: [CALLNAME]` saat alarm visual aktif.
3. **Badge Supir di Papan FIDS Kiosk (`lib/ui/board.dart`):**
   - Menampilkan nama supir berdampingan dengan nomor armada pada jadwal keberangkatan.

---

### G. Skema Cloud Supabase `hedge-cross` & Sinkronisasi Data
1. **Migrasi DDL Tabel `master_drivers`:**
   - Diterapkan pada project `mkffwfvaxuqifflpeaib`:
   ```sql
   CREATE TABLE IF NOT EXISTS master_drivers (
       id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
       uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
       route_uuid UUID NOT NULL REFERENCES master_routes(uuid) ON DELETE CASCADE,
       full_name TEXT NOT NULL,
       call_name TEXT NOT NULL,
       status TEXT NOT NULL DEFAULT 'tetap',
       default_unit_number TEXT,
       default_shift INT,
       active BOOLEAN DEFAULT true,
       created_at TIMESTAMPTZ DEFAULT NOW(),
       updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```
2. **Sinkronisasi di `lib/data/sync_service.dart`:**
   - `pullRoutes()` menarik relasi `master_drivers(*)`.
   - `mergeCloudRoutesIntoLocal()` memetakan driver, mempertahankan penugasan supir lokal yang sudah ada, serta mem-parsing konfigurasi `shiftChangeTime`.

---

## 3. Daftar File yang Dimodifikasi & Dibuat

| Kategori | File | Ringkasan Perubahan |
| :--- | :--- | :--- |
| **Domain** | [lib/domain/models.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart) | Penambahan entitas `Driver`, `DriverStatus`, slot shift `FleetUnit`, dan `PlanConfig.shiftChangeTime` |
| **Domain** | [lib/domain/alarm_plan.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/alarm_plan.dart) | Penambahan field `driverName` pada `AlarmEvent` |
| **Domain** | [lib/domain/scheduler.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/scheduler.dart) | Logika penugasan supir shift pagi vs siang berdasarkan waktu aplusan rute |
| **Controller** | [lib/application/workspace_controller.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart) | Implementasi aksi CRUD supir, auto-pair, swap unit, dan rolling shift massal |
| **UI** | [lib/ui/cockpit_components.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/cockpit_components.dart) | Penambahan slot `bottom` dan optimasi padding vertikal pada `CockpitManifestCard` |
| **UI** | [lib/ui/app.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart) | Pembersihan subtitle redundan, integrasi bar tandem supir, dan header responsif |
| **UI** | [lib/ui/driver_master_sheet.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/driver_master_sheet.dart) | Pembuatan modal lembar kerja master data pramudi berdesain Cyberpunk |
| **UI** | [lib/ui/configuration.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart) | Penambahan chip `+ {pramudi}` dan pembaruan preset template alarm |
| **UI** | [lib/ui/alarm_overlay.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart) | Tampilan badge supir monospaced pada HUD alarm layar penuh |
| **UI** | [lib/ui/board.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart) | Tampilan badge nama supir pada papan keberangkatan kiosk |
| **Data / Cloud** | [lib/data/sync_service.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/data/sync_service.dart) | Query join `master_drivers(*)` dan parsing sinkronisasi rute cloud |
| **Android Native** | [AlarmSpeechText.kt](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt) | Sanitasi pintar pelafalan teks TTS untuk variabel `{pramudi}` |
| **Android Native** | [AlarmEngine.kt](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt) | Penyaluran `driverName` dari alarm spec ke speech player |
| **Test Suite** | `test/driver_domain_test.dart` | Pengujian unit serialisasi dan model domain driver |
| **Test Suite** | `test/scheduler_driver_assignment_test.dart` | Pengujian penugasan supir berdasarkan jam aplusan |
| **Test Suite** | `test/alarm_speech_format_test.dart` | Pengujian logika sanitasi pelafalan TTS |
| **Test Suite** | `test/workspace_driver_controller_test.dart` | Pengujian operasi controller CRUD, swap, dan mass rolling |
| **Test Suite** | `test/driver_master_sheet_test.dart` | Pengujian widget modal lembar kerja master pramudi |
| **Test Suite** | `test/sync_service_test.dart` | Pengujian parsing driver cloud dan preservasi assignment lokal |
| **Test Suite** | `test/fleet_manifest_ui_test.dart` | Pengujian widget kartu armada tandem shift dan swap supir |
