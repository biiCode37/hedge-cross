# Ergonomi Tampilan Rute, Truncation & Searchable Unit Dropdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Menata ulang ergonomi tampilan rute dan armada pada aplikasi HEDGE: menampilkan nama trayek rute hanya pada halaman "04 Rute" (dengan posisi multi-line di bawah kode rute), menyortir rute aktif di posisi teratas daftar rute, menyederhanakan pill rute top bar hanya memuat kode rute aktif, serta menyediakan komponen reusable Searchable Unit Dropdown untuk pengisian nomor unit armada.

**Architecture:**
- **Domain Layer (`lib/domain/models.dart`):** Menambahkan parser murni deterministik `splitRouteName` dan getter `code` serta `trajectory` pada `HedgeRoute`.
- **Top Bar (`lib/ui/app.dart`):** Menyaring rute hanya yang aktif (`participates == true`) dan merender label pill hanya `r.code`.
- **Halaman 04 Rute (`lib/ui/app.dart`):** Memisahkan baris kode rute dan nama trayek pada `CockpitManifestCard` (bebas truncation), serta mengurutkan rute aktif (`participates == true`) di urutan paling atas.
- **Header Halaman Lain (`lib/ui/driver_master_sheet.dart` dsb.):** Mengganti `currentRoute.name` menjadi `currentRoute.code` dan memperbaiki layout overflow pada baris pencarian & segmented filter.
- **Reusable Component (`lib/ui/components/searchable_unit_picker.dart`):** Komponen pemilih nomor unit dengan fitur search real-time dan dialog cyberpunk bertema HEDGE, diintegrasikan ke form Tambah/Edit Pramudi.

**Tech Stack:** Flutter (Dart), Flutter Test, Material 3, HEDGE Design System (Cyberpunk Obsidian `#070B12`, Cyan `#00E5FF`, Amber `#FF9800`).

## Global Constraints
- Bekerja secara eksklusif pada branch `devmode`.
- **DILARANG KERAS** melakukan build APK (`flutter build apk`, Gradle assemble, dsb.) tanpa perintah eksplisit pengguna.
- Perintah command line harus kompatibel dengan Git Bash / PowerShell.
- Dual Theme (Dark Mode Obsidian `#0C1017` vs Light Mode Silver `#F8FAFC`) wajib didukung penuh.
- Project ID Supabase: `mkffwfvaxuqifflpeaib`.

---

### Task 1: Domain Model Parser (`splitRouteName`), `HedgeRoute` Getters & Unit Tests

**Files:**
- Create: `test/domain/route_name_parser_test.dart`
- Modify: `lib/domain/models.dart:420-465`

**Interfaces:**
- Produces:
  - `typedef ParsedRouteName = ({String code, String trajectory});`
  - `ParsedRouteName splitRouteName(String raw)`
  - `HedgeRoute.code` -> `String`
  - `HedgeRoute.trajectory` -> `String`

- [ ] **Step 1: Tulis unit test untuk parser nama rute**

Buat file `test/domain/route_name_parser_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';

void main() {
  group('Route Name Parser Tests', () {
    test('Standard dash delimiter separates code and trajectory', () {
      final parsed = splitRouteName('JAK.01 - TANJUNG PRIOK - PLUMPANG');
      expect(parsed.code, 'JAK.01');
      expect(parsed.trajectory, 'TANJUNG PRIOK - PLUMPANG');
    });

    test('En-dash delimiter separates code and trajectory', () {
      final parsed = splitRouteName('JAK.115 – TERM.TANJUNG PRIOK - PEGANGSAAN DUA');
      expect(parsed.code, 'JAK.115');
      expect(parsed.trajectory, 'TERM.TANJUNG PRIOK - PEGANGSAAN DUA');
    });

    test('Suffix alphanumeric code (JAK.110A)', () {
      final parsed = splitRouteName('JAK.110A - RUSUN MARUNDA');
      expect(parsed.code, 'JAK.110A');
      expect(parsed.trajectory, 'RUSUN MARUNDA');
    });

    test('Single code without trajectory', () {
      final parsed = splitRouteName('JAK.88');
      expect(parsed.code, 'JAK.88');
      expect(parsed.trajectory, '');
    });

    test('HedgeRoute getters return expected code and trajectory', () {
      final route = HedgeRoute(
        id: 'r1',
        name: 'JAK.05 - SEMPER - RAWAMANGUN',
        color: 0xFF00E5FF,
        units: [],
        order: [],
      );
      expect(route.code, 'JAK.05');
      expect(route.trajectory, 'SEMPER - RAWAMANGUN');
    });
  });
}
```

