# Spesifikasi Desain: Master Data Pramudi, Penugasan Shift Armada & Integrasi Panggilan TTS Cerdas

- **Tanggal:** 2026-10-18
- **Topik:** Master Data Pramudi Rute, Slot Penugasan Shift 1 & 2 per Unit, Waktu Aplusan per Rute, dan Pelafalan Nama Pramudi via TTS
- **Status:** Approved by User

---

## 1. Latar Belakang & Kebutuhan Pengguna

Pada operasional harian angkutan umum Mikrotrans / JakLingko di Jakarta Utara, dispatcher pos pantau memiliki kebutuhan operasional yang fundamental:
1. **Panggilan Operasional Berbasis Nama Supir:** Di pangkalan / shelter, dispatcher jauh lebih sering memanggil atau berkoordinasi langsung dengan menyebut nama **Pramudi** (baik via pengeras suara shelter maupun HT), bukan sekadar nomor bodi mobil.
2. **Karakteristik Penugasan Lapangan:**
   - Setiap pramudi terikat pada **1 rute tetap** sebagai homebase mereka.
   - Terdapat 2 kategori status pramudi:
     - **Tetap:** Terikat pada 1 unit bodi mobil tertentu sebagai unit bawaannya.
     - **Cadangan / Backup:** Tidak terikat pada mobil tertentu, tetapi terikat pada rute tersebut untuk siap menggantikan supir tetap yang izin/sakit.
   - Pembeda Nama: Terdapat nama lengkap resmi (untuk catatan administrasi manifes) dan nama panggilan ringkas (untuk dilafalkan cepat oleh TTS dan radio).
3. **Dua Shift per Unit (Pagi & Siang):** Setiap armada dioperasikan bergantian oleh 2 pramudi: Shift 1 (Pagi) dan Shift 2 (Siang).
4. **Waktu Aplusan Bervariasi per Rute:** Jam pergantian shift (waktu aplusan) berbeda-beda untuk tiap rute (misal: ada rute yang aplusan jam 13:00, ada yang jam 13:30 atau 14:00).
5. **Rotasi Berkala (Rolling Shift):** Pramudi secara berkala mengalami perputaran jadwal (misal 1–2 minggu bertugas shift pagi, periode berikutnya bertugas shift siang).
6. **Pembersihan UI Halaman 02 Armada:** Menghilangkan teks redundan *"Aktif untuk jadwal baru"* pada kartu armada agar ruang kartu lebih padat, bersih, dan memuat slot supir tandem.

---

## 2. Arsitektur Data & Model Domain

### A. Model Entitas Pramudi (`Driver`)
Dibuat di [lib/domain/models.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart):
```dart
enum DriverStatus { tetap, cadangan }

class Driver {
  const Driver({
    required this.id,
    required this.routeId,
    required this.fullName,
    required this.callName,
    this.status = DriverStatus.tetap,
    this.defaultUnitNumber,
    this.defaultShift,
    this.active = true,
  });

  final String id;
  final String routeId;
  final String fullName;       // Contoh: "Bambang Hariyanto"
  final String callName;       // Contoh: "Bambang" (dipanggil TTS)
  final DriverStatus status;   // DriverStatus.tetap / DriverStatus.cadangan
  final String? defaultUnitNumber; // Nomor bodi mobil tetap, misal: "540"
  final int? defaultShift;     // 1 = Pagi, 2 = Siang
  final bool active;

  Map<String, dynamic> toJson() => {
    'id': id,
    'routeId': routeId,
    'fullName': fullName,
    'callName': callName,
    'status': status.name,
    'defaultUnitNumber': defaultUnitNumber,
    'defaultShift': defaultShift,
    'active': active,
  };

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json['id'] as String,
    routeId: json['routeId'] as String,
    fullName: json['fullName'] as String,
    callName: json['callName'] as String,
    status: json['status'] == 'cadangan' ? DriverStatus.cadangan : DriverStatus.tetap,
    defaultUnitNumber: json['defaultUnitNumber'] as String?,
    defaultShift: json['defaultShift'] as int?,
    active: json['active'] as bool? ?? true,
  );
}
```

### B. Slot Penugasan Supir di Unit Armada (`FleetUnit`)
Unit armada kini memegang referensi supir yang bertugas pada hari operasional tersebut:
```dart
class FleetUnit {
  const FleetUnit({
    required this.id,
    required this.number,
    this.active = true,
    this.driverShift1Id,
    this.driverShift2Id,
  });

  final String id;
  final String number;
  final bool active;
  final String? driverShift1Id; // ID Pramudi Shift 1 (Pagi)
  final String? driverShift2Id; // ID Pramudi Shift 2 (Siang)

  FleetUnit copyWith({
    bool? active,
    String? driverShift1Id,
    String? driverShift2Id,
    bool clearShift1 = false,
    bool clearShift2 = false,
  }) => FleetUnit(
    id: id,
    number: number,
    active: active ?? this.active,
    driverShift1Id: clearShift1 ? null : driverShift1Id ?? this.driverShift1Id,
    driverShift2Id: clearShift2 ? null : driverShift2Id ?? this.driverShift2Id,
  );
}
```

