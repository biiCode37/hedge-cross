# 04. Analogi & Dampak Non-Teknis — Clean Schedule, Start Round & Batch Fleet

Dokumen ini menjelaskan peningkatan operasional dalam analogi non-teknis dunia nyata yang mudah dipahami, perbandingan kondisi sebelum vs sesudah, serta dampak langsung bagi dispatcher Mikrotrans di lapangan.

---

## 1. Analogi Dunia Nyata: Papan Operasional Terminal Bus

### Analogi 1: Mengatur Nomor Ritase seperti Menyetel Jam Tangan Sesuai Kondisi Lapangan
Bayangkan seorang pengatur perjalanan yang baru datang ke terminal pada pukul 12 siang untuk shift kedua. Di lapangan, para pengemudi mikrotrans sudah menyelesaikan putaran (rit) 1 dan 2 di pagi hari, dan sekarang mereka bersiap untuk **Putaran ke-3**.
- **Sebelum Perbaikan:** Sistem lama seperti papan tulis yang kaku. Setiap kali tombol jadwal ditekan, papan itu selalu menulis angka "1" di kolom putaran. Dispatcher terpaksa melihat armada jalan di rit 3 tetapi di aplikasinya tertulis "R1". Ketika laporan dinas dicocokkan, nomor ritase tidak sesuai dengan buku catatan pengemudi.
- **Sesudah Perbaikan:** Ketika menekan "Buat Jadwal", muncul kotak setelan digital cepat. Cukup ketuk tanda `[+]` dua kali, nomor melompat ke **RIT 3**. Seluruh papan jadwal langsung tersusun mulai dari Rit 3, 4, 5, dan seterusnya. Data aplikasi kini 100% selaras dengan kenyataan di jalan raya.

---

### Analogi 2: Menghapus Kalender Dinding yang Menutupi Papan Keberangkatan
- **Sebelum Perbaikan:** Di bagian paling atas papan pengumuman keberangkatan, ditempel kalender meja besar yang jarang disentuh. Karena papan tertutup kalender, kartu jadwal keberangkatan mikrotrans berikutnya terdorong ke bawah dan terpotong.
- **Sesudah Perbaikan:** Kalender dinding yang tidak perlu tersebut dicopot. Ruang layar menjadi lapang dan bersih. Dispatcher langsung melihat daftar rute dan deretan keberangkatan armada secara penuh saat aplikasi dibuka.

---

### Analogi 3: Menangani 10 Kendaraan Sekaligus vs. Satu per Satu
- **Sebelum Perbaikan:** Jika ada 10 mikrotrans yang tiba-tiba harus diistirahatkan karena perbaikan jalan, dispatcher harus mendatangi masing-masing kendaraan satu per satu dan menekan saklar 10 kali berturut-turut. Melelahkan dan lambat.
- **Sesudah Perbaikan:** Cukup tekan **"Pilih Semua"** (atau centang beberapa armada), lalu ketuk satu tombol **[Nonaktifkan]**. Seketika seluruh armada yang dipilih beralih status secara bersamaan dalam satu detik. Demikian pula jika ingin menghapus armada yang sudah tidak beroperasi, sistem meminta konfirmasi sekali saja lalu membersihkan seluruhnya secara aman.

---

## 2. Perbandingan Kondisi Sebelum vs. Sesudah

| Aspek | Kondisi Sebelum | Kondisi Sesudah |
|---|---|---|
| **Header Halaman Jadwal** | Menampilkan tombol kalender dan teks 'Lokal' yang memakan ruang | Bersih total, memaksimalkan ruang pandang timeline rute |
| **Penomoran Ritase Awal** | Statis, selalu dipaksa mulai dari Rit 1 | **Fleksibel**: Stepper taktil `[-] [ RIT N ] [+]` saat buat jadwal |
| **Kesesuaian Data Lapangan** | Sering tidak sinkron saat pergantian shift siang | **100% Sinkron** dengan ritase nyata di lapangan |
| **Operasi Status Armada** | Harus toggle switch satu per satu | **Batch Multi-Select & Select All** (Aktifkan / Nonaktifkan massal) |
| **Penghapusan Armada** | Hapus satu per satu berulang kali | **Hapus Massal** dengan satu dialog konfirmasi aman |
| **Beban Transaksi Database** | 10x simpan SQLite untuk 10 armada | **1x Simpan Atomic** untuk seluruh unit terpilih |

---

## 3. Dampak Langsung bagi Dispatcher di Lapangan

1. **Efisiensi Waktu di Terminal Naik Drastis:**
   - Pergantian status armada untuk belasan unit kini selesai dalam 2 detik, tidak lagi membuang waktu mengetuk layar berulang kali.
2. **Kesesuaian Laporan dan Pelacakan Headway:**
   - Dispatcher dan pengemudi kini memiliki acuan nomor ritase yang sama persis (misal sama-sama di Rit 4), menghindari selisih paham saat evaluasi target harian.
3. **Visibilitas Layar Smartphone Maksimal:**
   - Tanpa header tanggal yang menghalangi, kartu jadwal keberangkatan terlihat lebih banyak tanpa perlu sering menggulir layar (*zero unnecessary scroll*).
