# 01 Temuan Bug dan Permasalahan: Sinkronisasi Supabase, Auto-Pairing Pramudi, & Indikator Aktif TTS

**Tanggal:** 18 Oktober 2026  
**Branch:** `devmode`  
**Target Proyek Supabase:** `hedge-cross` (`mkffwfvaxuqifflpeaib`)  

---

## 1. Ringkasan Keluhan Dispatcher

1. **Database Supabase Kosong (`master_drivers`):**  
   Dispatcher telah menginput 67 pramudi (59 tetap, 8 cadangan) untuk rute `JAK.115` di aplikasi HP, namun tabel `master_drivers` di dashboard Supabase tetap kosong melompong (0 rows).
2. **Halaman "02 Armada" Tidak Terpasang Otomatis:**  
   Meskipun form tambah pramudi sudah menyertakan isian *Unit Default* (contoh: `KWK 222153`) dan *Default Shift* (Shift 1 / Shift 2), seluruh unit pada halaman 02 Armada masih menampilkan `Pagi: -` dan `Siang: -`. Dispatcher terpaksa memasangkan satu per satu secara manual.
3. **Kekhawatiran TTS Tertukar & Tiadanya Indikator Pramudi Aktif:**  
   Dispatcher cemas suara TTS akan salah memanggil antara pramudi pagi (Shift 1) dan pramudi siang (Shift 2). Belum ada visualisasi status pramudi aktif per unit pada jam operasional saat ini.

---

## 2. Analisis Akar Masalah (Root Cause Analysis)

### Root Cause 1: Tidak Ada Logika Push/Upsert ke Supabase & RLS Anon Read-Only
- **Data Flow Hilang:**  
  Di `DriverMasterSheet`, pemanggilan `addDriver` hanya memperbarui `route.drivers` di in-memory state Riverpod dan menyimpannya ke database SQLite lokal via `LocalWorkspaceRepository`.
- **Ketiadaan Fitur Push:**  
  Di `lib/data/sync_service.dart`, `SupabaseCloudSyncClient` hanya memiliki fungsi `pullRoutes()` yang melakukan SELECT, tanpa ada fungsi `pushDrivers()` atau `syncDriversToCloud()`.
- **Blokade RLS Supabase:**  
  Pemeriksaan `pg_policies` pada tabel `master_drivers` di Supabase `hedge-cross` (`mkffwfvaxuqifflpeaib`) menunjukkan bahwa peran `anon` hanya memiliki policy `SELECT`. Belum ada policy yang mengizinkan `INSERT` atau `UPDATE` bagi klien publik/anonim aplikasi.

### Root Cause 2: `addDriver` & `updateDriver` Tidak Memperbarui `route.units`
- Di `lib/application/workspace_controller.dart`, implementasi `addDriver` saat ini:
  ```dart
  Future<bool> addDriver(HedgeRoute route, Driver driver) {
    final updatedDrivers = [...route.drivers, driver];
    return updateRoute(route.copyWith(drivers: updatedDrivers));
  }
  ```
  Fungsi ini sama sekali tidak menyentuh `route.units`. Padahal penugasan pramudi pada unit tersimpan di properti `FleetUnit.driverShift1Id` dan `FleetUnit.driverShift2Id`.
- Fungsi `autoPairDefaultDrivers(HedgeRoute route)` sebenarnya telah tersedia di baris 299 `workspace_controller.dart`, namun **belum pernah dipanggil** otomatis saat pramudi ditambahkan/diperbarui, dan **tidak ada tombol aksi** di UI halaman "02 Armada" untuk menjalankannya.

### Root Cause 3: Persistence Lokal SQLite Menghilangkan Field Driver Shift Unit
- Di `lib/data/workspace_repository.dart`:
  Skema tabel `units` SQLite lokal hanya mencakup `(id, route_id, number, active, position)`.
- Saat `save()`, `driverShift1Id` dan `driverShift2Id` tidak ditulis ke tabel SQLite `units`.
- Saat `load()`, unit hanya direkonstruksi dari kolom `id`, `number`, dan `active`. Data pairing unit yang sudah dipasang hilang menjadi `null` saat aplikasi dimuat ulang dari SQLite.

### Root Cause 4: Kurangnya Indikator Visual Status Pramudi Aktif di Kartu Unit
- **Logika Backend Domain Sebenarnya Sudah Benar:**  
  Di `lib/domain/scheduler.dart`, jadwal keberangkatan (`Departure`) membandingkan menit keberangkatan dengan `shiftChangeTime` (default 13:00).
  - Keberangkatan sebelum 13:00 $\rightarrow$ mengambil `unit.driverShift1Id` (Pagi).
  - Keberangkatan $\ge$ 13:00 $\rightarrow$ mengambil `unit.driverShift2Id` (Siang).
  - TTS native Android membaca nama supir yang sesuai tanpa tertukar.
- **Masalah UX / UI:**  
  Di halaman "02 Armada", chip `☀️ Pagi: -` dan `🌙 Siang: -` ditampilkan statis berdampingan tanpa indikator siapa yang *sedang memegang kemudi saat jam sekarang*. Hal ini menimbulkan keraguan bagi dispatcher.
