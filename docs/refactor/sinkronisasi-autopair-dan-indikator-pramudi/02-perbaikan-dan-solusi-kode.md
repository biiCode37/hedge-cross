# 02 Perbaikan dan Solusi Kode: Sinkronisasi Supabase, Auto-Pairing Pramudi, & Indikator Aktif TTS

**Tanggal:** 18 Oktober 2026  
**Branch:** `devmode`  
**Target Proyek Supabase:** `hedge-cross` (`mkffwfvaxuqifflpeaib`)  

---

## 1. Arsitektur Solusi Menyeluruh

```
┌───────────────────────────────────────────────────────────┐
│                    Aplikasi HEDGE                         │
├──────────────────────────┬────────────────────────────────┤
│ 1. DriverMasterSheet     │ 2. Fleet Tab (02 Armada)       │
│    - Input Pramudi       │    - Tombol "Pasangkan Bawaan" │
│    - Tombol "Sync Cloud" │    - Indikator "AKTIF" Dinamis │
│    - Auto-Pair Unit      │    - Sesuai shiftChangeTime    │
└────────────┬─────────────┴────────────────┬───────────────┘
             │                              │
             ▼                              ▼
┌──────────────────────────┐   ┌────────────────────────────┐
│   WorkspaceController    │   │     Local Repository       │
│ - addDriver (auto-assign)│──>│ - SQLite table 'units'     │
│ - autoPairDefaultDrivers │   │   driver_shift1_id (col)   │
│ - syncDriversToCloud     │   │   driver_shift2_id (col)   │
└────────────┬─────────────┘   └────────────────────────────┘
             │
             ▼
┌───────────────────────────────────────────────────────────┐
│              Supabase Cloud (hedge-cross)                 │
│ - RLS Table 'master_drivers' ALL untuk anon               │
│ - Upsert master_drivers relasi ke master_routes(uuid)     │
└───────────────────────────────────────────────────────────┘
```

---

## 2. Rincian Modifikasi Kode

### A. Supabase RLS & Cloud Sync Client
1. **Policy Supabase RLS (`master_drivers`):**
   ```sql
   ALTER TABLE master_drivers ENABLE ROW LEVEL SECURITY;
   DROP POLICY IF EXISTS "Allow all master_drivers for anon" ON master_drivers;
   CREATE POLICY "Allow all master_drivers for anon"
     ON master_drivers FOR ALL TO anon USING (true) WITH CHECK (true);
   ```
2. **`lib/data/sync_service.dart`:**
   - Menambahkan method `pushDrivers(String routeUuid, List<Driver> drivers)`.
   - Meng-upsert data ke tabel `master_drivers` berdasarkan `(route_uuid, call_name)` atau UUID driver.

### B. Otomatisasi Penugasan (Auto-Pairing) pada `WorkspaceController`
1. **`addDriver` & `updateDriver`:**
   - Memeriksa apakah driver memiliki `status == DriverStatus.tetap`, `defaultUnitNumber != null`, dan `defaultShift != null`.
   - Secara reaktif meng-update `route.units` sehingga `driverShift1Id` / `driverShift2Id` langsung terisi pada unit yang bersangkutan.
2. **Aksi Tombol "Pasangkan Bawaan" (Auto-Pair):**
   - Menghubungkan controller `autoPairDefaultDrivers(route)` ke tombol baru di tab 02 Armada.
   - Sekali klik, seluruh 67 supir yang telah diinput user langsung terpasang rapi ke unit KWK masing-masing.

### C. Persistensi Unit Shift ke SQLite Lokal (`LocalWorkspaceRepository`)
1. **`lib/data/workspace_repository.dart`:**
   - Menambahkan migrasi kolom di `beforeOpen`:
     ```sql
     ALTER TABLE units ADD COLUMN driver_shift1_id TEXT;
     ALTER TABLE units ADD COLUMN driver_shift2_id TEXT;
     ```
   - Menyimpan `unit.driverShift1Id` dan `unit.driverShift2Id` ke tabel `units` saat `save()`.
   - Me-load `driverShift1Id` dan `driverShift2Id` saat `load()`.

### D. Indikator Status Pramudi Aktif pada Kartu Armada
1. **Visualisasi Dual Shift:**
   - Membandingkan jam saat ini terhadap `route.config.shiftChangeTime` (misal 13:00).
   - **Pagi (< 13:00):** Chip `☀️ Pagi` diberi badge Cyan `AKTIF` dan border menyala terang. Chip `🌙 Siang` berstatus standby.
   - **Siang ($\ge$ 13:00):** Chip `🌙 Siang` diberi badge Amber `AKTIF` dan border menyala terang. Chip `☀️ Pagi` berstatus standby.
2. **Keterangan Jam Pergantian:**
   - Menampilkan banner/teks informatif: `Shift 1: <13:00 • Shift 2: ≥13:00` agar dispatcher tidak ragu supir mana yang akan dipanggil oleh TTS.

### E. Penanganan Layout Overflow Tab 04 Rute
1. Membungkus row kode rute dan badge status dengan `Expanded` / `Flexible` agar tidak terjadi RenderFlex overflow pada layar sempit 320px berukuran font besar.
