# 01 — Temuan Latar Belakang & Analisis Permasalahan Desain: Cyberpunk Cockpit HUD Glass

## 1. Latar Belakang & Kebutuhan Desain
User menghendaki agar estetika visual aplikasi HEDGE ditingkatkan secara komprehensif ke seluruh antarmuka menggunakan tema **Kokpit Jet Tempur Futuristik (Cyberpunk Telemetry Cockpit / Flight HUD)**, merujuk langsung pada gambar referensi *Tactical Dispatch Control Console*:
- Panel beveled chamfered 45° dengan aksen corner tick brackets avionics.
- Garis aksen neon dual-tone Electric Cyan (`#00E5FF`) dan Amber Glow (`#FF9800`).
- Recessed capsule badges dengan indikator titik LED berpendar.
- Bottom Multi-Function Display (MFD) Tactical Navigation Bar menggantikan bar navigasi konvensional.
- Tipografi cyber monospace tabular berkarakter industrial (`Orbitron`).

## 2. Analisis Keterbatasan Antarmuka Sebelumnya
Sebelum refactor ini dilakukan:
1. **Inkonsistensi Visual Antarhalaman:**
   - Halaman Jadwal telah mulai mengadopsi elemen telemetry, namun halaman Armada, Urutan, Rute, Board (FIDS), dan Pengaturan masih menggunakan kartu `Card(child: ListTile(...))` material standar yang datar dan generik.
2. **Navigasi Bawah Material Biasa:**
   - Navigasi bawah menggunakan `NavigationBar` standar Material 3 yang memakan ruang vertikal dan tidak mencerminkan kontrol avionics taktis.
3. **Risiko Overflow pada Layar Sempit (Narrow 320px - 360px) & Text Scaling 1.6x:**
   - Font cyberpunk berukuran tebal dan berjarak renggang (`letterSpacing`) memiliki lebar glif yang jauh lebih lebar dibanding font standar.
   - Pada baris status manifest dan header aksi (seperti tombol 'Tambah rute' dan 'Buat semua'), penggunaan elemen statis non-flex menyebabkan `RenderFlex overflowed by 84 pixels` dan `RenderFlex overflowed by 6.6 pixels` saat dijalankan pada pengujian ekstrem layar 320px dengan pembesaran teks 1.6x.
   - Di tab Urutan (`_order`), penempatan teks instruksi panjang berdampingan dengan badge taktis dalam satu baris horizontal menyebabkan teks meluber vertikal hingga 1600 pixel dan memicu overflow vertikal 1248 pixel.

## 3. Matriks Akar Masalah (Root Cause Analysis)
| Area | Komponen Lama | Masalah yang Terjadi | Akar Masalah Teknis |
|---|---|---|---|
| Global AppBar & NavBar | `AppBar` & `NavigationBar` Material | Tampilan umum seperti aplikasi biasa, bukan kokpit HUD | Belum adanya styling MFD bezel dan telemetry status bar |
| Tab Armada (`_fleet`) | `Card` + `ListTile` | Visual generik, status unit tidak memiliki indikator LED cyber | Tidak memakai chamfered frame taktis |
| Tab Urutan (`_order`) | `Card` + `ListTile` | Nomor urut rotasi kurang mencolok; overflow saat textScale 1.6x | Header instruksi memakai `Row` dengan badge lebar horizontal |
| Tab Rute (`_routes`) | `Card` + `ListTile` | Tombol 'Buat semua' memicu horizontal overflow 6.6px pada 320px | Tombol `OutlinedButton` unconstrained meminta intrinsic width |
| Layar TV (`BoardScreen`) | Empty state `Container` polos | Inkonsistensi dengan empty state tab jadwal | Belum memakai `CockpitFrame` beveled 45° |
| Form Pengaturan | Sheet material generik | Header form belum mencerminkan kontrol konfigurasi avionik | Belum ada badge taktis dan button neon |