- [ ] **Step 2: Jalankan test dan pastikan gagal (TDD Red)**
Perintah: `flutter test test/domain/route_name_parser_test.dart`

- [ ] **Step 3: Implementasikan fungsi `splitRouteName` dan getter `HedgeRoute` di `lib/domain/models.dart`**
Tambahkan di `lib/domain/models.dart`:
```dart
typedef ParsedRouteName = ({String code, String trajectory});

ParsedRouteName splitRouteName(String raw) {
  final trimmed = raw.trim();
  final match = RegExp(r'^([A-Za-z0-9_.]+)\s*[-–—:]\s*(.+)$').firstMatch(trimmed);
  if (match != null && match.group(1) != null && match.group(2) != null) {
    return (
      code: match.group(1)!.trim(),
      trajectory: match.group(2)!.trim(),
    );
  }
  return (code: trimmed, trajectory: '');
}
```
Dan pada `class HedgeRoute`:
```dart
  String get code => splitRouteName(name).code;
  String get trajectory => splitRouteName(name).trajectory;
```

- [ ] **Step 4: Jalankan test dan pastikan lulus (TDD Green)**
Perintah: `flutter test test/domain/route_name_parser_test.dart`

- [ ] **Step 5: Commit perubahan Task 1**
```bash
git add test/domain/route_name_parser_test.dart lib/domain/models.dart
git commit -m "feat(domain): add splitRouteName parser and route code getters"
```

---

### Task 2: Top Bar Route Pills Filtering & Code-Only Display

**Files:**
- Modify: `lib/ui/app.dart:515-570`

**Interfaces:**
- Consumes:
  - `HedgeRoute.code`
  - `HedgeRoute.participates`
  - `HedgeRoute.dirty`

- [ ] **Step 1: Filter rute aktif dan tampilkan kode rute saja pada Top Bar**
Pada `lib/ui/app.dart` di dalam widget top route pill list:
1. Filter rute yang dirender:
```dart
final activeRoutes = workspace.routes.where((r) => r.participates).toList();
```
2. Gunakan `activeRoutes` untuk `itemCount` dan item builder.
3. Ubah label `ChoiceChip` dari:
```dart
label: Text('${r.name}${r.dirty ? ' •' : ''}'),
```
Menjadi:
```dart
label: Text('${r.code}${r.dirty ? ' •' : ''}'),
```

- [ ] **Step 2: Jalankan flutter test untuk memastikan tidak ada regresi**
Perintah: `flutter test`

- [ ] **Step 3: Commit perubahan Task 2**
```bash
git add lib/ui/app.dart
git commit -m "feat(ui): display only active route codes in top bar pills"
```

---

### Task 3: Halaman "04 Rute" Revamp (Active Route Sorting & Multi-Line Layout)

**Files:**
- Modify: `lib/ui/app.dart:1850-1925`

**Interfaces:**
- Consumes:
  - `HedgeRoute.code`
  - `HedgeRoute.trajectory`
  - `HedgeRoute.participates`

- [ ] **Step 1: Urutkan rute pada Halaman 04 Rute agar rute aktif tampil paling atas**
Pada `lib/ui/app.dart` di builder tab rute:
```dart
final sortedRoutes = [...workspace.routes]..sort((a, b) {
  if (a.participates == b.participates) return 0;
  return a.participates ? -1 : 1;
});
```

- [ ] **Step 2: Restrukturisasi kartu rute menjadi multi-line (Kode di atas, Nama Trayek di bawah)**
Ubah `title` dan `subtitle` pada `CockpitManifestCard`:
```dart
title: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    Row(
      children: [
        Text(
          r.code,
          style: TextStyle(
            fontFamily: HedgeTokens.cyberFont,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.6,
            color: isDark ? Colors.white : p.text,
          ),
        ),
        const SizedBox(width: 8),
        CockpitStatusBadge(
          label: r.participates ? 'AKTIF' : 'NONAKTIF',
          isAmber: !r.participates,
        ),
      ],
    ),
    if (r.trajectory.isNotEmpty) ...[
      const SizedBox(height: 3),
      Text(
        r.trajectory,
        style: TextStyle(
          fontFamily: HedgeTokens.cyberFont,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          color: isDark ? const Color(0xFF94A3B8) : p.muted,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  ],
),
subtitle: Padding(
  padding: const EdgeInsets.only(top: 4),
  child: Text(
    '${r.activeUnits.length} unit · ${r.config.start}–${r.config.end}',
    style: TextStyle(
      fontFamily: HedgeTokens.cyberFont,
      fontSize: 11.5,
      color: isDark ? const Color(0xFF64748B) : p.muted,
    ),
  ),
),
```