### C. Waktu Aplusan di Konfigurasi Rute (`PlanConfig`)
Tersimpan di dalam kolom JSONB `config` pada tabel Supabase `master_routes`:
```dart
class PlanConfig {
  const PlanConfig({
    this.start = '05:00',
    this.end = '22:00',
    this.shiftChangeTime = '13:00', // Default jam aplusan rute
    this.rounds = 8,
    this.startRound = 1,
    this.slowFirst = false,
    this.peakEnabled = false,
    this.peaks = const [...],
  });

  final String shiftChangeTime; // Format HH:mm
}
```

### D. Penugasan Otomatis ke Jadwal Keberangkatan (`Departure` & `AlarmEvent`)
Saat `Scheduler.generate()` atau `replan()` menghitung baris jadwal:
```dart
// Evaluasi jam menit keberangkatan terhadap waktu aplusan rute
final shiftCutoffMinute = parseMinute(route.config.shiftChangeTime);
final isMorningShift = departureMinute < shiftCutoffMinute;
final assignedDriverId = isMorningShift ? unit.driverShift1Id : unit.driverShift2Id;
final assignedDriver = driversById[assignedDriverId];

// Set field driverName pada Departure
final departure = Departure(
  ...
  driverName: assignedDriver?.callName ?? '',
);
```
Data `driverName` juga diteruskan langsung ke `AlarmEvent` $\rightarrow$ payload native Android `AlarmSpec`.

### E. Struktur Tabel Supabase Cloud (`hedge-cross`)
1. **Tabel `master_routes`:**
   - Menggunakan kolom JSONB `config` yang sudah ada untuk menyimpan `shiftChangeTime` (tanpa perlu modifikasi DDL / `ALTER TABLE`).
2. **Tabel Baru `master_drivers`:**
   ```sql
   CREATE TABLE IF NOT EXISTS master_drivers (
       id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
       uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
       route_uuid UUID NOT NULL REFERENCES master_routes(uuid) ON DELETE CASCADE,
       full_name TEXT NOT NULL,
       call_name TEXT NOT NULL,
       status TEXT NOT NULL DEFAULT 'tetap',
       default_unit_number TEXT,
       default_shift INT,
       active BOOLEAN DEFAULT true,
       created_at TIMESTAMPTZ DEFAULT NOW(),
       updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```

---

## 3. Desain Antarmuka Pengguna (UI/UX)

### A. Header Halaman 02 Armada
Di samping kolom pencarian dan tombol tambah unit (`+`):
1. **Tombol "Kelola Pramudi":**
   - Ikon `Icons.badge_outlined` / `Icons.person_pin_outlined`.
   - Tooltip: *"Kelola Master Pramudi Rute"*.
   - Membuka BottomSheet `DriverMasterSheet`.
2. **Tombol "Rolling Shift Rute" (Ikon `Icons.sync_alt_rounded`):**
   - Menampilkan dialog konfirmasi: *"Rotasi/Rolling Shift Semua Armada?"*.
   - Saat dikonfirmasi, seluruh unit aktif pada rute ini menukar posisi: `driverShift1Id` $\leftrightarrow$ `driverShift2Id` dalam satu langkah instan.

### B. Tampilan Kartu Armada di Halaman 02 (`CockpitManifestCard`)
- **Pembersihan Teks Redundan:** Teks `"Aktif untuk jadwal baru"` **dihapus sepenuhnya**.
- **Baris Slot Supir Tandem:**
  ```
  ┌─────────────────────────────────────────────────────────────┐
  │ [ 1 ]  KLM                                    [Aktif Switch]│
  │        540                                                  │
  │                                                             │
  │        [☀️ Pagi: Bambang]  [ ⇄ ]  [🌙 Siang: Rudi]          │
  └─────────────────────────────────────────────────────────────┘
  ```
- **Slot Shift 1 (Pagi `☀️`):** Menampilkan nama panggilan supir pagi. Jika belum ada supir, menampilkan `[+ Supir Pagi]`.
- **Tombol Swap Per-Unit (`[ ⇄ ]`):** Menukar posisi supir pagi dan siang khusus pada unit tersebut jika terjadi tukaran shift harian.
- **Slot Shift 2 (Siang `🌙`):** Menampilkan nama panggilan supir siang. Jika belum ada supir, menampilkan `[+ Supir Siang]`.
- **Ketuk Slot Supir:** Membuka pop-up pemilih supir cepat (menampilkan supir tetap, supir cadangan yang tersedia, atau opsi *"Kosongkan"*).

