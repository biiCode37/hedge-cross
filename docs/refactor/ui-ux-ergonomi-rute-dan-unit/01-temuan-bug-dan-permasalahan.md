# Temuan & Permasalahan: Ergonomi Tampilan Rute, Truncation, dan Seleksi Unit

## 1. Konteks Operasional Lapangan
Pada sistem operasi **HEDGE (Headway Generator By Mikrotrans Utara)**, sebagian besar pengguna adalah dispatcher lapangan yang mengoperasikan smartphone Android dalam kondisi ritme kerja cepat, dinamis, dan di bawah terik matahari maupun malam hari. Efisiensi tata letak (*layout density*), kecepatan pemindaian visual (*eye scanning speed*), dan aksesibilitas satu jempol (*thumb-first ergonomics*) merupakan faktor vital penentu kelancaran pemberangkatan armada.

Berdasarkan audit visual terhadap 5 tangkapan layar (*screenshot*) kondisi aplikasi saat ini, ditemukan inkonsistensi desain, tabrakan elemen antarmuka (*visual overlap*), pemborosan ruang horizontal (*horizontal space misuse*), dan pemotongan teks parah (*severe truncation*).

---

## 2. Temuan Keterbatasan & Anomali UI/UX

### A. Polusi Teks Nama Rute Panjang di Halaman Selain "04 Rute"
- **Kondisi:** Nama rute panjang (misal: `JAK.01 - TANJUNG PRIOK - PLUMPANG` atau `JAK.115 – TERM.TANJUNG PRIOK`) ditampilkan secara penuh di baris header dan komponen sub-header di berbagai halaman (seperti pada sheet Master Pramudi).
- **Dampak Visual:** 
  - Pada header Master Pramudi (Screenshot 1, 2, 3), teks nama rute menembus dan bertabrakan langsung ke belakang tombol aksi `[+ Tambah Pramudi]`. Teks rute menjadi tidak terbaca dan merusak hierarki visual.
  - Memakan ruang layar vertikal dan horizontal yang sangat berharga pada layar ponsel berukuran 360–390dp.

### B. Pemotongan Teks Ekstrem (*Truncation*) pada Kartu Rute di Halaman "04 Rute"
- **Kondisi:** Pada tab "04 Rute" (Screenshot 5), judul kartu rute memaksakan kode rute dan nama lintasan dalam satu baris horizontal sejajar (`r.name`) berdampingan dengan badge status `[NONAKTIF]` dan tombol menu kebab `⋮`.
- **Dampak Visual:** Nama lintasan terpotong secara ekstrem menjadi 1–3 karakter saja (`JAK.01 - TA...`, `JAK.05 - S...`, `JAK.113 - T...`). Nama rute menjadi sama sekali tidak informatif dan sia-sia bagi dispatcher.

### C. Pemborosan Ruang Horizontal pada Komponen Pill Rute Top Bar
- **Kondisi:** Komponen `ChoiceChip` horizontal di bar atas (Screenshot 5) memuat teks string penuh nama rute beserta lintasannya. Selain itu, semua rute di workspace ditampilkan tanpa menyaring apakah rute tersebut aktif beroperasi atau non-aktif.
- **Dampak Visual:** Satu pill menghabiskan hampir 85% lebar layar smartphone. Dispatcher terpaksa melakukan swipe horizontal berulang-ulang hanya untuk berganti rute, menurunkan kecepatan reaksi dispatching.

### D. Urutan Daftar Rute Tidak Memprioritaskan Status Operasional
- **Kondisi:** Daftar rute pada halaman "04 Rute" ditampilkan dengan urutan statis atau numerik bawaan tanpa memperhitungkan status aktif/non-aktif rute (`participates`).
- **Dampak Visual:** Rute yang aktif operasional bercampur dengan belasan rute non-aktif. Dispatcher harus menyusuri list ke bawah untuk menemukan rute yang sedang berjalan.

### E. Responsive Flex Layout Bug pada Filter Bar Master Pramudi
- **Kondisi:** Pada sheet Master Pramudi (Screenshot 2), baris pencarian dan segmented filter (`Semua`, `Tetap`, `Cadangan`) berbagi ruang horizontal secara kaku menggunakan `Expanded(child: TextField(...))` di sebelah `SegmentedButton`.
- **Dampak Visual:** Saat tab `Tetap` aktif, lebar segmented button menyusut sedikit sehingga kotak pencarian tiba-tiba menampilkan potongan teks `"C..."` (dari placeholder "Cari nama supir...") yang gepeng dan terpotong secara vertikal/horizontal.

### F. Input Nomor Unit Manual pada Form Tambah Pramudi
- **Kondisi:** Pada dialog form Tambah Pramudi Baru (Screenshot 4), kolom input nomor unit bawaan berupa `TextField` biasa dengan placeholder panjang yang terpotong (`Nomor Unit Bawaan (Opsio...`).
- **Dampak Operasional:** Dispatcher rentan salah ketik (*typo*) nomor armada, format nomor unit tidak terstandarisasi, dan tidak ada validasi apakah unit tersebut memang terdaftar pada rute terkait.
