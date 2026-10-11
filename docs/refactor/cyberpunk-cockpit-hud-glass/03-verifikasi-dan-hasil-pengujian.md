# 03 — Verifikasi & Hasil Pengujian: Cyberpunk Cockpit HUD Glass

## 1. Perintah Analisis Statis
```bash
dart analyze lib test
```
**Hasil:**
```
Analyzing lib, test...
No issues found!
```
Semua file Dart bebas dari issue linter, deprecated API (misal `activeColor` diperbarui menjadi `activeThumbColor` / `activeTrackColor`), dan compiler warning.

---

## 2. Pengujian Unit & Widget Otomatis
```bash
flutter test
```
**Hasil:**
```
00:27 +74: D:/MINE/HEDGE-FLUTTER/test/widget_test.dart: Dispatcher 1200.0 light: fleet edits preserve committed schedule
00:28 +75: All tests passed!
```
**100% dari 75 test suite lulus sempurna tanpa kegagalan.**

---

## 3. Rincian Pengujian Kasus Ekstrem & Edge Cases

### A. Pengujian Resolusi Sempit 320px & Text Scale 1.6x (`test/design_system_test.dart`)
- **Kasus:** Layar ponsel sangat kecil (320px) dengan aksesibilitas pembesaran huruf maksimal (1.6x).
- **Pengujian:** Berpindah antar tab Jadwal -> Armada -> Urutan -> Rute -> Papan Keberangkatan.
- **Hasil:** Semua `expect(tester.takeException(), isNull)` lulus, zero `RenderFlex` overflow (baik horizontal maupun vertikal).

### B. Pengujian Dual-Theme & Reaktivitas Switch (`test/widget_test.dart`)
- **Resolusi:** 360px & 1200px.
- **Tema:** Obsidian Dark Mode & Polar Slate Light Mode.
- **Pengujian:**
  - Navigasi ke tab Armada.
  - Interaksi `Switch` untuk mengaktifkan/menonaktifkan unit armada.
  - Verifikasi perubahan jumlah unit aktif (`activeUnits.length` dari 39 menjadi 38).
  - Verifikasi jadwal bertanda `dirty`.
  - Navigasi kembali ke tab Jadwal dan memastikan banner peringatan jadwal dirty tampil.
- **Hasil:** Seluruh 4 matriks skenario (360 dark, 360 light, 1200 dark, 1200 light) lulus sempurna.

### C. Pengujian Isolasi Jam Digital & Performa Rebuild
- **Pengujian:** `AvionicsTopBar` dan `CyberBoardTimelineTile` mengisolasi langganan `clockProvider` via widget `Consumer` lokal.
- **Hasil:** Frame rate stabil, tidak terjadi cascading rebuild pada kontainer utama `HomeScreen` saat jam berdetak setiap detik.

---

## 4. Kompilasi Release APK (`v2.1.0`)
```bash
flutter build apk --release
```
**Hasil:**
```
√ Built build\app\outputs\flutter-apk\app-release.apk (64.7MB)
```
- **File Output:** `apks/v2.1.0/hedge-v2.1.0.apk` (Ukuran: 64.7 MB / 67,821,407 bytes)
- **Kepatuhan Aturan Output APK:** Sesuai standar `AGENTS.md`, folder `apks/v2.1.0/` hanya memuat tepat 1 file APK rilis versi 2.1.0.

