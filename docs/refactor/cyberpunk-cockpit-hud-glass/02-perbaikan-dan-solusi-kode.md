# 02 — Perbaikan & Solusi Kode: Cyberpunk Cockpit HUD Glass

## 1. Arsitektur Komponen Baru (`lib/ui/cockpit_components.dart`)

### A. `CockpitFrame` & `CockpitFramePainter`
- Custom painter dengan sudut chamfered 45° (`chamfer: 12.0`).
- Garis border dual-tone linear gradient antara Electric Cyan (`#00E5FF`) dan Tactical Amber (`#FF9800`).
- Corner tick brackets avionik pada sudut kiri-atas dan kanan-bawah.
- Recessed top title notch berlatar kontras dengan LED pulsing indicator.

### B. `CockpitStatusBadge`
- Badge berdesain kapsul ramping dengan pendaran neon dot indicator 5x5 px berbayang pendar (`BoxShadow`).

### C. `AvionicsTopBar`
- Menggantikan `AppBar` konvensional dengan glass panel horizontal.
- Memuat reticle icon `Icons.gps_fixed`, judul brand `HEDGE DISPATCH CONTROL`, jam digital militer real-time terisolasi (`Consumer` clock), rute aktif, serta status mode offline.
- Dilengkapi shortcut TV Board (`Icons.tv`) dan Pengaturan (`Icons.tune`).

### D. `CockpitMfdNavBar`
- Menggantikan `NavigationBar` dengan MFD cockpit switchboard.
- 4 Tombol MFD Taktis berdigit militer: `[01 JADWAL]`, `[02 ARMADA]`, `[03 URUTAN]`, `[04 RUTE]`.
- Efek pendaran cyan aktif dan garis pembatas atas neon.

### E. `CockpitManifestCard`
- Kartu manifes chamfered 8° untuk item daftar Armada, Urutan, dan Sektor Rute.
- Leading box beraksen border neon untuk ikon armada atau nomor giliran.
- Trailing action row yang ergonomis dengan touch-target minimal 44px.

---

## 2. Refactor Halaman & Pencegahan Layout Overflow

### A. Tab Armada (`_fleet` di `lib/ui/app.dart`)
- TextField pencarian dibalut border neon beraksen cyan dan cyber typography.
- Status header `[FLEET MANIFEST]` dibungkus `Expanded` dengan `TextOverflow.ellipsis` agar aman dari overflow pada layar 320px.
- Setiap unit armada menggunakan `CockpitManifestCard`, membedakan warna aktif (cyan) vs tidak aktif (amber), tetap mempertahankan semantic widget `Switch` untuk kompatibilitas test automation.

### B. Tab Urutan Taktis (`_order` di `lib/ui/app.dart`)
- Header instruksi diubah dari `Row` horizontal menjadi `Column(crossAxisAlignment: CrossAxisAlignment.start)`. Badge `[ROTATION ORDER]` diletakkan di atas teks instruksi, menghilangkan lonjakan tinggi vertikal 1600px pada layar 320px ber-textScale 1.6x.
- Tombol panah reorder (`IconButton`) diberi batasan `constraints: BoxConstraints(minWidth: 36, minHeight: 36)` dan `padding: EdgeInsets.zero`.
- Judul nomor unit dibungkus `FittedBox(fit: BoxFit.scaleDown)` agar tidak overflow.

### C. Tab Sektor Rute (`_routes` di `lib/ui/app.dart`)
- Tombol `Tambah rute` dan `Buat semua` dibungkus dalam rasio proporsional `Expanded(flex: 3)` dan `Flexible(flex: 2)`.
- Menggunakan `FittedBox(fit: BoxFit.scaleDown)` pada label tombol sehingga tidak pernah memicu horizontal overflow 6.6px.
- Kartu rute menampilkan badge `[NONAKTIF]` amber saat rute disembunyikan dari jadwal gabungan.

### D. Layar TV Papan Keberangkatan (`BoardScreen` di `lib/ui/board.dart`)
- Empty state menggunakan `CockpitFrame(title: 'PAPAN KEBERANGKATAN')` yang selaras dengan seluruh antarmuka.

### E. Lembar Pengaturan Avionik (`ConfigurationSheet` di `lib/ui/configuration.dart`)
- Header dilengkapi badge `[AVIONICS CONFIG]` dan cyber font.
- Tombol simpan menggunakan `FilledButton.icon` dengan styling neon border dan ikon centang.

---

## 3. Daftar File yang Diubah
1. [`lib/ui/cockpit_components.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/cockpit_components.dart) — Fondasi visual kokpit (`CockpitFrame`, `AvionicsTopBar`, `CockpitMfdNavBar`, `CockpitManifestCard`).
2. [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart) — Integrasi penuh `_fleet`, `_order`, `_routes`, dan `HomeScreen`.
3. [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart) — Integrasi `CockpitFrame` pada empty state BoardScreen.
4. [`lib/ui/configuration.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart) — Styling cyber pada ConfigurationSheet.