- [ ] **Step 3: Jalankan analisis statis flutter**
Perintah: `flutter analyze`

- [ ] **Step 4: Commit perubahan Task 3**
```bash
git add lib/ui/app.dart
git commit -m "feat(ui): sort active routes first and use multi-line layout in route tab"
```

---

### Task 4: Standarisasi Kode Rute pada Master Pramudi & Perbaikan Filter Search Layout

**Files:**
- Modify: `lib/ui/driver_master_sheet.dart:80-181`

**Interfaces:**
- Consumes:
  - `HedgeRoute.code`

- [ ] **Step 1: Ubah nama rute di header Master Pramudi menjadi kode rute saja**
Di `lib/ui/driver_master_sheet.dart`:
Ganti `currentRoute.name` menjadi `currentRoute.code`. Tambahkan `Flexible` agar teks tidak pernah tumpang tindih dengan tombol tambah.

- [ ] **Step 2: Perbaiki responsive flex layout pada Search Bar & Segmented Button**
Atur layout baris filter pencarian agar search bar memiliki lebar yang cukup dan tidak terpotong (misal: beri layout terstruktur atau `Flexible` dengan ukuran minimum yang pas).

- [ ] **Step 3: Jalankan flutter test & analyze**
Perintah: `flutter test && flutter analyze`

- [ ] **Step 4: Commit perubahan Task 4**
```bash
git add lib/ui/driver_master_sheet.dart
git commit -m "fix(ui): use route code in master pramudi header and fix filter search layout"
```

---

### Task 5: Komponen Reusable `SearchableUnitPicker` & Integrasi Form Tambah Pramudi

**Files:**
- Create: `lib/ui/components/searchable_unit_picker.dart`
- Create: `test/ui/searchable_unit_picker_test.dart`
- Modify: `lib/ui/driver_master_sheet.dart:440-455`

**Interfaces:**
- Produces:
  - `class SearchableUnitPicker extends StatelessWidget`
    - `final String? selectedUnitNumber;`
    - `final List<FleetUnit> availableUnits;`
    - `final ValueChanged<String?> onUnitSelected;`
    - `final String labelText;`

- [ ] **Step 1: Buat widget unit test untuk `SearchableUnitPicker`**
Buat `test/ui/searchable_unit_picker_test.dart`.

- [ ] **Step 2: Implementasikan `SearchableUnitPicker` di `lib/ui/components/searchable_unit_picker.dart`**
Komponen menampilkan input selector yang jika diketuk akan membuka dialog / modal bottom sheet dengan:
- Kolom pencarian teks instan (menyaring nomor body & operator unit).
- Daftar unit armada dalam list bertema cyberpunk.
- Opsi "Tanpa Unit Bawaan" (Clear selection).

- [ ] **Step 3: Pasang `SearchableUnitPicker` pada dialog Tambah/Edit Pramudi di `driver_master_sheet.dart`**
Gantikan `TextField(controller: unitController, ...)` dengan `SearchableUnitPicker`.

- [ ] **Step 4: Jalankan test dan analisis statis**
Perintah: `flutter test test/ui/searchable_unit_picker_test.dart && flutter analyze`

- [ ] **Step 5: Commit perubahan Task 5**
```bash
git add lib/ui/components/searchable_unit_picker.dart test/ui/searchable_unit_picker_test.dart lib/ui/driver_master_sheet.dart
git commit -m "feat(ui): add SearchableUnitPicker and integrate into driver form"
```

---

### Task 6: Audit Komprehensif Seluruh Penggunaan Nomor Unit & Verifikasi Akhir

**Files:**
- Modify / Verify: `lib/ui/`
- Update: `docs/refactor/ui-ux-ergonomi-rute-dan-unit/03-verifikasi-dan-hasil-pengujian.md`

- [ ] **Step 1: Cari seluruh input nomor unit manual di seluruh halaman dan pastikan menggunakan picker**
- [ ] **Step 2: Jalankan full test suite dan flutter analyze**
Perintah: `flutter test && flutter analyze`
- [ ] **Step 3: Update progress ledger dan dokumen hasil pengujian**
- [ ] **Step 4: Commit perubahan akhir**
```bash
git add docs/ docs/refactor/ .superpowers/
git commit -m "docs: finalize verification and test results for route and unit UX refactor"
```
