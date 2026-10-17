# Temuan & Permasalahan: Halaman 02 Armada

## 1. Konteks Operasional Lapangan
Pada sistem dispatcher HEDGE (Headway Generator By Mikrotrans Utara), tab **"02 Armada"** adalah pusat kendali untuk mendaftarkan, mengaktifkan/menonaktifkan, dan mengatur unit bus kecil (Mikrotrans) yang siap beroperasi dalam satu hari layanan.

## 2. Analisis Keterbatasan & Masalah Sebelum Perbaikan
Sebelum perbaikan dilakukan, ditemukan 3 keterbatasan utama pada Halaman 02 Armada:

### A. Polusi Visual & Redundansi Prefix "Unit"
- Di setiap baris manifest armada pada ListView, judul kartu menampilkan string dengan format `'Unit ${unit.number}'`.
- Contoh: `Unit KLM 540`, `Unit KWK 001`.
- Kata "Unit" diulang puluhan kali di layar smartphone dispatcher Android, menghabiskan ruang horizontal (screen real-estate) dan memperlambat pemindaian visual (*eye scanning speed*) saat dispatcher mencari nomor body unit dalam kondisi terburu-buru.

### B. Format Nomor Body Tidak Membedakan Kode Operator & Nomor Body
- Nomor armada Mikrotrans memiliki struktur ganda: **Kode Operator** (seperti `KLM`, `KWK`, `TSU`, `JAK`) dan **Nomor Body** (seperti `540`, `001`, `1168`, `12`).
- Kode operator dan nomor body sebelumnya digabung menjadi satu baris teks biasa.
- Dispatcher kesulitan membedakan dengan cepat armada mana yang berasal dari operator mitra tertentu vs armada reguler, serta angka nomor body tidak menonjol secara visual.

### C. Keterbatasan Seleksi Checklist Biasa & Hilangnya Urutan Seleksi
- Fitur seleksi massal sebelumnya menggunakan icon checklist standar (`Icons.check_box_rounded`).
- Dispatcher tidak dapat melihat urutan armada mana yang pertama, kedua, ketiga, dst. yang mereka tandai.
- Saat tombol **"Aktifkan"** ditekan, controller mengambil urutan bawaan dari `route.units` asli (daftar statis), sehingga mengabaikan urutan taktikal yang diinginkan dispatcher ketika memilih armada di pagi hari.
