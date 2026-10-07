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

## 3. Bagian 2: Logika Interaksi Live Capsule Hero & Transisi Satu Jempol (DIKUNCI)

![Live Capsule Hero Interaction](file:///D:/MINE/HEDGE-FLUTTER/docs/superpowers/specs/assets/cyber-transit-hero-interaction.jpg)

*Gambar 2: Interaksi Live Capsule Hero saat status 'WAKTU BERANGKAT', countdown amber glow di 00:00, dan tactile ripple pada tombol aksi satu jempol.*

### 3.1 State Transisi Kartu Hero
1. **State Normal / Countdown (`Idle`)**:
   * Cincin waktu berputar fluida dengan warna Electric Cyan (`#00E5FF`).
   * Label status: `KEBERANGKATAN BERIKUTNYA` dengan titik cyan solid.
2. **State Segera / Persiapan (`Prep`)**:
   * Menjelang waktu keberangkatan (misal < 60 detik), cincin mulai bergradasi ke Amber Glow lembut.
3. **State Waktu Berangkat (`Due`)**:
   * Saat jam/menit keberangkatan tercapai (`diff <= 0`), seluruh cincin waktu dan border frame kartu bertransformasi menjadi **Amber Glow Pulse** (`#FF9800`).
   * Berdenyut halus setiap 1.5 detik menggunakan `TweenAnimationBuilder` ringan (*zero CPU overhead*).
   * Teks waktu berubah menjadi `00:00 BERANGKAT`.

### 3.2 Interaksi Tombol Satu Jempol & Transisi Meluncur (Slide-Away)
1. **Ergonomi Jempol Ekstra Nyaman**:
   * Tinggi sentuh minimal tombol adalah **54px** dengan lebar penuh kartu (`match-parent width`), memastikan dispatcher dapat menekan tombol secara instan dengan jempol kanan/kiri tanpa perlu presisi rumit.
   * Menggunakan umpan balik getar taktil via `HapticFeedback.mediumImpact()` pada saat sentuhan pertama.
2. **Animasi Meluncur (Slide-Away Dismissal)**:
   * Begitu tombol ditekan, kartu hero melakukan transisi animasi meluncur ke kiri/bawah secara mulus (*Curve: `Curves.easeOutCubic`*, durasi *200ms*) langsung masuk ke baris riwayat ritase.
   * Kartu jadwal keberangkatan berikutnya otomatis meluncur naik (*Slide-up Transition*) menggantikan posisi hero dalam satu gerakan fluida tanpa hentakan layar (*zero layout jump*).
3. **Proteksi Anti-Double-Tap (Debounce 500ms)**:
   * Tombol dinonaktifkan seketika setelah tap pertama untuk mencegah risiko tercatatnya ritase ganda akibat sentuhan cepat berulang di lapangan.

---

---

## 4. Bagian 3: Telemetry Bar & Cyber Timeline Schedule View (DIKUNCI)

![Telemetry Bar and Cyber Timeline](file:///D:/MINE/HEDGE-FLUTTER/docs/superpowers/specs/assets/cyber-transit-timeline-telemetry.jpg)

*Gambar 3: Tampilan Telemetry Bar di bagian atas dan Cyber Transit Timeline dengan rel transit vertikal menyambungkan status armada.*

### 4.1 Fleet Telemetry Pill Bar
1. **Tata Letak & Metrik**:
   * Diletakkan di bawah App Bar dan di atas Live Capsule Hero.
   * Terdiri dari 3 kapsul telemetri:
     * **Kapsul 1 (Armada)**: Ikon armada bus + `39 Unit Aktif` (Aksen Neon Cyan).
     * **Kapsul 2 (Ritase)**: Ikon ritase + `Ritase 3/8` (Aksen Perak / Muted).
     * **Kapsul 3 (Headway)**: Ikon headway + `Headway 3m` (Aksen Amber Glow).
   * **Responsivitas Layar Sempit**:
     * Pada layar sempit (lebar 320–360px), kapsul otomatis memanfaatkan horizontal scrolling halus atau auto-scaling tanpa pembungkusan (*no awkward wrapping*).

### 4.2 Linimasa Rel Transit (Cyber Transit Timeline)
1. **Transit Rail Track Vertikal**:
   * Menggantikan tabel datar konvensional dengan visual rel transit bercahaya:
     * **Selesai Berangkat (`Departed`)**: Rel warna solid, node lingkaran centang emas/amber, teks unit sedikit redup menandakan ritase telah selesai dan mencantumkan waktu aktual keberangkatan.
     * **Aktif / Waktu Berangkat (`Live/Due`)**: Node lingkaran berdenyut (*pulsing aura node*), kartu unit terangkat (*elevated HUD card*) berbingkai neon tipis dengan badge status `WAKTU BERANGKAT`.
     * **Mendatang (`Upcoming`)**: Rel putus-putus (*dashed line*) dengan node lingkaran berongga, teks unit perak kontras tinggi, dan jam rencana keberangkatan (misal: `07:18`, `07:25`).
2. **Filter Ritase Fleksibel**:
   * Dilengkapi bilah chip filter horizontal di atas linimasa untuk melihat ritase tertentu secara cepat (Semua, Ritase 1, Ritase 2, dst.).
3. **Optimasi Performa 120 FPS**:
   * Menggunakan virtualisasi `ListView.builder` dengan ukuran baris item terukur (*fixed item extent*) sehingga scrolling 300+ baris jadwal terasa seringan kertas tanpa jank di GPU ponsel.

---

## 5. Agenda Bagian Berikutnya
- [x] **Bagian 1: Arsitektur Komponen & Visual Design System** *(Disepakati & Dikunci)*
- [x] **Bagian 2: Logika Interaksi Live Capsule Hero & Transisi Satu Jempol** *(Disepakati & Dikunci)*
- [x] **Bagian 3: Telemetry Bar & Cyber Timeline Schedule View** *(Disepakati & Dikunci)*
- [ ] **Bagian 4: Papan TV / Board Monitor Modern (Airport/FIDS Style)**
