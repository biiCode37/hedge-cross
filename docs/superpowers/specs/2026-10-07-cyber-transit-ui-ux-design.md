# Spesifikasi Desain UI/UX HEDGE — Cyber-Transit HUD Telemetry

- **Topik**: Transformasi Desain UI/UX HEDGE (Headway Generator By Mikrotrans Utara)
- **Konsep Terpilih**: **Opsi 1 — Cyber-Transit HUD Telemetry**
- **Status Dokumen**: *Bagian 1 Disepakati & Dikunci (7 Oktober 2026)*
- **Target Pengguna**: Dispatcher smartphone Android di lapangan (akses 1 jempol / *thumb-first* di terminal)

---

## 1. Visualisasi Desain Resmi (Mockup Bagian 1)

![Cyber-Transit HUD Mockup](file:///D:/MINE/HEDGE-FLUTTER/docs/superpowers/specs/assets/cyber-transit-hud-mockup.jpg)

*Gambar 1: Antarmuka Cyber-Transit HUD Telemetry menampilkan Live Capsule Hero, Telemetry Capsule Bar, dan Transit Timeline.*

---

## 2. Bagian 1: Arsitektur Komponen & Sistem Visual (DIKUNCI)

### 2.1 Identitas Brand & Token Warna
Mengacu pada logo visual resmi HEDGE (Mikrotrans Utara):
* **Primary Amber Glow**: `#FF9800` (Status "Waktu Berangkat / Due") dan `#FFB74D` (Aksen gradasi tombol).
* **Neon Electric Cyan**: `#00E5FF` (Status "Keberangkatan Berikutnya", progress ring waktu, garis rel transit).
* **Deep Obsidian Surface**: `#070B12` (Latar belakang gelap pekat) dan `#0E141E` (Permukaan kartu elevasi).
* **Crisp Silver / White**: `#F8FAFC` (Teks kontras tinggi dan nilai numerik).
* **HUD Border Frame**: Garis batas kartu setebal 1px–1.5px dengan gradasi halus (opacity 40%–70%) tanpa efek blur shader yang membebani GPU.

### 2.2 Tipografi Telemetry & Angka Bebas Jitter
* **Tabular Figures Wajib**: Menggunakan `FontFeature.tabularFigures()` pada seluruh teks angka (nomor unit, jam, menit, detik) agar tidak bergetar (*no jitter*) saat detik berganti setiap 1 detik.
* **Ukuran Unit Hero**: Nomor armada berukuran `48–56sp` dengan bobot `FontWeight.w800` agar terbaca sekilas dari jarak 1 meter di bawah sinar matahari langsung.

### 2.3 Pembagian Modul Komponen (`lib/ui/`)
Menghindari "god file" dengan memecah antarmuka menjadi komponen terisolasi:
1. `lib/ui/design_system.dart`: Palet token warna, text style telemetry, radii, dan durasi transisi.
2. `lib/ui/dispatch_components.dart`: Komponen `LiveCapsuleHero`, cincin energi hitung mundur (`CountdownRing`), dan tombol dispatch.
3. `lib/ui/telemetry_bar.dart`: Bar status armada horizontal (`FleetTelemetryPillBar`).
4. `lib/ui/schedule_timeline.dart`: Tampilan linimasa keberangkatan rel transit (`CyberTimelineList`).

### 2.4 Standar Dukungan Dua Tema (Dual-Theme)
* **Dark Mode (Default)**: Dominasi obsidian pekat dan neon glow kontras tinggi, hemat daya baterai layar OLED/AMOLED di lapangan.
* **Light Mode (Daylight High-Contrast)**: Latar abu-abu perak bersih (`#F8FAFC`), permukaan kartu putih salju (`#FFFFFF`), dengan aksen Amber Pekat (`#C65D00`) dan Deep Cyan (`#007799`) yang mempertahankan keterbacaan optimal di siang hari.

### 2.5 Prinsip Performa Tinggi (120 FPS Baseline)
* Mengisolasi detak jam detik (1 Hz) dalam `RepaintBoundary` khusus pada `CountdownRing`, sehingga tidak memicu re-render pada daftar jadwal di bawahnya.
* Menghindari penggunaan `BackdropFilter` / blur shader mahal demi menjamin kelancaran 120 FPS tanpa lag dan konsumsi baterai rendah pada perangkat dispatcher.

---

## 3. Agenda Bagian Berikutnya
- [x] **Bagian 1: Arsitektur Komponen & Visual Design System** *(Disepakati & Dikunci)*
- [ ] **Bagian 2: Logika Interaksi Live Capsule Hero & Transisi Satu Jempol (Slide-Away & Haptics)**
- [ ] **Bagian 3: Telemetry Bar & Cyber Timeline Schedule View**
- [ ] **Bagian 4: Papan TV / Board Monitor Modern**
