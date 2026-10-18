# Master Data Pramudi, Penugasan Shift Armada & Integrasi Panggilan TTS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengimplementasikan Master Data Pramudi rute (Tetap & Cadangan), penugasan shift bertandem (Pagi & Siang) pada unit armada dengan tombol swap instan dan rolling massal, jam aplusan independen per rute, serta pelafalan nama supir secara cerdas via tag `{pramudi}` pada TTS alarm keberangkatan.

**Architecture:** 
- Lapisan domain memperluas `HedgeRoute` dengan daftar `drivers: List<Driver>`, `FleetUnit` dengan `driverShift1Id` & `driverShift2Id`, `PlanConfig` dengan `shiftChangeTime`, serta `Departure` & `AlarmEvent` dengan `driverName`.
- `Scheduler` otomatis memetakan nama supir pagi/siang berdasarkan perbandingan waktu keberangkatan terhadap `shiftChangeTime`.
- Native Kotlin `AlarmSpeechText` memproses substitusi `{pramudi}` dengan fallback otomatis yang membersihkan tanda baca saat supir tidak ditugaskan.
- Lapisan UI merombak kartu armada (menghapus subtitle *"Aktif untuk jadwal baru"* dan menambahkan bar supir tandem dengan swap `⇄`), menyediakan modal `DriverMasterSheet`, serta tombol *Rolling Shift Massal*.

**Tech Stack:** Flutter (Dart), Kotlin Android (AlarmSpeechText, AlarmSpec, AlarmEngine), Riverpod, Supabase (`master_routes` JSONB config & `master_drivers`).

## Global Constraints
- Bekerja secara eksklusif pada branch `devmode`.
- **DILARANG KERAS** melakukan build APK (`flutter build apk` dsb.) tanpa perintah eksplisit pengguna.
- Perintah shell command harus kompatibel dengan Git Bash / PowerShell.
- Dual Theme (Dark Obsidian `#0C1017` vs Light Silver `#F8FAFC`) wajib didukung penuh.
- Project ID Supabase: `mkffwfvaxuqifflpeaib`.

---

### Task 1: Domain Models (`Driver`, `FleetUnit`, `PlanConfig`, `Departure`, `AlarmEvent`) & Model Unit Test

**Files:**
- Create: `test/driver_domain_test.dart`
- Modify: `lib/domain/models.dart:37-128`, `lib/domain/models.dart:152-201`, `lib/domain/models.dart:259-312`, `lib/domain/models.dart:314-410`
- Modify: `lib/domain/alarm_plan.dart:3-50`

**Interfaces:**
- Produces:
  - `class Driver` (`id`, `routeId`, `fullName`, `callName`, `status`, `defaultUnitNumber`, `defaultShift`, `active`)
  - `enum DriverStatus { tetap, cadangan }`
  - `FleetUnit.driverShift1Id`, `FleetUnit.driverShift2Id`
  - `PlanConfig.shiftChangeTime` (default `'13:00'`)
  - `Departure.driverName` (`String?`)
  - `AlarmEvent.driverName` (`String`)
  - `AlarmPreferences.prepTemplate` (default: `"{rute} unit {unit}, {pramudi}, {detik} detik lagi."`)
  - `AlarmPreferences.dueTemplate` (default: `"{rute} unit {unit}, {pramudi}, saatnya berangkat."`)

- [ ] **Step 1: Tulis unit test domain untuk model Driver dan ekstensi FleetUnit & PlanConfig**

