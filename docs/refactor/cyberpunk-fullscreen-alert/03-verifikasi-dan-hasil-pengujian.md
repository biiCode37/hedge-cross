# 03. Verifikasi & Hasil Pengujian — Dialog Alert Fullscreen Keberangkatan

Dokumen ini memuat catatan eksekusi pengujian otomatis, analisis statis, kompilasi unit test Android native, dan verifikasi paket rilis APK untuk versi `v2.0.9+12`.

---

## 1. Analisis Statis Kode (Dart Analyze)

- **Perintah:**
  ```bash
  dart analyze
  ```
- **Hasil:**
  ```
  Analyzing HEDGE-FLUTTER...
  No issues found!
  ```
- **Status:** **PASS** (0 warning, 0 error, 0 linter hint).

---

## 2. Pengujian Suite Widget & Fungsional Flutter

- **Perintah:**
  ```bash
  flutter test
  ```
- **Hasil:**
  ```
  00:22 +71: All tests passed!
  ```
- **Rincian Khusus Pengujian Alert:**
  - `test/alarm_test.dart`: 10/10 test cases lulus, termasuk verifikasi layar mini 320x640 dengan pembesaran teks aksesibilitas 1.6x (`textScaleFactor: 1.6`) pada mode Dark dan Light tanpa overflow:
    - *Full alert small screen, enlarged text, stage transition and OFF dark* → **PASS**
    - *Full alert small screen, enlarged text, stage transition and OFF light* → **PASS**
    - *Alert timeout keeps feature enabled and does not record actual* → **PASS**
    - *Sudah Berangkat records actual and closes both prep and due* → **PASS**
    - *Configuration saves alarm controls without rebuilding schedule* → **PASS**

---

## 3. Pengujian Unit Test Android Native (Gradle)

- **Perintah:**
  ```bash
  ./gradlew :app:testDebugUnitTest
  ```
- **Hasil:**
  ```
  BUILD SUCCESSFUL in 2m 3s
  157 actionable tasks: 15 executed, 142 up-to-date
  ```
- **Status:** **PASS** (Kompilasi Kotlin dan eksekusi JVM unit test berhasil 100%).

---

## 4. Verifikasi Kompilasi & Struktur Folder APK Rilis

- **Perintah Kompilasi:**
  ```bash
  flutter build apk --release
  ```
- **Output Build:**
  - `build\app\outputs\flutter-apk\app-release.apk` (65.0 MB / 68,116,203 bytes).
- **Aturan Manajemen Folder APK:**
  - Folder tujuan khusus per versi: `apks/v2.0.9/`
  - Nama file APK: `apks/v2.0.9/hedge-v2.0.9.apk`
  - Jumlah file dalam folder: Tepat 1 file APK (tanpa tumpang tindih versi lain).
