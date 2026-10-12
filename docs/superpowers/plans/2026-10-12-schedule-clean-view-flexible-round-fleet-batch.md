# Clean Schedule View, Fleksibilitas Ritase Awal & Multi-Select Armada Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menghapus date picker di header jadwal, menyediakan modal fleksibilitas ritase awal (*start round*), dan menambahkan fitur multi-select/batch actions armada.

**Architecture:** Memperluas `PlanConfig` dengan field `startRound` dan mengintegrasikannya ke `Scheduler.generate()` & `replan()`; mengeliminasi baris header date picker di `app.dart`; serta menambahkan batch operations pada `WorkspaceController` dan interaksi multi-select pada tab `_fleet()`.

**Tech Stack:** Flutter 3, Dart 3, Flutter Riverpod, Cyber-Transit Design Tokens (`HedgeTokens`).

## Global Constraints
- Wajib bekerja di branch `devmode`.
- DILARANG melakukan build APK kecuali ada instruksi eksplisit dari pengguna.
- Menjaga dukungan tema dual: Obsidian Dark (`#070B12`) dan Slate Light (`#F8FAFC`).
- Touch target minimal 44-48px (thumb-first).

---

### Task 1: Domain & Controller Support untuk `startRound` dan Batch Fleet

**Files:**
- Modify: `lib/domain/models.dart`
- Modify: `lib/domain/scheduler.dart`
- Modify: `lib/application/workspace_controller.dart`
- Test: `test/scheduler_test.dart`
- Test: `test/repository_test.dart`

**Steps:**
- [ ] **Step 1: Update `PlanConfig` di `lib/domain/models.dart`**
  - Tambahkan `startRound: int` (default `1`).
  - Tambahkan serialisasi dan deserialisasi JSON.
  - Tambahkan method `copyWith()`.
- [ ] **Step 2: Update `Scheduler.generate()` & `Scheduler.replan()` di `lib/domain/scheduler.dart`**
  - Pada `generate()`: `round: route.config.startRound + (i ~/ units.length)`.
  - Pada `replan()`: `queue.add((unit: u, round: (route.config.startRound - 1) + completed + pass))`.
- [ ] **Step 3: Tambahkan method batch di `lib/application/workspace_controller.dart`**
  - `setUnitsActive(HedgeRoute route, Set<String> unitIds, bool active)`.
  - `deleteUnits(HedgeRoute route, Set<String> unitIds)`.
- [ ] **Step 4: Update unit test di `test/scheduler_test.dart` & jalankan**
  - Tambahkan test case untuk verifikasi ritase mulai dari `startRound` kustom.
- [ ] **Step 5: Commit perubahan Task 1**

---

### Task 2: UI Halaman Jadwal — Eliminasi Date Picker & Modal Generate dengan Ritase Awal

**Files:**
- Modify: `lib/ui/app.dart`
- Test: `test/widget_test.dart`

**Steps:**
- [ ] **Step 1: Hapus baris Date Picker di `lib/ui/app.dart`**
  - Hapus `Padding` berisi `TextButton.icon(onPressed: () => _date(workspace)...)` dan teks `Lokal`.
  - Hapus method pembantu `_date(Workspace workspace)`.
- [ ] **Step 2: Buat Modal Konfirmasi Generate Jadwal dengan Stepper Ritase**
  - Ubah fungsi `generate(HedgeRoute route, {bool replan = false})`:
    - Jika bukan replan, tampilkan dialog konfirmasi bertema Cyber-Transit dengan stepper `[-] [ startRound ] [+]` (min: 1, max: 99).
    - Saat dikonfirmasi, simpan `startRound` ke `route.config` lalu jalankan `controller.generate(route)`.
- [ ] **Step 3: Verifikasi Widget Test & Jalankan**
- [ ] **Step 4: Commit perubahan Task 2**

---

### Task 3: UI Halaman 02 Armada — Multi-Select, Select All & Batch Actions

**Files:**
- Modify: `lib/ui/cockpit_components.dart` (jika diperlukan checkbox pada `CockpitManifestCard`)
- Modify: `lib/ui/app.dart` (`_fleet(route)`)
- Test: `test/design_system_test.dart` / `test/widget_test.dart`

**Steps:**
- [ ] **Step 1: Tambahkan Checkbox Seleksi pada `CockpitManifestCard` di `lib/ui/cockpit_components.dart`**
  - Parameter opsional: `isSelected: bool`, `onSelectChanged: ValueChanged<bool?>?`.
- [ ] **Step 2: Implementasi State Multi-Select & Baris Aksi Massal di `_fleet()` pada `lib/ui/app.dart`**
  - State: `Set<String> selectedUnitIds = {}`.
  - Tombol **"Pilih Semua"** / **"Batal Pilih"** di header manifest.
  - **Batch Action Bar** saat `selectedUnitIds.isNotEmpty`:
    - Label `${selectedUnitIds.length} unit terpilih`.
    - Tombol `[Aktifkan]` -> `controller.setUnitsActive(route, selectedUnitIds, true)`.
    - Tombol `[Nonaktifkan]` -> `controller.setUnitsActive(route, selectedUnitIds, false)`.
    - Tombol `[Hapus]` -> Dialog konfirmasi `confirm()` -> `controller.deleteUnits(route, selectedUnitIds)`.
- [ ] **Step 3: Uji interaksi multi-select dan batch actions**
- [ ] **Step 4: Commit perubahan Task 3**

---

### Task 4: Verifikasi Menyeluruh, Dokumentasi Refactor & Laporan

**Files:**
- Create: `docs/refactor/clean-schedule-start-round-fleet-batch/01-temuan-bug-dan-permasalahan.md`
- Create: `docs/refactor/clean-schedule-start-round-fleet-batch/02-perbaikan-dan-solusi-kode.md`
- Create: `docs/refactor/clean-schedule-start-round-fleet-batch/03-verifikasi-dan-hasil-pengujian.md`
- Create: `docs/refactor/clean-schedule-start-round-fleet-batch/04-analogi-dan-dampak-non-teknis.md`

**Steps:**
- [ ] **Step 1: Jalankan `flutter test` (seluruh suite)**
- [ ] **Step 2: Jalankan `flutter analyze`**
- [ ] **Step 3: Tulis 4 dokumen standar refactor AGENTS.md**
- [ ] **Step 4: Commit dokumentasi ke branch `devmode`**
- [ ] **Step 5: Laporkan ringkasan perubahan sesuai format standar**
