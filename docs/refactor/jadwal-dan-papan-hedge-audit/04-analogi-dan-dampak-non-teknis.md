# 04. Analogi & Dampak Non-Teknis — Halaman JADWAL & Papan HEDGE

Dokumen ini menjelaskan temuan audit teknis pada halaman **JADWAL** dan mode **Papan HEDGE** dalam bahasa analogi non-teknis dunia nyata, membandingkan kondisi sebelum vs sesudah solusi, serta memaparkan dampak langsungnya bagi dispatcher Mikrotrans di lapangan.

---

## 1. Analogi Dunia Nyata

### 1. Analogi "Peluit Parkir 8 Detik yang Bikin Salah Kirim Angkot" (Bug Drop-Off 8 Detik)
> **Ibarat di Terminal Tanjung Priok / Plumpang:**  
> Bayangkan seorang petugas pos terminal meniup peluit untuk menyuruh **Angkot 01** berangkat pada pukul 07.00. Peluit ditiup selama 8 detik.  
> Namun, supir Angkot 01 butuh waktu 10 detik karena harus menutup pintu geser dan menunggu motor yang memotong jalan.  
> Tepat pada detik ke-9, petugas pos langsung menutup mata dari Angkot 01, mencoret namanya dari papan kerja, dan langsung mengarahkan pandangannya ke **Angkot 02** yang jadwalnya masih 10 menit lagi!  
> Saat Angkot 01 akhirnya melaju di detik ke-11, petugas malah mencatat: *"Angkot 02 sudah berangkat!"*  
> Akibatnya, Angkot 01 dianggap belum pernah narik, Angkot 02 dianggap curi start 10 menit lebih cepat, dan jadwal satu hari langsung berantakan total!

---

### 2. Analogi "Papan Pengumuman FIDS yang Menghapus Bus Mogok" (Armada Terlambat Lenyap)
> **Ibarat Layar Monitor Keberangkatan di Stasiun / Terminal:**  
> Di ruang tunggu ada layar TV besar yang menampilkan jadwal angkot. Calon penumpang melihat Angkot 01 dijadwalkan pukul 07.00.  
> Pukul 07.01, Angkot 01 agak telat karena ban kurang angin. Alih-alih menampilkan tulisan **"TERLAMBAT 1 MENIT"**, layar TV tersebut **langsung menghapus nama Angkot 01 dari monitor**, seolah-olah angkot itu sudah lenyap ditelan bumi!  
> Penumpang dan supir bingung: *"Lho, angkotnya masih parkir di depan mata, kok di layar sudah hilang?"*

---

### 3. Analogi "Spidol Permanen Tanpa Penghapus" (Ketiadaan Tombol Undo)
> **Ibarat Mencatat di Buku Ekspedisi:**  
> Dispatcher mencatat keberangkatan supir menggunakan spidol permanen tebal di atas papan tulis yang dilapisi laminasi permanen.  
> Ketika tangan dispatcher tersenggol pengemudi yang lewat sehingga spidol mencoret kolom yang salah, tidak ada penghapus (*tipex*) yang tersedia. Coretan salah itu abadi dan tidak bisa dibatalkan sampai akhir jam kerja.

---

### 4. Analogi "Papan Tulis yang Terkunci di Balik Kaca Etalase" (Papan HEDGE Pasif)
> **Ibarat Layar Kiosk di Pos Pantau:**  
> Dispatcher memasang tablet di dinding pos pantau agar supir-supir bisa melihat hitung mundur.  
> Namun, setiap kali ada supir yang berangkat, layar tablet di dinding itu tidak bisa disentuh untuk mencatat. Dispatcher harus menekan tombol keluar, membuka buku catatan di kantong, mencoret nama supir, lalu menyalakan kembali layar tablet di dinding. Sangat melelahkan untuk pekerjaan yang berulang tiap beberapa menit.

---

### 5. Analogi "Lampu Sirine Pos yang Padam Karena Sekring Izin Lepas" (Alert Dialog Fullscreen Tidak Muncul)
> **Ibarat Sirine Darurat di Pos Dispatcher:**  
> Di atas meja pos pantau dipasang lampu sirine besar berputar yang seharusnya menyala merah terang saat jam keberangkatan tiba, memunculkan papan bertuliskan: *"UNIT 05 BERANGKAT!"*.  
> Namun, kabel sirine itu diputus karena sistem Android menolak izin *"tampilkan di atas aplikasi lain"*, dan aplikasi Flutter di layar sendiri sengaja mematikan lampu cadangannya.  
> Hasilnya: saat jam berangkat tiba, sirine diam membisu dan layar tetap hening tanpa dialog apapun. Dispatcher yang sedang fokus mencatat karcis tidak sadar bahwa armada sudah harus jalan.