Buat file `test/driver_domain_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';

void main() {
  group('Driver & Domain Extension Tests', () {
    test('Driver model JSON serialization round-trip', () {
      const driver = Driver(
        id: 'driver-1',
        routeId: 'route-1',
        fullName: 'Bambang Hariyanto',
        callName: 'Bambang',
        status: DriverStatus.tetap,
        defaultUnitNumber: '540',
        defaultShift: 1,
        active: true,
      );

      final json = driver.toJson();
      final restored = Driver.fromJson(json);

      expect(restored.id, 'driver-1');
      expect(restored.fullName, 'Bambang Hariyanto');
      expect(restored.callName, 'Bambang');
      expect(restored.status, DriverStatus.tetap);
      expect(restored.defaultUnitNumber, '540');
      expect(restored.defaultShift, 1);
      expect(restored.active, isTrue);
    });

    test('FleetUnit stores driverShift1Id and driverShift2Id', () {
      const unit = FleetUnit(
        id: 'unit-1',
        number: '540',
        driverShift1Id: 'd-1',
        driverShift2Id: 'd-2',
      );

      expect(unit.driverShift1Id, 'd-1');
      expect(unit.driverShift2Id, 'd-2');

      final copied = unit.copyWith(driverShift1Id: 'd-3');
      expect(copied.driverShift1Id, 'd-3');
      expect(copied.driverShift2Id, 'd-2');
    });

    test('PlanConfig supports shiftChangeTime with default 13:00', () {
      const config = PlanConfig();
      expect(config.shiftChangeTime, '13:00');

      final custom = config.copyWith(shiftChangeTime: '13:30');
      expect(custom.shiftChangeTime, '13:30');
      expect(custom.toJson()['shiftChangeTime'], '13:30');

      final fromJson = PlanConfig.fromJson({
        'start': '05:00',
        'end': '22:00',
        'shiftChangeTime': '14:00',
        'rounds': 8,
      });
      expect(fromJson.shiftChangeTime, '14:00');
    });

    test('Departure stores driverName', () {
      const departure = Departure(
        id: 'dep-1',
        unitId: 'u-1',
        unitNumber: '540',
        ordinal: 1,
        round: 1,
        minute: 330,
        peak: false,
        driverName: 'Bambang',
      );

      expect(departure.driverName, 'Bambang');
      final json = departure.toJson();
      expect(json['driverName'], 'Bambang');
      final restored = Departure.fromJson(json);
      expect(restored.driverName, 'Bambang');
    });
  });
}
```

- [ ] **Step 2: Jalankan test untuk memverifikasi kegagalan (Red)**

Jalankan:
```bash
flutter test test/driver_domain_test.dart
```
Hasil yang diharapkan: FAIL karena `Driver` belum ada dan field belum ditambahkan ke `FleetUnit`, `PlanConfig`, `Departure`.

- [ ] **Step 3: Tambahkan model `Driver` dan perbarui `FleetUnit`, `PlanConfig`, `Departure`, `AlarmPreferences`, serta `HedgeRoute` di `lib/domain/models.dart`**

Ubah [lib/domain/models.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart):
1. Tambahkan `enum DriverStatus { tetap, cadangan }` dan `class Driver`.
2. Perbarui `class FleetUnit`:
   - field `final String? driverShift1Id;`
   - field `final String? driverShift2Id;`
   - update `copyWith`, `toJson()`, `fromJson()`.
3. Perbarui `class PlanConfig`:
   - field `final String shiftChangeTime;` (default `'13:00'`)
   - update `copyWith`, `toJson()`, `fromJson()`.
4. Perbarui `class Departure`:
   - field `final String? driverName;`
   - update `withGap`, `toJson()`, `fromJson()`.
5. Perbarui `class AlarmPreferences`:
   - default `prepTemplate = '{rute} unit {unit}, {pramudi}, {detik} detik lagi.'`
   - default `dueTemplate = '{rute} unit {unit}, {pramudi}, saatnya berangkat.'`
6. Perbarui `class HedgeRoute`:
   - field `final List<Driver> drivers;`
   - update `copyWith`, `toJson()`, `fromJson()`.
7. Perbarui `AlarmEvent` di [lib/domain/alarm_plan.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/alarm_plan.dart):
   - field `final String driverName;`
   - update `toJson()` menyertakan `'driverName': driverName`.

- [ ] **Step 4: Jalankan kembali unit test untuk memverifikasi kelulusan (Green)**

