# Cyber-Transit HUD Telemetry UI/UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mentransformasi UI/UX layar utama dispatcher dan papan keberangkatan HEDGE menjadi Cyber-Transit HUD Telemetry yang modern, responsif, hemat daya, dan berperforma 120 FPS dengan kontrol ergonomis satu jempol.

**Architecture:** Memisahkan komponen UI operasional menjadi modul terisolasi: `design_system.dart` (HUD tokens & palette), `telemetry_bar.dart` (Fleet Telemetry Capsule Bar), `dispatch_components.dart` (Live Capsule Hero, Countdown Ring, Slide-Away Dispatch Action), `schedule_timeline.dart` (Cyber Transit Timeline dengan vertical transit rail), dan `board.dart` (Papan TV FIDS Monitor). Detak detik diisolasi dalam `RepaintBoundary` untuk memastikan re-render 120 FPS bebas jank.

**Tech Stack:** Flutter 3, Dart, Riverpod, CustomPainter, TweenAnimationBuilder, HapticFeedback, WakelockPlus.

## Global Constraints
- **Branch Git**: Bekerja HANYA pada branch `devmode`. Dilarang menyentuh `main`.
- **Aturan Build APK**: Dilarang menjalankan `flutter build apk` sampai user memberikan perintah eksplisit.
- **Dual Theme Support**: Mendukung Dark Mode (`#070B12`) dan Light Mode (`#F8FAFC`) dengan kontras tinggi.
- **Ergonomi Jempol**: Ukuran target sentuh minimal 48–54px pada area aksi utama dispatcher.
- **Bebas Jitter**: Seluruh nilai angka numerik wajib menggunakan `FontFeature.tabularFigures()`.
- **Quality Gates**: `flutter analyze` 0 issues, `flutter test` lulus 100%, `pnpm run verify:legacy` lulus.

---

### Task 1: Token Desain & Sistem Visual Cyber-Transit HUD

**Files:**
- Modify: `lib/ui/design_system.dart`
- Test: `test/design_system_test.dart`

**Interfaces:**
- Consumes: `HedgeTokens`, `HedgePalette`
- Produces: `HedgeTokens.amberGlow`, `HedgeTokens.cyanGlow`, `HedgeTokens.obsidianRaised`, `HedgeTokens.hudBorderRadius`, `HedgeTextStyles.telemetryUnit`, `HedgeTextStyles.telemetryTimer`

- [ ] **Step 1: Tulis unit test untuk token baru Cyber-Transit HUD di `test/design_system_test.dart`**

```dart
test('Cyber-Transit HUD tokens provide high-contrast glowing accents and tabular telemetry styles', () {
  expect(HedgeTokens.amber, const Color(0xffff9800));
  expect(HedgeTokens.cyan, const Color(0xff38bdf8));
  expect(HedgeTokens.numberFeatures, contains(const FontFeature.tabularFigures()));
  final darkPalette = HedgePalette.dark;
  expect(darkPalette.background, const Color(0xff070b12));
  final lightPalette = HedgePalette.light;
  expect(lightPalette.background, const Color(0xfff8fafc));
});
```

- [ ] **Step 2: Jalankan test untuk memverifikasi kesiapan**

Run: `flutter test test/design_system_test.dart`
Expected: PASS

- [ ] **Step 3: Tambahkan token styling HUD & helper text styles di `lib/ui/design_system.dart`**

Tambahkan border radius HUD dan text style telemetry:
```dart
abstract final class HedgeTokens {
  static const amber = Color(0xffff9800);
  static const cyan = Color(0xff38bdf8);
  static const electricCyan = Color(0xff00e5ff);
  static const obsidian = Color(0xff070b12);
  static const obsidianSurface = Color(0xff0c1017);
  static const obsidianRaised = Color(0xff141a24);
  static const silver = Color(0xfff8fafc);
  static const touchTarget = 48.0;
  static const primaryButtonHeight = 54.0;
  static const radius = 12.0;
  static const panelRadius = 20.0;
  static const space = 8.0;
  static const motion = Duration(milliseconds: 180);
  static const slideMotion = Duration(milliseconds: 200);
  static const numberFeatures = [FontFeature.tabularFigures()];
}
```

- [ ] **Step 4: Jalankan test dan analisis statis**

Run: `flutter test test/design_system_test.dart && flutter analyze`
Expected: PASS dan No issues found!

- [ ] **Step 5: Commit perubahan Task 1**

