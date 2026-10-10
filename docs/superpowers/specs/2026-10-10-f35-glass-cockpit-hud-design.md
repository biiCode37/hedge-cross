# F-35 Digital Glass Cockpit & Tactical HUD — Design Specification

Dokumen spesifikasi desain resmi untuk mentransformasikan antarmuka aplikasi **HEDGE (Headway Generator By Mikrotrans Utara)** menjadi **F-35 Digital Glass Cockpit / Tactical Flight HUD** berbasis referensi visual *Tactical Dispatch Control Console*.

---

## 1. Analisis Referensi Desain & Filosofi Visual

Berdasarkan referensi visual *Tactical Dispatch Control*, antarmuka mengadopsi estetika konsol operasi militer/penerbangan modern kelas atas:

1. **Beveled & Chamfered Frame Panels (`CockpitFrame`):**
   - Panel kontainer tidak menggunakan kartu rounded biasa, melainkan sudut potong miring (*chamfered 45° cut*) dengan aksen garis neon tipis 1.2px dual-tone:
     - Sisi Kiri / Atas: **Electric Cyan (`#00E5FF` / `#38BDF8`)**
     - Sisi Kanan / Bawah: **Amber Glow (`#FF9800` / `#F59E0B`)**
   - Latar belakang panel berupa kaca gelap bergradien (*dark glassmorphic surface* `#0A0F18` / `#0C121D`) dengan transparansi halus.

2. **Section Header Recessed Badge (`CockpitSectionHeader`):**
   - Setiap bagian panel memiliki judul yang tertanam pada kapsul bertakik (*recessed pill*) tepat di atas garis pembatas panel, misalnya:
     - `[ACTIVE DISPATCH MISSION]`
     - `[DEPLOYED UNITS]`
     - `[ENV DATA]` / `[SYSTEMS]`

3. **Status Badges Dual-Tone (`CockpitStatusBadge`):**
   - Kapsul status dengan lampu LED indikator dot menyala:
     - `[READY • OK]` (Cyan/Green neon)
     - `[EN ROUTE]` (Amber neon)
     - `[STANDBY]` (Amber/Yellow)
     - `[ONLINE • LOKAL]` (Cyan dot)

4. **Cockpit Multi-Function Display (MFD) Bottom Navigation Bar:**
   - Navigasi bawah berupa bar konsol khusus dengan 4 tombol bezel chamfered ergonomis satu jempol (*thumb-first*):
     - `[⌖] 01 · JADWAL` (Tactical Mission Scope & Timeline)
     - `[🚌] 02 · ARMADA` (Fleet Manifest & Status Kesiapan)
     - `[≡] 03 · URUTAN` (Sortie Rotation & Antrian Ritase)
     - `[⚙] 04 · RUTE` (Flight/Route Parameters & Konfigurasi)

---

## 2. Palet Warna & Design Tokens

Mengacu pada logo resmi HEDGE dan referensi taktis:

| Token | Dark Mode (Obsidian Tactical) | Light Mode (Polar Slate) | Peran |
| :--- | :--- | :--- | :--- |
| `cockpitBackground` | `#070B12` (Deep Obsidian) | `#F8FAFC` (Pure Slate) | Latar dasar seluruh aplikasi |
| `cockpitSurface` | `#0A0F18` / `#0C121D` | `#FFFFFF` | Permukaan panel instrumen kaca |
| `cockpitBorderCyan` | `#00E5FF` / `#38BDF8` (Alpha 0.6) | `#0284C7` (Alpha 0.8) | Garis neon sudut kiri/atas panel |
| `cockpitBorderAmber`| `#FF9800` / `#F59E0B` (Alpha 0.6) | `#D97706` (Alpha 0.8) | Garis neon sudut kanan/bawah panel |
| `cockpitGlowCyan` | `rgba(0, 229, 255, 0.25)` | `rgba(2, 132, 199, 0.12)` | Ambient glow panel dan tombol aktif |
| `cockpitGlowAmber` | `rgba(255, 152, 0, 0.25)` | `rgba(217, 119, 6, 0.12)` | Ambient glow status warning/due |
| `cockpitTextPrimary`| `#F8FAFC` (Crisp Silver White) | `#0F172A` (Deep Slate Ink) | Teks utama angka & label |
| `cockpitTextMuted`  | `#94A3B8` (Muted Slate) | `#64748B` (Cool Grey) | Teks sekunder & satuan |