Jalankan:
```bash
flutter test test/driver_domain_test.dart
```
Hasil yang diharapkan: PASS.

- [ ] **Step 5: Commit perubahan Task 1**

```bash
git add test/driver_domain_test.dart lib/domain/models.dart lib/domain/alarm_plan.dart
git commit -m "feat(domain): add Driver entity, shift assignment fields, and route shiftChangeTime"
```

---

### Task 2: Logika Penugasan Supir di `Scheduler` (`generate` & `replan`)

**Files:**
- Create: `test/scheduler_driver_assignment_test.dart`
- Modify: `lib/domain/scheduler.dart:79-118`, `lib/domain/scheduler.dart:120-210`
- Modify: `lib/domain/alarm_plan.dart:53-114`

**Interfaces:**
- Consumes: `HedgeRoute.drivers`, `FleetUnit.driverShift1Id`, `FleetUnit.driverShift2Id`, `PlanConfig.shiftChangeTime`
- Produces:
  - `Departure.driverName` sesuai jam keberangkatan terhadap `shiftChangeTime`.
  - `AlarmEvent.driverName` terisi dari `row.driverName`.

- [ ] **Step 1: Tulis unit test untuk penugasan supir di `Scheduler`**

Buat file `test/scheduler_driver_assignment_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/domain/scheduler.dart';
import 'package:hedge_flutter/domain/alarm_plan.dart';

void main() {
  group('Scheduler Driver Assignment Tests', () {
    const dPagi = Driver(
      id: 'd-pagi',
      routeId: 'r-1',
      fullName: 'Bambang Hariyanto',
      callName: 'Bambang',
      status: DriverStatus.tetap,
    );
    const dSiang = Driver(
      id: 'd-siang',
      routeId: 'r-1',
      fullName: 'Rudi Suherman',
      callName: 'Rudi',
      status: DriverStatus.tetap,
    );

    const unit = FleetUnit(
      id: 'u-1',
      number: '540',
      active: true,
      driverShift1Id: 'd-pagi',
      driverShift2Id: 'd-siang',
    );

    final route = HedgeRoute(
      id: 'r-1',
      name: 'JAK.115',
      color: 0xFF00E5FF,
      units: [unit],
      order: ['u-1'],
      drivers: [dPagi, dSiang],
      config: const PlanConfig(
        start: '06:00',
        end: '20:00',
        shiftChangeTime: '13:00',
        rounds: 4,
      ),
    );

    test('Scheduler.generate assigns morning driver before 13:00 and afternoon driver at or after 13:00', () {
      const scheduler = Scheduler();
      final schedule = scheduler.generate(
        route,
        date: '2026-10-18',
        revisionId: 'rev-1',
        createdAt: DateTime.utc(2026, 10, 18, 5, 0),
      );

      final morningRows = schedule.departures.where((d) => d.minute < 13 * 60).toList();
      final afternoonRows = schedule.departures.where((d) => d.minute >= 13 * 60).toList();

      expect(morningRows.isNotEmpty, isTrue);
      expect(afternoonRows.isNotEmpty, isTrue);

      for (final row in morningRows) {
        expect(row.driverName, 'Bambang');
      }
      for (final row in afternoonRows) {
        expect(row.driverName, 'Rudi');
      }
    });

    test('buildAlarmPlan propagates driverName to AlarmEvent', () {
      const scheduler = Scheduler();
      final schedule = scheduler.generate(
        route,
        date: '2026-10-18',
        revisionId: 'rev-1',
        createdAt: DateTime.utc(2026, 10, 18, 5, 0),
      );

      final workspace = Workspace(
        routes: [route.copyWith(schedule: schedule)],
        activeRouteId: 'r-1',
        date: '2026-10-18',
      );

      final events = buildAlarmPlan(workspace, DateTime.utc(2026, 10, 18, 0, 0));
      expect(events.any((e) => e.driverName == 'Bambang'), isTrue);
    });
  });
}
```

- [ ] **Step 2: Jalankan test untuk memverifikasi kegagalan (Red)**

