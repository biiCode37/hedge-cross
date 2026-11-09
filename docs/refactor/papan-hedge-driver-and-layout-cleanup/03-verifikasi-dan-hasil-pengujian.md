# Verifikasi dan Hasil Pengujian

## 1. Lingkungan dan Target Verifikasi
- **Branch Git:** `devmode`
- **Modul Pengujian:**
  - `test/board_screen_test.dart` (Pengujian Papan HEDGE & Linimasa FIDS Kiosk)
  - `test/dispatch_components_test.dart` (Pengujian DepartureFocusPanel)
  - Seluruh test suite Flutter (`flutter test`)
  - Analisis statis (`flutter analyze`)

---

## 2. Hasil Pengujian Unit & Widget Test Khusus

### A. Pengujian `test/board_screen_test.dart`
```text
00:00 +0: loading test/board_screen_test.dart
00:00 +0: CyberBoardTimelineTile renders unit, route, round, and countdown
00:01 +1: CyberBoardTimelineTile adapts status between STANDBY, BERSIAP, and BOARDING
00:01 +2: CyberBoardTimelineTile displays driver name replacing STANDBY when driver assigned
00:01 +3: CyberBoardTimelineTile renders on 320px narrow screen without overflow (dark)
00:01 +4: CyberBoardTimelineTile renders on 320px narrow screen without overflow (light)
00:01 +5: All tests passed!
```
- **Status:** **5/5 LULUS (100% Passed)**.
- Verifikasi membuktikan label `STANDBY` berhasil digantikan oleh nama Pramudi ketika driver telah ditugaskan, dan tetap kompatibel di layar sempit 320px tanpa overflow pada tema Dark maupun Light.

### B. Pengujian `test/dispatch_components_test.dart`
```text
00:00 +0: loading test/dispatch_components_test.dart
00:00 +0: DepartureFocusPanel renders Live Capsule HUD elements and button
00:01 +1: DepartureFocusPanel shows WAKTU BERANGKAT on due status
00:01 +2: DepartureFocusPanel renders driver name when driverName is present
00:01 +3: showDepartureUndoSnackBar renders themed content, close button, and undo button
00:01 +4: All tests passed!
```
- **Status:** **4/4 LULUS (100% Passed)**.
- Verifikasi membuktikan nama pramudi tampil presisi di antara nomor unit dan countdown gauge.

---

## 3. Hasil Pengujian Seluruh Suite Flutter

Perintah:
```bash
flutter test
```
Hasil:
```text
00:00 +0: loading test/alarm_permissions_test.dart
...
00:44 +145: All tests passed!
```
- **Total Test:** 145 test cases
- **Status:** **145 PASSED, 0 FAILED (100% LULUS)**.
- Tidak ada regresi logika atau kerusakan antarmuka pada komponen lainnya.

---

## 4. Hasil Analisis Statis (Flutter Analyze)

Perintah:
```bash
flutter analyze
```
Hasil:
```text
Analyzing HEDGE-FLUTTER...
No issues found! (ran in 216.3s)
```
- **Status:** **0 error, 0 warning (CLEAN)**.
