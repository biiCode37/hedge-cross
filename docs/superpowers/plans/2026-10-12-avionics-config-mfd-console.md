# Avionics Config Cockpit MFD Console Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mentransformasi `ConfigurationSheet` (AVIONICS CONFIG) menjadi Cockpit MFD Console modular dengan navigasi 3 segmen taktis, Modern 24-Hour Time Picker tanpa ketik tanda titik dua manual, dan Digital Stepper numerik ramah jempol.

**Architecture:** Membagi form ke dalam 3 segmen MFD (`OPERASIONAL`, `PEAK HOURS`, `ALARM`), membungkus elemen ke dalam `CockpitFrame`, menggantikan input waktu teks mentah dengan `CockpitTimeTile` (pemicu `showTimePicker` bertema Cyber-Transit), serta mengontrol ritase, peak interval, dan detik alarm menggunakan `CockpitDigitalStepper`.

**Tech Stack:** Flutter, Dart, Riverpod, Material 3 TimePicker, HEDGE Design Tokens (Obsidian, Cyan, Amber).

## Global Constraints

- Wajib bekerja di branch `devmode`.
- DILARANG build APK kecuali diperintahkan eksplisit oleh user.
- Mengikuti standar dokumentasi investigasi & perbaikan di `docs/refactor/avionics-config-mfd-console/` (4 file inti).
- Seluruh test di `test/alarm_test.dart` dan seluruh repositori harus PASS.

---

### Task 1: Rancang Komponen Tactical `CockpitTimeTile` & `CockpitDigitalStepper`

**Files:**
- Modify: `lib/ui/configuration.dart`

**Interfaces:**
- Produces:
  - `CockpitTimeTile(label, timeString, onTimeChanged, accentColor, isDark)`
  - `CockpitDigitalStepper(label, value, min, max, step, unit, onChanged, isDark, accentColor)`
  - `CockpitMfdSegmentSelector(currentIndex, onSegmentChanged, isDark)`

- [ ] **Step 1: Implementasikan `CockpitTimeTile`**
  Menampilkan waktu terformat (misal `06:00 WIB`) dengan border chamfered/neon, yang saat diketuk membuka `showTimePicker` 24-jam bertema gelap/terang Cyber-Transit.

- [ ] **Step 2: Implementasikan `CockpitDigitalStepper`**
  Menampilkan label, tombol `[-]`, display angka monospaced beraksen neon dengan unit (misal `12 RITASE` atau `20 DETIK`), dan tombol `[+]`.

- [ ] **Step 3: Implementasikan `CockpitMfdSegmentSelector`**
  Tiga tab segmen taktis berukuran touch target 44px: `OPERASIONAL`, `PEAK HOURS`, dan `ALARM`.

---

### Task 2: Rekonstruksi `ConfigurationSheet` Menjadi 3 Segmen MFD

**Files:**
- Modify: `lib/ui/configuration.dart`

**Interfaces:**
- Produces: `ConfigurationSheet` yang responsif, modular, dan bebas dari pengetikan teks manual `:` untuk jam.

- [ ] **Step 1: Rakit Segmen 1 (OPERASIONAL)**
  Jam Mulai & Jam Selesai menggunakan `CockpitTimeTile`, Target Ritase menggunakan `CockpitDigitalStepper`, sakelar urutan headway.

- [ ] **Step 2: Rakit Segmen 2 (PEAK HOURS)**
  Sakelar periode peak, konfigurasi Peak 1 & Peak 2 (Jam mulai/selesai via `CockpitTimeTile`, interval menit via `CockpitDigitalStepper`).

- [ ] **Step 3: Rakit Segmen 3 (ALARM)**
  Sakelar Alarm Rute, format FullScreen vs Banner, pengingat persiapan + stepper detik, alarm saat waktu berangkat, timeout alert otomatis stepper, sakelar suara TTS dan getaran.

- [ ] **Step 4: Pertahankan tombol simpan & validasi jam selesai > mulai**
  Tombol `Simpan pengaturan` memvalidasi logika rute dan mengembalikan `HedgeRoute` yang diperbarui.

---

### Task 3: Penyelarasan Pengujian Widget & Modul Alarm

**Files:**
- Modify: `test/alarm_test.dart`

**Interfaces:**
- Consumes: `ConfigurationSheet`
- Produces: Test suite yang memverifikasi perubahan konfigurasi alarm dan input waktu baru.

- [ ] **Step 1: Sesuaikan test interaction di `test/alarm_test.dart`**
  Pastikan widget test `Configuration saves alarm controls without rebuilding schedule` menargetkan kontrol stepper/switch segmen baru secara tepat.

- [ ] **Step 2: Jalankan `flutter test test/alarm_test.dart`**
  Verifikasi semua test di `test/alarm_test.dart` lulus (10/10 PASS).

---

### Task 4: Verifikasi Menyeluruh & Dokumentasi Standar 4 File

**Files:**
- Create: `docs/refactor/avionics-config-mfd-console/01-temuan-bug-dan-permasalahan.md`
- Create: `docs/refactor/avionics-config-mfd-console/02-perbaikan-dan-solusi-kode.md`
- Create: `docs/refactor/avionics-config-mfd-console/03-verifikasi-dan-hasil-pengujian.md`
- Create: `docs/refactor/avionics-config-mfd-console/04-analogi-dan-dampak-non-teknis.md`

- [ ] **Step 1: Jalankan `flutter test` untuk seluruh repositori**
  Pastikan seluruh 75+ test kasus lulus tanpa regresi.

- [ ] **Step 2: Buat 4 berkas dokumentasi standar di `docs/refactor/avionics-config-mfd-console/`**

- [ ] **Step 3: Commit seluruh perubahan ke branch `devmode`**