```bash
flutter test test/scheduler_driver_assignment_test.dart
```

- [ ] **Step 3: Implementasikan logika resolusi supir di `Scheduler` & `buildAlarmPlan`**

Di `lib/domain/scheduler.dart`:
1. Buat helper lookup:
   ```dart
   final driversById = {for (final d in route.drivers) d.id: d};
   final unitsById = {for (final u in route.units) u.id: u};
   final shiftCutoff = parseMinute(route.config.shiftChangeTime);
   ```
2. Pada pembuatan setiap row `Departure`:
   ```dart
   final targetUnit = unitsById[assignedUnitId];
   final isMorning = timeMinute < shiftCutoff;
   final driverId = isMorning ? targetUnit?.driverShift1Id : targetUnit?.driverShift2Id;
   final driverName = driversById[driverId]?.callName ?? '';
   ```
3. Lakukan hal yang sama pada fungsi `replan()`.
4. Di `lib/domain/alarm_plan.dart`:
   Set `driverName: row.driverName ?? ''` saat instansiasi `AlarmEvent`.

- [ ] **Step 4: Jalankan test kembali untuk memverifikasi kelulusan (Green)**

```bash
flutter test test/scheduler_driver_assignment_test.dart
```

- [ ] **Step 5: Commit perubahan Task 2**

```bash
git add test/scheduler_driver_assignment_test.dart lib/domain/scheduler.dart lib/domain/alarm_plan.dart
git commit -m "feat(scheduler): map driver by shiftChangeTime cutoff in generate and replan"
```

---

### Task 3: Integrasi Suara Cerdas TTS Kotlin Android (`{pramudi}` & Fallback)

**Files:**
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt`
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt`
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt`
- Test: `test/alarm_speech_text_test.dart` (Test simuler reguler regex & format)

**Interfaces:**
- Consumes: `AlarmSpec.driverName`
- Produces:
  - Substitusi `{pramudi}` dengan nama supir yang dilafalkan.
  - Graceful fallback: penghilangan `{pramudi}` dan sanitasi tanda koma ganda saat supir kosong.

- [ ] **Step 1: Perbarui `AlarmSpeechText.kt` di Kotlin Android**

Buka [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt):
Tambahkan pemrosesan `{pramudi}`:
```kotlin
val driverSpoken = event.driverName.trim()

var result = chosenTmpl
if (!event.isMultiRoute) {
    result = result.replace(Regex("""(?i)\brute\s*\{rute\}"""), "")
        .replace("{rute}", "", ignoreCase = true)
} else {
    result = result.replace("{rute}", routeSpoken, ignoreCase = true)
}

result = result
    .replace("{unit}", unitSpoken, ignoreCase = true)
    .replace("{pramudi}", driverSpoken, ignoreCase = true)
    .replace("{detik}", secondsSpoken, ignoreCase = true)
    .replace("{jam}", timeFormatted, ignoreCase = true)
    .replace("{ritase}", ritaseSpoken, ignoreCase = true)
    .replace(Regex("""\{[^{}]*\}"""), "")

result = result
    .replace(Regex("""\s*,\s*"""), ", ")
    .replace(Regex("""\s*\.\s*"""), ". ")
    .replace(Regex("""^([,\s.-]+)"""), "")
    .replace(Regex("""(,(\s*,)+)"""), ",")
    .replace(Regex("""\s+"""), " ")
    .trim()
```

- [ ] **Step 2: Perbarui `AlarmSpec` dan `AlarmEngine.kt` untuk menyimpan `driverName`**

Buka [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt):
1. Tambahkan `val driverName: String` ke constructor data class `AlarmSpec`.
2. Di fungsi `spec(j: JSONObject)`:
   `j.optString("driverName", "")`
3. Di fungsi `json(e: AlarmSpec)`:
   `.put("driverName", e.driverName)`

- [ ] **Step 3: Tulis unit test logika sanitasi pelafalan di Dart (Mirror Test)**

Buat `test/alarm_speech_format_test.dart` untuk memverifikasi logika regex format yang sama persis:
```dart
import 'package:flutter_test/flutter_test.dart';