```bash
git add lib/ui/design_system.dart test/design_system_test.dart
git commit -m "feat(ui): tambahkan token desain Cyber-Transit HUD"
```

---

### Task 2: Komponen Fleet Telemetry Capsule Bar

**Files:**
- Create: `lib/ui/telemetry_bar.dart`
- Test: `test/telemetry_bar_test.dart`

**Interfaces:**
- Consumes: `HedgeRoute`, `ScheduleRevision`, `HedgeWorkspace`
- Produces: `FleetTelemetryPillBar(activeUnits: int, currentRound: int, totalRounds: int, headwayMinutes: int)`

- [ ] **Step 1: Tulis unit test untuk `FleetTelemetryPillBar` di `test/telemetry_bar_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'package:hedge_flutter/ui/telemetry_bar.dart';

void main() {
  testWidgets('FleetTelemetryPillBar displays fleet, round, and headway metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: const Scaffold(
          body: FleetTelemetryPillBar(
            activeUnits: 39,
            currentRound: 3,
            totalRounds: 8,
            headwayMinutes: 3,
          ),
        ),
      ),
    );
    expect(find.text('39 Unit Aktif'), findsOneWidget);
    expect(find.text('Ritase 3/8'), findsOneWidget);
    expect(find.text('Headway 3m'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Jalankan test untuk memverifikasi gagal awal (TDD)**

Run: `flutter test test/telemetry_bar_test.dart`
Expected: FAIL (file belum ada)

- [ ] **Step 3: Buat implementasi `FleetTelemetryPillBar` di `lib/ui/telemetry_bar.dart`**

Implementasikan bar horisontal dengan 3 kapsul telemetri:
- Kapsul Unit Aktif (Cyan)
- Kapsul Ritase (Muted/Silver)
- Kapsul Headway (Amber Glow)
Gunakan `SingleChildScrollView(scrollDirection: Axis.horizontal)` agar aman di layar sempit.

- [ ] **Step 4: Jalankan test untuk memverifikasi lulus**

Run: `flutter test test/telemetry_bar_test.dart && flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit perubahan Task 2**

```bash
git add lib/ui/telemetry_bar.dart test/telemetry_bar_test.dart
git commit -m "feat(ui): implementasi FleetTelemetryPillBar"
```

---

### Task 3: Komponen Live Capsule Hero & Slide-Away Dispatch Action

**Files:**
- Modify: `lib/ui/dispatch_components.dart`
- Test: `test/dispatch_components_test.dart`

**Interfaces:**
- Consumes: `DispatchFocus`, `plannedInstant`, `HedgePalette`
- Produces: `LiveCapsuleHero`, `CountdownRing`, `SlideAwayDispatchAction`

- [ ] **Step 1: Tulis unit test untuk `LiveCapsuleHero` dan `CountdownRing` di `test/dispatch_components_test.dart`**

Uji status `WAKTU BERANGKAT` vs `KEBERANGKATAN BERIKUTNYA`, format nomor unit, dan callback tombol sentuh satu jempol dengan getaran taktil.

- [ ] **Step 2: Jalankan test untuk memverifikasi status awal**

Run: `flutter test test/dispatch_components_test.dart`

- [ ] **Step 3: Implementasikan `CountdownRing` dan `LiveCapsuleHero` di `lib/ui/dispatch_components.dart`**

- Buat `CountdownRing` menggunakan `CustomPainter` yang efisien dalam `RepaintBoundary`.
- Tambahkan animasi *Amber Glow pulse* halus saat status `due == true`.
- Tambahkan `SlideAwayDispatchAction` dengan tinggi 54px, `HapticFeedback.mediumImpact()`, dan debounce 500ms.

- [ ] **Step 4: Jalankan test dan pastikan semua lulus**

