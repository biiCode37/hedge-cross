# 04. Analogi & Dampak Non-Teknis — Unifikasi Single-Component Fullscreen Alert

Dokumen ini memuat analogi non-teknis dunia nyata yang mudah dipahami, perbandingan kondisi sebelum vs sesudah perbaikan, serta dampak langsung bagi dispatcher di lapangan.

---

## 1. Analogi Dunia Nyata: "Dua Jam Dinding di Pos Dispatcher"

Bayangkan seorang kepala regu dispatcher di pangkalan terminal memiliki **dua buah jam alarm**:
- **Alarm Pertama:** Jam digital modern canggih di atas meja kerjanya yang memiliki layar LED besar bercahaya, angka terbaca jelas dari jauh, warna peringatan oranye menyala, dan tombol konfirmasi yang empuk. Jam ini hanya berbunyi jika dispatcher sedang duduk di depan mejanya.
- **Alarm Kedua:** Jam weker manual kuno dari besi yang dipasang di pintu belakang. Jam ini berbunyi ketika dispatcher sedang berdiri mengecek bus di luar atau sedang berada di toilet. Tampilannya berbeda, angkanya kecil, dan cara mematikannya harus memutar tuas manual.

Keberadaan dua jam berbeda ini sangat **aneh dan membingungkan**:
- Dispatcher harus mengingat dua cara kerja jam yang berbeda.
- Saat alarm kedua bunyi, dispatcher sering salah pencet karena bentuk tombolnya tidak sama dengan jam utama.

**Setelah Perbaikan:**
Jam weker kuno di pintu belakang dicopot dan dibuang. Sekarang, **jam digital modern yang canggih itu dibuatkan speaker nirkabel dan mekanisme pemanggil otomatis**:
Kapan pun alarm berbunyi—baik dispatcher sedang duduk santai di mejanya, sedang membuka HP membaca pesan grup pengemudi, atau saat HP ditaruh di saku celana—**hanya jam digital modern yang sama persis** yang akan langsung menyala terang dan menampilkan layar besar yang sudah sangat dihafal oleh dispatcher.

---

## 2. Perbandingan Sebelum vs. Sesudah Perbaikan

| Parameter | Sebelum Perbaikan (Dual Component) | Sesudah Perbaikan (Unified Component) |
| :--- | :--- | :--- |
| **Jumlah Komponen Alert** | 2 Komponen terpisah (Flutter Overlay & Android Native Canvas) | **1 Komponen Tunggal** (`ForegroundAlarmOverlay` Flutter) |
| **Konsistensi Visual** | Inkonsisten (tampilan berbeda saat app aktif vs saat buka app lain) | **100% Identik & Seragam** di semua kondisi |
| **Beban Pemeliharaan Kode** | Berat (harus merawat 2 basis kode Dart & Kotlin Canvas) | **Ringan & Bersih** (467 baris kode redundan dihapus) |
| **Siklus Sinkronisasi Aksi** | Aksi di native harus ditulis ke JSON buffer lalu di-poll | **Langsung reaktif** ke state Riverpod aplikasi |
| **Keandalan Membangunkan Layar** | Tergantung Activity native sekunder yang rawan tertutup OS | Menggunakan `showWhenLocked` & `turnScreenOn` resmi pada Activity utama |

---

## 3. Dampak Langsung bagi Dispatcher di Lapangan

1. **Nol Kebingungan (*Zero Cognitive Load*):**
   - Dispatcher di shelter tidak lagi terkejut melihat tampilan alert yang berganti-ganti bentuk ketika mereka sedang multitasking membuka aplikasi lain (misal WhatsApp operasional atau kalkulator).
2. **Kecepatan Refleks Satu Jempol (*Thumb-First Muscle Memory*):**
   - Letak tombol *"Sudah Berangkat"*, *"Tutup Alert"*, dan hitungan mundur radar 220dp selalu berada di posisi koordinat yang presisi sama persis.
3. **Respon Cepat Saat Layar HP Mati:**
   - Ketika waktu keberangkatan tiba saat HP dispatcher berada di dasbor atau meja dengan layar padam, layar otomatis menyala terang dan langsung menampilkan antarmuka HEDGE tanpa perlu membuka kunci layar (*unlock*) terlebih dahulu.