String formatSpeech(String template, {required String unit, required String driver, required String seconds}) {
  var result = template
      .replaceAll('{unit}', unit)
      .replaceAll('{pramudi}', driver)
      .replaceAll('{detik}', seconds);
  
  result = result
      .replaceAll(RegExp(r'\s*,\s*'), ', ')
      .replaceAll(RegExp(r'\s*\.\s*'), '. ')
      .replaceAll(RegExp(r'^([,\s.-]+)'), '')
      .replaceAll(RegExp(r'(,(\s*,)+)'), ',')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return result;
}

void main() {
  test('formatSpeech with driver substitutes properly', () {
    final text = formatSpeech(
      'Unit {unit}, {pramudi}, saatnya berangkat.',
      unit: '540',
      driver: 'Bambang',
      seconds: '10',
    );
    expect(text, 'Unit 540, Bambang, saatnya berangkat.');
  });

  test('formatSpeech without driver cleans duplicate commas cleanly', () {
    final text = formatSpeech(
      'Unit {unit}, {pramudi}, saatnya berangkat.',
      unit: '540',
      driver: '',
      seconds: '10',
    );
    expect(text, 'Unit 540, saatnya berangkat.');
  });
}
```

- [ ] **Step 4: Jalankan test format untuk verifikasi**

```bash
flutter test test/alarm_speech_format_test.dart
```

- [ ] **Step 5: Commit perubahan Task 3**

```bash
git add android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt test/alarm_speech_format_test.dart
git commit -m "feat(speech): support {pramudi} variable with smart fallback sanitization in Android TTS"
```

---

### Task 4: State Management `WorkspaceController` (CRUD Driver, Auto-Pairing, Swap & Rolling)

**Files:**
- Modify: `lib/application/workspace_controller.dart`
- Create: `test/workspace_driver_controller_test.dart`

**Interfaces:**
- Produces:
  - `controller.addDriver(route, driver)`
  - `controller.updateDriver(route, driver)`
  - `controller.deleteDriver(route, driverId)`
  - `controller.setUnitDrivers(route, unitId, {String? shift1Id, String? shift2Id})`
  - `controller.swapUnitDrivers(route, unitId)` (Menukar supir pagi $\leftrightarrow$ siang khusus unit tsb)
  - `controller.rollAllDrivers(route)` (Menukar supir pagi $\leftrightarrow$ siang di semua unit aktif rute)
  - `controller.autoPairDefaultDrivers(route)` (Memasangkan supir tetap bawaan ke unitnya secara otomatis)

- [ ] **Step 1: Tulis unit test untuk controller aksi driver**

Buat `test/workspace_driver_controller_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/domain/models.dart';