---

## 2. Perbandingan Situasi: Sebelum vs Sesudah Perbaikan

| Aspek Operasional | Situasi Sebelum Perbaikan (Kondisi Saat Ini) | Situasi Sesudah Perbaikan (Solusi yang Ditawarkan) |
|---|---|---|
| **Alert Dialog Fullscreen** | Dialog modal keberangkatan tidak muncul di Android (terblokir izin OS & overlay Flutter mati). | Overlay dialog modal selalu aktif di dalam aplikasi saat dibuka, lengkap dengan tombol langsung "Sudah Berangkat". |
| **Keterlambatan Armada** | Lewat 8 detik, unit langsung hilang dari kartu fokus dan papan informasi. Dispatcher salah mencatat unit berikutnya. | Unit yang belum jalan tetap menjadi prioritas utama dengan badge **TERLAMBAT (+mm:ss)** sampai benar-benar dicatat jalan. |
| **Papan Informasi (FIDS)** | Armada telat lenyap dari layar TV, menyisakan kebingungan supir dan penumpang. | Armada telat tetap terpampang jelas di layar dengan status **TERLAMBAT**, supir tahu urutan giliran mereka. |
| **Kesalahan Pencet Layar** | Sekali salah tekan "SUDAH BERANGKAT", data rusak permanen dan tidak bisa dibatalkan sama sekali. | Tersedia tombol **"BATALKAN" (Undo)** instan selama 5 detik, serta opsi tap pada daftar untuk koreksi. |
| **Operasional di Kiosk Tablet** | Mode Papan HEDGE pasif total. Harus keluar masuk layar setiap kali memberangkatkan armada. | Kartu di Papan HEDGE memiliki tombol aksi langsung, dispatcher cukup sentuh satu kali tanpa pindah halaman. |
| **Kejelasan Istilah** | Saat jam keberangkatan tiba, muncul tulisan membingungkan **"WAKTU TIBA"** (disangka kedatangan). | Ditampilkan istilah yang tepat dan lugas: **"WAKTU BERANGKAT"** atau **"SIAP BERANGKAT"**. |
| **Peralihan Hari (Besok Pagi)** | Buka aplikasi jam 5 pagi, layar langsung menyapa dengan tulisan **"Layanan selesai"** karena tanggal masih kemarin. | Tanggal rollover otomatis mendeteksi hari baru, aplikasi langsung siap membuat atau memuat jadwal hari ini. |
| **Penggunaan Siang Hari di Lapangan** | Di bawah terik matahari Jakarta, garis rel dan gauge timer di tema terang (Light Mode) nyaris tidak terlihat. | Kontras warna tinggi dan tegas di Light Mode; dispatcher tetap bisa membaca linimasa meski di bawah silau matahari. |

---

## 3. Dampak Langsung bagi Dispatcher di Lapangan

1. **Peringatan Keberangkatan Visual 100% Andal:**
   Dispatcher tidak akan pernah melewatkan waktu berangkat armada karena dialog visual modal langsung muncul seketika di atas layar aplikasi tanpa terhalang izin OS Android.
2. **Beban Mental Dispatcher Berkurang Signifikan:**
   Dispatcher tidak perlu lagi merasa cemas atau terburu-buru "balapan dengan waktu 8 detik" hanya untuk menekan tombol keberangkatan sebelum kartu fokus melompat ke unit yang salah.
3. **Kerapian Data Operasional Mikrotrans:**
   Laporan ekspor Excel dan histori headway harian menjadi 100% akurat karena tidak ada lagi insiden salah catat unit yang berangkat lebih awal secara prematur.
4. **Efisiensi Kerja di Pos Pantau:**
   Penggunaan Papan HEDGE pada tablet pos pantau menjadi benar-benar fungsional sebagai pusat kendali (*command kiosk*), bukan sekadar pajangan pasif yang menyulitkan kerja.
5. **Kenyamanan Visual Sepanjang Hari:**
   Baik saat terik matahari siang maupun malam hari saat shift penutup, dispatcher dapat mengoperasikan aplikasi dengan nyaman tanpa gangguan keterbacaan (*eye-strain free*).