Run: `flutter test test/dispatch_components_test.dart && flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit perubahan Task 3**

```bash
git add lib/ui/dispatch_components.dart test/dispatch_components_test.dart
git commit -m "feat(ui): implementasi LiveCapsuleHero dengan CountdownRing dan SlideAwayAction"
```

---

### Task 4: Komponen Cyber Transit Timeline Schedule

**Files:**
- Create: `lib/ui/schedule_timeline.dart`
- Test: `test/schedule_timeline_test.dart`

**Interfaces:**
- Consumes: `HedgeRoute`, `ScheduleRevision`, `Departure`, `HedgeWorkspace`
- Produces: `CyberTimelineList`

- [ ] **Step 1: Tulis unit test untuk `CyberTimelineList` di `test/schedule_timeline_test.dart`**

Uji render rel transit vertikal:
- Baris unit yang sudah berangkat (`hasDeparted == true`) memiliki tanda centang emas/amber.
- Baris unit aktif memiliki badge status menyala.
- Baris unit mendatang memiliki garis rel putus-putus.

- [ ] **Step 2: Jalankan test untuk memverifikasi TDD**

Run: `flutter test test/schedule_timeline_test.dart`
Expected: FAIL (file belum ada)

- [ ] **Step 3: Implementasikan `CyberTimelineList` di `lib/ui/schedule_timeline.dart`**

- Gunakan `CustomPainter` untuk menggambar garis rel vertikal (`TransitRailPainter`).
- Tampilkan nomor unit, waktu jadwal, ritase, dan tombol aksi cepat.
- Gunakan `ListView.builder` dengan ukuran item terukur untuk performa 120 FPS.

- [ ] **Step 4: Jalankan test dan pastikan lulus**

Run: `flutter test test/schedule_timeline_test.dart && flutter analyze`
Expected: PASS

- [ ] **Step 5: Commit perubahan Task 4**

```bash
git add lib/ui/schedule_timeline.dart test/schedule_timeline_test.dart
git commit -m "feat(ui): implementasi CyberTimelineList dengan TransitRailTrack"
```

---

### Task 5: Integrasi Layar Utama Operasional (`_schedule` di `lib/ui/app.dart`)

**Files:**
- Modify: `lib/ui/app.dart`
- Test: `test/widget_test.dart`, `test/alarm_test.dart`

**Interfaces:**
- Menggabungkan: `FleetTelemetryPillBar`, `LiveCapsuleHero`, dan `CyberTimelineList` ke dalam tab layar jadwal aktif.

- [ ] **Step 1: Jalankan pengujian layar utama saat ini sebelum integrasi**

Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 2: Perbarui method `_schedule` di `lib/ui/app.dart`**

Gantikan layout lama dengan:
1. `FleetTelemetryPillBar` di bagian atas.
2. `LiveCapsuleHero` sebagai centerpiece keberangkatan.
3. `CyberTimelineList` untuk daftar ritase dan timeline armada di bawahnya.

- [ ] **Step 3: Jalankan seluruh test suite widget layar utama**

Run: `flutter test test/widget_test.dart test/alarm_test.dart && flutter analyze`
Expected: PASS dan No issues found!

- [ ] **Step 4: Commit perubahan Task 5**

```bash
git add lib/ui/app.dart
git commit -m "feat(ui): integrasikan Cyber-Transit HUD ke Layar Utama Jadwal"
```

---

### Task 6: Modernisasi Papan TV / Board Monitor (`lib/ui/board.dart`)

**Files:**
- Modify: `lib/ui/board.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Produces: `BoardScreen` dengan FIDS Matrix Board (Flight Information Style) dan banner hero keberangkatan jarak jauh.

- [ ] **Step 1: Perbarui layout `BoardScreen` di `lib/ui/board.dart`**

- Header TV Kiosk dengan jam digital detik besar.
- Hero Departure Banner berukuran besar untuk keterbacaan 3–5 meter.
- FIDS Matrix Table: kolom teratur `WAKTU` | `RUTE` | `UNIT` | `RITASE` | `STATUS`.
- Status badges: `BOARDING` (Amber), `BERSIAP` (Cyan), `STANDBY` (Silver), `SUDAH BERANGKAT` (Muted).

- [ ] **Step 2: Jalankan test widget dan analisis statis**

Run: `flutter test && flutter analyze`
Expected: PASS dan No issues found!

- [ ] **Step 3: Commit perubahan Task 6**

```bash
git add lib/ui/board.dart
git commit -m "feat(ui): modernisasi BoardScreen bergaya Papan TV FIDS"
```

---

### Task 7: Quality Gate & Verifikasi Penuh

- [ ] **Step 1: Jalankan `flutter analyze`**
- [ ] **Step 2: Jalankan `flutter test` (seluruh 53+ test harus PASS)**
- [ ] **Step 3: Jalankan `cd android && ./gradlew :app:testDebugUnitTest && cd ..`**
- [ ] **Step 4: Jalankan `pnpm run verify:legacy`**
- [ ] **Step 5: Verifikasi branch git tetap `devmode`**