void main() {
  test('WorkspaceController driver operations', () async {
    final container = ProviderContainer();
    final controller = container.read(workspaceProvider.notifier);

    final route = HedgeRoute(
      id: 'r-1',
      name: 'JAK.115',
      color: 0xFF00E5FF,
      units: const [
        FleetUnit(id: 'u-1', number: '540', driverShift1Id: 'd-1', driverShift2Id: 'd-2'),
      ],
      order: const ['u-1'],
      drivers: const [
        Driver(id: 'd-1', routeId: 'r-1', fullName: 'Bambang', callName: 'Bambang'),
        Driver(id: 'd-2', routeId: 'r-1', fullName: 'Rudi', callName: 'Rudi'),
      ],
    );

    controller.state = AppState(
      workspace: Workspace(routes: [route], activeRouteId: 'r-1', date: '2026-10-18'),
    );

    // Test Swap
    await controller.swapUnitDrivers(route, 'u-1');
    var updatedUnit = container.read(workspaceProvider).workspace.routes.first.units.first;
    expect(updatedUnit.driverShift1Id, 'd-2');
    expect(updatedUnit.driverShift2Id, 'd-1');

    // Test Rolling All
    await controller.rollAllDrivers(route);
    updatedUnit = container.read(workspaceProvider).workspace.routes.first.units.first;
    expect(updatedUnit.driverShift1Id, 'd-1');
    expect(updatedUnit.driverShift2Id, 'd-2');
  });
}
```

- [ ] **Step 2: Jalankan test untuk memastikan kegagalan (Red)**

```bash
flutter test test/workspace_driver_controller_test.dart
```

- [ ] **Step 3: Implementasikan fungsi-fungsi driver di `WorkspaceController`**

Buka [lib/application/workspace_controller.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/application/workspace_controller.dart):
Implementasikan method:
- `addDriver(HedgeRoute route, Driver driver)`
- `updateDriver(HedgeRoute route, Driver driver)`
- `deleteDriver(HedgeRoute route, String driverId)`
- `setUnitDrivers(HedgeRoute route, String unitId, {String? shift1Id, String? shift2Id})`
- `swapUnitDrivers(HedgeRoute route, String unitId)`
- `rollAllDrivers(HedgeRoute route)`
- `autoPairDefaultDrivers(HedgeRoute route)`

- [ ] **Step 4: Jalankan test kembali untuk memastikan kelulusan (Green)**

```bash
flutter test test/workspace_driver_controller_test.dart
```

- [ ] **Step 5: Commit perubahan Task 4**

```bash
git add test/workspace_driver_controller_test.dart lib/application/workspace_controller.dart
git commit -m "feat(controller): add driver CRUD, swap unit drivers, and mass rolling in WorkspaceController"
```

---

### Task 5: UI Halaman 02 Armada (Pembersihan Subtitle & Bar Supir Tandem dengan Swap)

**Files:**
- Modify: `lib/ui/app.dart` (`_fleet(route)` and `CockpitManifestCard`)
- Create/Modify: `test/fleet_manifest_ui_test.dart`

**Interfaces:**
- Consumes: `FleetUnit.driverShift1Id`, `FleetUnit.driverShift2Id`, `route.drivers`
- UI Changes:
  - Teks `"Aktif untuk jadwal baru"` **dihapus**.
  - Baris Supir Tandem (`☀️ Pagi: [Nama]` `⇄` `🌙 Siang: [Nama]`) dirender rapi di bawah nomor bodi unit.
  - Tombol `⇄` memanggil `controller.swapUnitDrivers(route, unit.id)`.
  - Header memiliki tombol `Kelola Pramudi` dan `Rolling Shift Rute`.

- [ ] **Step 1: Update unit/widget test untuk memverifikasi UI kartu armada baru**

Di `test/fleet_manifest_ui_test.dart`:
Tambahkan pengujian:
- Memastikan teks `'Aktif untuk jadwal baru'` TIDAK ditemukan di pohon widget.
- Memastikan slot supir pagi dan siang muncul pada kartu unit.
- Mengetuk tombol `⇄` memicu pertukaran supir.

- [ ] **Step 2: Jalankan widget test untuk melihat kegagalan (Red)**

```bash
flutter test test/fleet_manifest_ui_test.dart
```

- [ ] **Step 3: Modifikasi UI kartu armada di `lib/ui/app.dart`**

1. Pada [lib/ui/app.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart):
   Hapus teks `unit.active ? 'Aktif untuk jadwal baru' : 'Tidak aktif'` dari `subtitle`.
2. Gantikan dengan bar horizontal supir tandem:
   - Slot chip `☀️ Pagi: [Nama Panggilan]` (warna amber/cyan).
   - Tombol icon `IconButton(icon: Icon(Icons.swap_horiz, size: 16), onPressed: () => controller.swapUnitDrivers(route, unit.id))`.
   - Slot chip `🌙 Siang: [Nama Panggilan]`.
3. Di header atas daftar armada, tambahkan tombol `Kelola Pramudi` dan `Rolling Shift`.

- [ ] **Step 4: Jalankan widget test kembali untuk memverifikasi kelulusan (Green)**

```bash
flutter test test/fleet_manifest_ui_test.dart
```

- [ ] **Step 5: Commit perubahan Task 5**

```bash
git add lib/ui/app.dart test/fleet_manifest_ui_test.dart
git commit -m "feat(fleet): remove redundant active subtitle and integrate tandem driver bar with quick swap"
```

---

### Task 6: Modal Lembar Kerja Master Pramudi (`DriverMasterSheet`)

**Files:**
- Create: `lib/ui/driver_master_sheet.dart`
- Modify: `lib/ui/app.dart` (panggil `DriverMasterSheet` saat tombol Kelola Pramudi ditekan)
- Create: `test/driver_master_sheet_test.dart`

**Interfaces:**
- Produces:
  - Komponen `DriverMasterSheet` (Filter `Semua`, `Tetap`, `Cadangan`, Daftar Driver, Dialog Tambah/Edit).

- [ ] **Step 1: Tulis widget test untuk `DriverMasterSheet`**

Buat `test/driver_master_sheet_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/driver_master_sheet.dart';