### C. BottomSheet Master Pramudi (`DriverMasterSheet`)
- Tampilan modal ergonomis satu jempol.
- Filter chips: `Semua` | `Tetap` | `Cadangan`.
- Tombol aksi: `+ Tambah Pramudi`.
- Form Tambah/Edit Pramudi:
  - Input: *Nama Lengkap* (misal: "Bambang Hariyanto").
  - Input: *Nama Panggilan / TTS* (misal: "Bambang").
  - Radio/Pilihan: `Tetap` vs `Cadangan`.
  - Jika Tetap: Input *Nomor Bodi Mobil Bawaan* & Dropdown *Shift Bawaan (Shift 1 / Shift 2)*.

### D. Tampilan Papan Jadwal & Fullscreen Alarm Overlay
- **Papan Jadwal (Board & Timeline):**
  Menampilkan tag mikro supir yang bertugas di baris jadwal: `👤 Bambang`.
- **Fullscreen Alarm Overlay (HUD Saat Alarm Berbunyi):**
  Di bawah nomor unit besar (misal `540`), ditampilkan label identitas menyala:
  `PRAMUDI: BAMBANG` (atau hening/kosong jika unit tidak memiliki supir bertugas).

---

## 4. Integrasi Suara TTS Cerdas

### A. Tag Variabel `{pramudi}`
Template suara default di [lib/domain/models.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/models.dart) diperbarui:
- **Tahap Persiapan (*Prep*):**
  `"{rute} unit {unit}, {pramudi}, {detik} detik lagi."`
  *(Pelafalan: "JAK 115 unit 540, Bambang, 10 detik lagi.")*
- **Tahap Waktu Berangkat (*Due*):**
  `"{rute} unit {unit}, {pramudi}, saatnya berangkat."`
  *(Pelafalan: "JAK 115 unit 540, Bambang, saatnya berangkat.")*

Di halaman [lib/ui/configuration.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart), ditambahkan chip cepat: **`+ {pramudi}`**.

### B. Logika Kotlin Android ([AlarmSpeechText.kt](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt))
```kotlin
val driverSpoken = event.driverName.trim()

var result = chosenTmpl
result = result
    .replace("{unit}", unitSpoken, ignoreCase = true)
    .replace("{pramudi}", driverSpoken, ignoreCase = true)
    .replace("{detik}", secondsSpoken, ignoreCase = true)
    .replace("{jam}", timeFormatted, ignoreCase = true)
    .replace("{ritase}", ritaseSpoken, ignoreCase = true)
```

### C. Graceful Fallback (Jika Supir Belum Ditugaskan)
Jika unit belum diisi supir (`driverSpoken` kosong):
- Tag `{pramudi}` otomatis digantikan dengan string kosong `""`.
- Pembersih tanda baca regex (`Regex("""\s*,\s*""")`, `Regex("""^[,\s.-]+""")`, dan `Regex("""\s+""")`) otomatis menormalkan tanda koma ganda:
  `"JAK 115 unit 540, , saatnya berangkat."` $\rightarrow$ `"JAK 115 unit 540, saatnya berangkat."`
  Hasil suara tetap terdengar mulus dan alami tanpa cacat tanda baca.

---

## 5. Rencana Pengujian (Quality Gates)

1. **Unit Test Dart (Domain & Logika Bisnis):**
   - Serialization dan deserialization model `Driver` (JSON round-trip, tetap vs cadangan, full name & call name).
   - `Scheduler.generate()` & `replan()`:
     - Verifikasi jadwal sebelum `shiftChangeTime` (misal 05:00 s.d. 12:59) memegang `driverName` supir Shift 1 (Pagi).
     - Verifikasi jadwal sesudah `shiftChangeTime` (misal 13:00 s.d. 22:00) memegang `driverName` supir Shift 2 (Siang).
     - Verifikasi rotasi/rolling shift (swap 1 unit maupun rolling massal seluruh rute).
   - `buildAlarmPlan`: verifikasi payload `driverName` sampai ke `AlarmEvent`.
2. **Unit Test Kotlin Android:**
   - Verifikasi penggantian `{pramudi}` di `AlarmSpeechText.format()` saat pramudi terisi.
   - Verifikasi fallback cerdas saat `driverName` kosong: tag `{pramudi}` lenyap dan koma ganda dibersihkan secara otomatis.
3. **Widget Test Flutter:**
   - Verifikasi hilangnya teks `"Aktif untuk jadwal baru"` pada kartu unit Halaman 02 Armada.
   - Verifikasi rendering slot supir pagi & siang pada kartu armada.
   - Verifikasi tombol swap `⇄` membalikkan posisi supir seketika.
   - Verifikasi tombol *Kelola Pramudi* di header membuka BottomSheet master data.
   - Verifikasi kepatuhan Dual Theme (Dark Obsidian vs Light Silver).
4. **Kepatuhan Aturan Repositori:**
   - Bekerja secara eksklusif pada branch `devmode`.
   - **TIDAK melakukan build APK** sebelum diperintahkan secara eksplisit oleh pengguna.
