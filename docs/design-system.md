# HEDGE design system — 2.0.1

Keputusan desain dari sesi brainstorming: teknologi futuristik yang estetik dan premium, konsisten dengan logo HEDGE, dengan permukaan solid dan perhatian pada performa. Identitas: HEDGE / Headway Generator / By Mikrotrans Utara. Implementasi berada di branch `devmode` pada `D:/MINE/HEDGE-FLUTTER`.

## Hirarki operasional

1. **Nomor unit** menjadi informasi pertama: 44 px pada panel dispatcher, 64 px pada papan lebar. Angka tebal dan tabular.
2. **Countdown** menjadi informasi kedua: 28 px pada dispatcher, 40 px pada papan lebar. Cyan dalam kondisi normal; amber saat sisa waktu <= 60 detik; teks “Waktu berangkat” saat mencapai nol.
3. **Jam rencana** 16 px dengan konteks WIB.
4. **Rute dan ritase** 12 px. Penanda peak mengikuti accent cyan.

Pada layar sempit, nomor unit panjang atau ukuran teks sistem besar, countdown pindah ke bawah nomor unit sehingga keduanya tetap terbaca. Daftar jadwal memakai nomor unit 24 px dan jam 16 px. Papan memakai komponen fokus yang sama untuk menjaga konsistensi.

Pemilihan unit fokus hanya untuk presentasi. Pada waktunya, unit dipertahankan selama durasi alarm rute (dibatasi 1–60 detik), lalu bergeser ke keberangkatan berikutnya. Mencapai nol dan mengakui alarm **tidak** mencatat keberangkatan aktual; aktual tetap membutuhkan tindakan dispatcher. Setelah aktual dicatat, fokus langsung beralih. Jadwal lintas rute dengan jam sama dipilih secara deterministik. Batas 1–60 detik tersebut khusus pemilihan fokus pada panel jadwal; alert penuh source 2.0.2 memiliki durasi tampil tersendiri 1–300 detik. Tombol **Sudah Berangkat** pada alert mencatat aktual, sedangkan timeout tidak. Lihat [panduan alarm](alarms.md).

## Warna berdasarkan peran

| Peran | Dark | Light |
| --- | --- | --- |
| Latar utama | `#070B12` | `#F8FAFC` |
| Permukaan | `#0C1017` | `#FFFFFF` |
| Permukaan input | `#141A24` | `#F1F5F9` |
| Teks utama | `#F8FAFC` | `#0F172A` |
| Teks sekunder | `#94A3B8` | `#475569` |
| Garis | `#2B394B` | `#CBD5E1` |
| Amber untuk teks/status | `#FF9800` | `#9A4700` |
| Cyan untuk teks/status | `#38BDF8` | `#006B8B` |
| Permukaan fokus | `#11212D` | `#EAF5FC` |
| Permukaan peringatan | `#2C2011` | `#FFF2DF` |
| Sukses | `#34D399` | `#087A4B` |
| Kesalahan | `#FB7185` | `#B42336` |

Tombol utama selalu memakai amber branding `#FF9800` dengan teks obsidian `#070B12`. Amber/cyan teks pada tema terang sengaja lebih gelap agar tetap terbaca di putih. Warna identitas rute hanya menjadi penanda kecil; warna operasional tetap mengikuti token. Pasangan teks utama, sekunder, accent, sukses dan kesalahan pada permukaan terkait diuji dengan batas rasio kontras 4.5:1. Garis dekoratif bukan pengganti teks/status.

Token dikendalikan melalui `HedgeTokens`, `HedgePalette` dan `hedgeTheme` di `lib/ui/design_system.dart`. Flutter menggunakan `ThemeExtension` sebagai padanan token tema; CSS variables tidak digunakan oleh UI native ini. Komponen Material diberi warna eksplisit agar tidak muncul tint bawaan yang menggeser identitas logo.

## Bentuk, tipografi dan interaksi

- Roboto lokal tersedia offline; angka memakai tabular figures untuk mengurangi gerakan horizontal countdown.
- Basis spacing 8 px, padding utama 16 px, radius kontrol 12 px dan panel fokus 20 px.
- Touch target tombol/ikon minimal 48 px. Navigasi utama di bawah untuk layar ponsel; rail pada layar lebar.
- Permukaan solid, garis tipis, tanpa gradient, blur latar, glow bergerak atau animasi berulang.
- Transisi tema 180 ms dan dinonaktifkan saat sistem meminta reduced motion. Feedback interaksi memakai komponen native.
- Panel fokus dan aksi jadwal berada di awal layar. Daftar memakai sliver yang memuat baris sesuai kebutuhan; teks besar dapat menambah scroll demi keterbacaan.
- Dialog, input, calendar, menu, chip, tombol, navigasi dan pengaturan mengikuti tema yang sama.

## Strategi performa

Clock tetap menerbitkan tick per detik, tetapi listener UI countdown berada di komponen kecil dengan `RepaintBoundary`. Provider fokus mengembalikan record stabil selama unit belum berganti; daftar jadwal tidak dibangun ulang setiap tick. Pemilihan fokus memakai binary search pada jadwal berurutan. Papan memakai consumer terpisah untuk jam/countdown; ukuran jam tidak mengalahkan nomor unit.

Uji widget membandingkan identitas widget baris jadwal sebelum/sesudah tick, selain memeriksa countdown dan peralihan warna. Ini merupakan bukti pembatasan rebuild di widget test; FPS, baterai dan perilaku vendor Android tetap membutuhkan pengukuran pada perangkat fisik.

## Verifikasi dan preview

Jalankan dari Git Bash:

```bash
cd /d/MINE/HEDGE-FLUTTER
git branch --show-current
flutter analyze --no-pub
flutter test --no-pub
HEDGE_CAPTURE=1 flutter test --no-pub test/widget_test.dart
pnpm run verify:legacy
```

Preview widget menggunakan Roboto, ikon dan logo asli, clock tetap pukul 06:58:20 WIB pada tanggal contoh 2026-10-05. Preview bukan tangkapan perangkat Android. File ada di `docs/screenshots/dispatcher-{360|1200}-{dark|light}.png`.

APK masih merupakan build internal debug dengan signing debug. Ukuran debug bukan perkiraan ukuran release produksi. Tidak ada dependensi visual tambahan dalam perubahan ini.