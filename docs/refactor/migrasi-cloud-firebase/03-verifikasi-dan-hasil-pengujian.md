# 03. Verifikasi & Hasil Pengujian: Migrasi Cloud Firebase

**Tanggal:** 2026-11-09  
**Branch:** `devmode`  
**Topik:** Catatan Verifikasi Uji Koneksi Live, Static Analysis, Unit Testing, dan Build APK Release  

---

## 1. Uji Koneksi Live Server (End-to-End Latency Test)

Pengujian langsung dilakukan ke server Google Firebase project `hedge-mikrotrans` (Jakarta / `asia-southeast2`):

```text
=== 1. TESTING AUTHENTICATION CONNECTION ===
[OK] Firebase Auth SignIn: HTTP 200 (369 ms)

=== 2. TESTING FIRESTORE DATA ACCESS (AUTHENTICATED) ===
[OK] Dispatcher Whitelist Read: HTTP 200 (105 ms)
     User: biicode37@gmail.com | Name: BiiDev | Role: superadmin | Status: active
[OK] Route Master Read: HTTP 200 (146 ms)
     Route: JAK.115 — TERM.TANJUNG PRIOK - PEGANGSAAN II IGI
     Armada Unit Tersimpan: 30 unit
     Pramudi/Driver Tersimpan: 6 orang

[OK] Test cleanup completed.
>>> STATUS KONEKSI CLOUD: 100% TERHUBUNG, CEPAT & SEHAT! <<<
```

### Verifikasi Security Rules:
* Permintaan tanpa kredensial otentikasi: `HTTP 403 Forbidden` (Akses ditolak).
* Permintaan dengan token otentikasi Firebase: `HTTP 200 OK` (Akses diizinkan).

---

## 2. Analisis Statis Kode (`flutter analyze`)

Perintah:
```bash
flutter analyze
```
**Hasil:**
```text
Analyzing HEDGE-FLUTTER...
No issues found! (ran in 28.9s)
```
Target nol error dan nol warning terpenuhi sempurna.

---

## 3. Hasil Pengujian Unit & Widget Test (`flutter test`)

Perintah:
```bash
flutter test
```
**Hasil:**
```text
All tests passed! (142/142 tests passed)
```

Pengujian mencakup:
* Serialisasi dan parsing model `AuthorizedDispatcher` dari dokumen Firestore (`test/auth_models_test.dart`).
* Penggabungan rute dan format supir dari dokumen Cloud Firestore (`test/sync_service_test.dart`).
* Penanganan status login dan pending whitelist (`test/auth_gate_test.dart` & `test/login_screen_test.dart`).
* Pengujian jadwal, alarm headway, timeline cyber, dan stabilitas SQLite lokal.

---

## 4. Hasil Kompilasi APK Release v2.1.8

Perintah:
```bash
flutter build apk --release
```
**Hasil:**
```text
Running Gradle task 'assembleRelease'...
√ Built build\app\outputs\flutter-apk\app-release.apk (67.7MB)
```

Paket rilis resmi disalin ke folder khusus versi:
* **Lokasi Berkas:** [`apks/v2.1.8/hedge-v2.1.8.apk`](file:///d:/MINE/HEDGE-FLUTTER/apks/v2.1.8/hedge-v2.1.8.apk)
* **Ukuran Berkas:** 70.945.612 byte (~70.9 MB)
* **SHA-256 Hash:** `B1B84C0DFF3C55972A3A860C7E36664546801FC4A8400B1133D3B12641928863`