---

## 3. Arsitektur Komponen Baru (`lib/ui/cockpit_components.dart`)

Untuk menjaga kebersihan kode dan menghindari *god-file* di `lib/ui/app.dart`, semua komponen instrumen avionik diisolasi ke dalam modul tersendiri:

### 3.1 `CockpitFrame` (Chamfered Glass Container)
- **Fungsi:** Pembungkus kartu berpenampilan F-35 Glass Display dengan sudut chamfered 45°.
- **Renderer:** `CustomPainter` (`CockpitFramePainter`) yang menggambar:
  - Outline bergaris ganda dengan transisi gradient Cyan ke Amber.
  - Bracket sudut teknis (*corner tick brackets*) di 4 sudut.
  - Recessed header notch di bagian atas tengah jika parameter `title` disediakan.

### 3.2 `AvionicsTopBar` (Top Flight Header)
- **Fungsi:** Menggantikan `AppBar` material lama.
- **Elemen:**
  - Ikon reticle radar `[⌖]` berdenyut lembut (*pulse animation*).
  - Teks Monospaced: `HEDGE DISPATCH CONTROL`.
  - Subtitle: `MIKROTRANS UTARA · [RUTE AKTIF]`.
  - Chip status kanan: `[ONLINE • LOKAL]` dan jam digital WIB live (`HH:mm:ss`).
  - Action buttons: Shortcut Papan TV dan Modal Pengaturan & Backup.

### 3.3 `CockpitMfdNavBar` (Bottom MFD Control Strip)
- **Fungsi:** Menggantikan `NavigationBar` material standar.
- **Tinggi:** 66dp (ramah akses satu jempol).
- **Elemen:**
  - 4 Tombol sentuh MFD taktis dengan dual-label:
    - Index 0: `[⌖] 01 · JADWAL`
    - Index 1: `[🚌] 02 · ARMADA`
    - Index 2: `[≡] 03 · URUTAN`
    - Index 3: `[⚙] 04 · RUTE`
  - Tombol aktif mendapatkan pendaran neon cyan/amber (`BoxShadow` pendaran neon), border 1.5px, dan teks tebal.

### 3.4 `CockpitStatusBadge` (LED Indicator Pill)
- **Fungsi:** Kapsul status serbaguna untuk status armada, trip, dan sistem.
- **Format:** `● [STATUS_TEXT]` dengan lampu LED berkedip atau pendaran lembut.

---

## 4. Rencana Integrasi ke Halaman Utama (`lib/ui/app.dart`)

1. **Sub-Proyek 1 (Fondasi Global & Navigasi MFD):**
   - Mengintegrasikan `AvionicsTopBar` dan `CockpitMfdNavBar` ke dalam `HomeScreen`.
   - Mengatur selector rute horizontal dengan aksen chip MFD taktis.
2. **Sub-Proyek 2 (Halaman Jadwal / Mission Queue):**
   - Membungkus timeline keberangkatan dan telemetri dalam `CockpitFrame`.
3. **Sub-Proyek 3 (Halaman Armada / Fleet Manifest):**
   - Menata ulang daftar armada menjadi *Deployed Fleet Manifest* seperti pada gambar referensi.
4. **Sub-Proyek 4 (Halaman Urutan / Sortie Rotation):**
   - Menata ulang rotasi giliran mobil ke dalam matriks rotasi instrumen.
5. **Sub-Proyek 5 (Halaman Rute / Mission Parameters):**
   - Merombak form headway dan parameter rute menjadi *Avionics Mission Config Panel*.

---

## 5. Rencana Pengujian & Quality Gates

- **Static Analysis:** `dart analyze` wajib 0 error / warning.
- **Flutter Widget Tests:** Semua 71 test suite existing harus tetap **PASS** 100%.
- **Test Baru:** `test/cockpit_components_test.dart` menguji rendering `CockpitFrame`, `AvionicsTopBar`, dan interaksi tap pada `CockpitMfdNavBar`.
- **Aksesibilitas & Layar Mini:** Pengujian pada resolusi 320x640 dengan pembesaran teks 1.6x di Dark dan Light mode tanpa overflow.
