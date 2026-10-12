# Unifikasi Fullscreen Alarm Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghilangkan redundansi dengan menjadikan `ForegroundAlarmOverlay` (Flutter) sebagai satu-satunya komponen alert layar penuh, serta menghapus total komponen native Android (`AlarmSurface.kt`, `AlarmOverlay.kt`, dan `AlarmActivity.kt`).

**Architecture:** Bawa `MainActivity` (Flutter) langsung ke latar depan saat alarm berdering di kondisi background atau layar terkunci memanfaatkan izin `SYSTEM_ALERT_WINDOW`, `showWhenLocked`, dan `turnScreenOn`. Dengan demikian, antarmuka Flutter `ForegroundAlarmOverlay` selalu tampil secara tunggal dan seragam tanpa duplikasi canvas native.

**Tech Stack:** Flutter, Dart, Riverpod, Kotlin, Android Jetpack, NotificationManager, WindowManager.

## Global Constraints

- Wajib bekerja di branch `devmode`.
- DILARANG build APK kecuali diperintahkan eksplisit oleh user.
- Mengikuti standar dokumentasi investigasi & perbaikan di `docs/refactor/unifikasi-fullscreen-alert/` (4 file inti).
- Semua test di `test/alarm_test.dart` harus tetap PASS.

---

### Task 1: Hapus Komponen Visual Redundan Native Android

**Files:**
- Delete: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt`
- Delete: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt`
- Delete: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt`
- Modify: `android/app/src/main/AndroidManifest.xml:31-35`

**Interfaces:**
- Consumes: `AndroidManifest.xml`
- Produces: Proyek Android bebas dari deklarasi `AlarmActivity` dan file canvas native duplikat.

- [ ] **Step 1: Hapus berkas native Android duplikat**
  Hapus `AlarmSurface.kt`, `AlarmOverlay.kt`, dan `AlarmActivity.kt`.

- [ ] **Step 2: Bersihkan deklarasi `AlarmActivity` di AndroidManifest.xml**
  Hapus elemen activity `.AlarmActivity` dari `AndroidManifest.xml`.

- [ ] **Step 3: Commit perubahan Task 1**
  ```bash
  git add android/app/src/main/AndroidManifest.xml
  git rm android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt
  git rm android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt
  git rm android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt
  git commit -m "refactor(android): remove redundant AlarmSurface, AlarmOverlay, and AlarmActivity"
  ```

---

### Task 2: Konfigurasi `MainActivity` untuk Lock Screen & Bring-to-Front

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt`

**Interfaces:**
- Consumes: `MainActivity.kt`
- Produces: `MainActivity` yang siap menyalakan layar, tampil saat lockscreen, dan menerima intent alarm tanpa restart.

- [ ] **Step 1: Perbarui atribut `MainActivity` di `AndroidManifest.xml`**
  Tambahkan `android:showWhenLocked="true"` dan `android:turnScreenOn="true"` pada deklarasi `.MainActivity`.

- [ ] **Step 2: Tambahkan window flags dan `onNewIntent` pada `MainActivity.kt`**
  Di `onCreate()`: tambahkan `setShowWhenLocked(true)`, `setTurnScreenOn(true)`, dan `FLAG_KEEP_SCREEN_ON`.
  Tambahkan `override fun onNewIntent(intent: Intent)`.

- [ ] **Step 3: Commit perubahan Task 2**
  ```bash
  git add android/app/src/main/AndroidManifest.xml android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt
  git commit -m "feat(android): enable showWhenLocked and turnScreenOn for MainActivity"
  ```

---

### Task 3: Perbarui `AlarmEngine.kt` untuk Meluncurkan `MainActivity`

**Files:**
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt`

**Interfaces:**
- Consumes: `MainActivity::class.java`
- Produces: `AlarmEngine.activityIntent()` yang selalu membuka `MainActivity` dan helper `AlarmEngine.launchApp()`.

- [ ] **Step 1: Modifikasi `activityIntent` agar selalu mengarah ke `MainActivity`**
  Ubah target intent dari `AlarmActivity` ke `MainActivity` dengan flags `FLAG_ACTIVITY_NEW_TASK or FLAG_ACTIVITY_CLEAR_TOP or FLAG_ACTIVITY_SINGLE_TOP`.

- [ ] **Step 2: Tambahkan helper `launchApp(context: Context, key: String? = null)`**
  Implementasikan pemanggilan `startActivity(MainActivity)` aman yang memanfaatkan izin overlay/background activity start.

- [ ] **Step 3: Commit perubahan Task 3**
  ```bash
  git add android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt
  git commit -m "refactor(android): redirect alarm intents and add launchApp for MainActivity"
  ```

---

### Task 4: Perbarui `AlarmDeliveryService.kt` Tanpa Native Overlay

**Files:**
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt`

**Interfaces:**
- Consumes: `AlarmEngine.launchApp()`
- Produces: `AlarmDeliveryService` ramping tanpa `AlarmOverlay` yang mengaktifkan `MainActivity` saat alarm fullscreen aktif.

- [ ] **Step 1: Hapus dependensi `overlay: AlarmOverlay` dari `AlarmDeliveryService`**
  Hapus deklarasi `private lateinit var overlay: AlarmOverlay` dan lifecycle `overlay.close()`.

- [ ] **Step 2: Integrasikan `AlarmEngine.launchApp()` pada `refresh()`**
  Saat alarm `fullScreen` aktif dan `MainActivity.foreground?.get() == null`, panggil `AlarmEngine.launchApp(this, key)`.

- [ ] **Step 3: Commit perubahan Task 4**
  ```bash
  git add android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt
  git commit -m "refactor(android): remove AlarmOverlay from AlarmDeliveryService and trigger MainActivity"
  ```

---

### Task 5: Verifikasi Suite Pengujian & Pembuatan Dokumentasi Investigasi

**Files:**
- Create: `docs/refactor/unifikasi-fullscreen-alert/01-temuan-bug-dan-permasalahan.md`
- Create: `docs/refactor/unifikasi-fullscreen-alert/02-perbaikan-dan-solusi-kode.md`
- Create: `docs/refactor/unifikasi-fullscreen-alert/03-verifikasi-dan-hasil-pengujian.md`
- Create: `docs/refactor/unifikasi-fullscreen-alert/04-analogi-dan-dampak-non-teknis.md`

**Interfaces:**
- Consumes: Seluruh test suite `test/alarm_test.dart`
- Produces: Laporan lengkap 4 file dokumentasi investigasi & refactor HEDGE.

- [ ] **Step 1: Jalankan `flutter test test/alarm_test.dart`**
  Verifikasi semua pengujian tetap PASS (10/10).

- [ ] **Step 2: Buat 4 berkas dokumentasi di `docs/refactor/unifikasi-fullscreen-alert/`**
  Tulis analisis mendalam sesuai standar AGENTS.md: temuan redundansi, arsitektur solusi, bukti verifikasi pengujian, dan analogi dampak non-teknis.

- [ ] **Step 3: Commit perubahan Task 5**
  ```bash
  git add docs/refactor/unifikasi-fullscreen-alert/
  git commit -m "docs: add 4 comprehensive refactor documentation files for unified fullscreen alert"
  ```