void main() {
  testWidgets('DriverMasterSheet renders driver list and allows filtering', (tester) async {
    const d1 = Driver(id: 'd1', routeId: 'r1', fullName: 'Bambang Hariyanto', callName: 'Bambang', status: DriverStatus.tetap);
    const d2 = Driver(id: 'd2', routeId: 'r1', fullName: 'Agus Santoso', callName: 'Agus', status: DriverStatus.cadangan);

    final route = HedgeRoute(
      id: 'r1',
      name: 'JAK.115',
      color: 0xFF00E5FF,
      units: const [],
      order: const [],
      drivers: const [d1, d2],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DriverMasterSheet(route: route),
          ),
        ),
      ),
    );

    expect(find.text('Bambang Hariyanto'), findsOneWidget);
    expect(find.text('Agus Santoso'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Jalankan test untuk memverifikasi kegagalan (Red)**

```bash
flutter test test/driver_master_sheet_test.dart
```

- [ ] **Step 3: Implementasikan `DriverMasterSheet` di `lib/ui/driver_master_sheet.dart`**

Buat file [lib/ui/driver_master_sheet.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/driver_master_sheet.dart):
- Styling Cyberpunk taktis (Dark Obsidian `#0C1017` & Light Silver `#F8FAFC`).
- Form dialog Tambah/Edit Pramudi.
- Hubungkan dengan `WorkspaceController`.

- [ ] **Step 4: Jalankan test untuk memverifikasi kelulusan (Green)**

```bash
flutter test test/driver_master_sheet_test.dart
```

- [ ] **Step 5: Commit perubahan Task 6**

```bash
git add lib/ui/driver_master_sheet.dart lib/ui/app.dart test/driver_master_sheet_test.dart
git commit -m "feat(ui): add DriverMasterSheet for managing route drivers"
```

---

### Task 7: Integrasi Chip `{pramudi}` di Konfigurasi Suara & Tampilan Supir di Jadwal / HUD Alert

**Files:**
- Modify: `lib/ui/configuration.dart` (tambah chip `+ {pramudi}` & update preset)
- Modify: `lib/ui/alarm_overlay.dart` (tampilkan `PRAMUDI: [CALLNAME]` di HUD fullscreen alert)
- Modify: `lib/ui/board.dart` / `lib/ui/cockpit_components.dart` (tampilkan supir di baris jadwal)
- Test: `test/configuration_tts_test.dart`

**Interfaces:**
- Menampilkan supir di layar alert fullscreen saat alarm berbunyi.
- Memungkinkan penambahan chip `{pramudi}` di text editor template alarm.

- [ ] **Step 1: Tambahkan chip `+ {pramudi}` di `lib/ui/configuration.dart`**

Perbarui list chip variabel di [lib/ui/configuration.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart):
Tambahkan `'{pramudi}'` ke daftar tombol quick insertion chips.

- [ ] **Step 2: Tampilkan nama supir di `lib/ui/alarm_overlay.dart`**

Pada tampilan HUD layar penuh ketika alarm aktif:
Tampilkan teks monospace cyan/amber:
`Text('PRAMUDI: ${event.driverName.toUpperCase()}')` jika `event.driverName.isNotEmpty`.

- [ ] **Step 3: Jalankan verifikasi test konfigurasi**

```bash
flutter test test/configuration_tts_test.dart
```

- [ ] **Step 4: Commit perubahan Task 7**

```bash
git add lib/ui/configuration.dart lib/ui/alarm_overlay.dart lib/ui/cockpit_components.dart
git commit -m "feat(ui): add {pramudi} quick chip in configuration and display driver in HUD alert"
```

---

### Task 8: Database Supabase `master_drivers` & Penyesuaian Sinkronisasi

**Files:**
- Modify: `lib/data/sync_service.dart`
- Eksekusi DDL via Supabase MCP tool (`mkffwfvaxuqifflpeaib`)

**Interfaces:**
- Supabase Cloud menyimpan `master_drivers` dan merelasikannya ke `master_routes(uuid)`.
- `sync_service.dart` menarik data pramudi saat pull rute.

- [ ] **Step 1: Eksekusi DDL pembuatan tabel `master_drivers` di Supabase `hedge-cross`**

Gunakan Supabase MCP `execute_sql` pada project `mkffwfvaxuqifflpeaib`:
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

- [ ] **Step 2: Perbarui `sync_service.dart` untuk mem-parse `master_drivers`**

Buka [lib/data/sync_service.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/data/sync_service.dart):
Tambahkan include `master_drivers(*)` pada query select `pullRoutes()`, dan petakan ke `HedgeRoute.drivers`.

- [ ] **Step 3: Verifikasi sinkronisasi dengan unit test**

```bash
flutter test test/sync_service_test.dart
```

- [ ] **Step 4: Commit perubahan Task 8**

```bash
git add lib/data/sync_service.dart
git commit -m "feat(sync): add master_drivers cloud table support and sync integration"
```

---

### Task 9: Verifikasi Penuh Test Suite & Penyusunan 4 Dokumen Refactor

**Files:**
- Create: `docs/refactor/master-pramudi-dan-tts/01-temuan-bug-dan-permasalahan.md`
- Create: `docs/refactor/master-pramudi-dan-tts/02-perbaikan-dan-solusi-kode.md`
- Create: `docs/refactor/master-pramudi-dan-tts/03-verifikasi-dan-hasil-pengujian.md`
- Create: `docs/refactor/master-pramudi-dan-tts/04-analogi-dan-dampak-non-teknis.md`

- [ ] **Step 1: Jalankan seluruh test suite Flutter untuk memastikan ZERO REGRESI**

```bash
flutter test
```
Pastikan seluruh pengujian PASS.

- [ ] **Step 2: Susun 4 Dokumen Refactor Standar Repositori**

Tulis dokumen ke folder `docs/refactor/master-pramudi-dan-tts/`:
1. `01-temuan-bug-dan-permasalahan.md`: Latar belakang ketiadaan data supir, tantangan 2 shift dan rolling, serta redundansi teks subtitle.
2. `02-perbaikan-dan-solusi-kode.md`: Penjelasan arsitektur entitas `Driver`, penugasan supir berdasarkan jam aplusan, bar tandem supir di Halaman 02, dan integrasi Kotlin TTS.
3. `03-verifikasi-dan-hasil-pengujian.md`: Bukti eksekusi unit test, widget test, dan uji fallback TTS.
4. `04-analogi-dan-dampak-non-teknis.md`: Analogi operasional radio pos pantau, perbandingan sebelum vs sesudah, dan dampak langsung bagi dispatcher & supir.

- [ ] **Step 3: Commit akhir dokumen refactor**

```bash
git add docs/refactor/master-pramudi-dan-tts/
git commit -m "docs(refactor): add 4 core refactor documents for master pramudi and tts integration"
```
