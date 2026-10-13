# 04. Analogi & Dampak Non-Teknis — Papan Jam Kerja & Papan Skor Putaran Armada

Dokumen ini menyajikan analogi dunia nyata serta perbandingan situasi sebelum dan sesudah perbaikan agar mudah dipahami oleh dispatcher, manajemen operasional, dan pihak non-teknis di lapangan.

---

## 1. Analogi Non-Teknis Dunia Nyata

### A. Analogi Kalender Meja yang Terjebak Kemarin (Bug Countdown)
Bayangkan di pos dispatch terminal ada sebuah **jam dinding pintar** dan **kalender meja fisik**.
- **Sebelum Perbaikan:** Kemarin tanggal 12, kalender dibuka pada tanggal 12. Karena laci penyimpanan tidak pernah merobek kalender secara otomatis saat malam tiba, kalender tersebut tetap tertulis **"Tanggal 12"**. Ketika pagi hari tanggal 13 dispatcher datang dan menyuruh mesin: *"Cetak jadwal keberangkatan untuk hari ini!"*, mesin melihat kalender meja dan mencetak jadwal dengan stempel **"Tanggal 12"**. Jam dinding pintar melihat jadwal itu dan bingung: *"Lho, jam keberangkatan ini kan jam 07:00 kemarin! Berarti bus ini sudah telat 24 jam!"* Akibatnya, jarum jam hitung mundur langsung menunjukkan angka merah minus puluhan jam, dan bel tanda bersiap tidak pernah berbunyi.
- **Setelah Perbaikan:** Sekarang kalender meja dilengkapi sistem digital otomatis. Begitu matahari terbit atau hari berganti, kalender seketika menunjukkan **"Tanggal 13 (Hari Ini)"**. Setiap kali dispatcher menekan tombol buat jadwal, jadwal seketika dicetak untuk hari ini, dan jam hitung mundur menghitung detik demi detik keberangkatan secara akurat dan tepat waktu.

---

### B. Analogi Babak Pertandingan Olahraga (Bug Denominator Ritase)
Bayangkan seorang atlet lari yang mengikuti lomba estafet 3 putaran. Karena masuk sebagai pelari pengganti di tengah pertandingan, atlet tersebut mulai berlari pada **Putaran ke-2**.
- **Sebelum Perbaikan:** Di layar monitor stadion, panitia menuliskan: *"Atlet sedang berlari di Putaran 2/3"*. Penonton mengira putaran ketiga adalah putaran terakhir dari total lomba. Padahal target yang harus diselesaikan atlet adalah 3 putaran penuh yang berakhir di **Putaran ke-4**! Atlet dan penonton menjadi bingung karena angka penyebut di papan skor tidak cocok dengan batas garis finish yang sebenarnya.
- **Setelah Perbaikan:** Papan skor kini cerdas membaca nomor garis finish target: *"Atlet sedang di Putaran 2 dari 4 (Putaran 2/4)"*, lalu berlanjut ke *"Putaran 3/4"*, dan puncaknya di *"Putaran 4/4"*. Dispatcher dan pengemudi langsung tahu dengan tegas bahwa dinas mereka akan tuntas tepat di ritase ke-4.

---

## 2. Perbandingan Situasi Sebelum vs Sesudah Perbaikan

| Aspek Operasional | Sebelum Perbaikan | Sesudah Perbaikan |
|---|---|---|
| **Tanggal Pembuatan Jadwal** | Terkunci pada tanggal lama di database kemarin karena ketiadaan date picker manual. | Otomatis sinkron dengan tanggal operasional hari ini saat aplikasi dibuka maupun saat generate. |
| **Countdown Waktu Berangkat** | Countdown rusak (menghitung mundur/overdue dari 24 jam yang lalu). | Countdown presisi real-time hingga detik keberangkatan armada hari ini. |
| **Alarm Keberangkatan (HUD/TTS)** | Tidak berbunyi karena seluruh antrean dianggap sudah lewat kemarin. | Berbunyi tepat waktu sesuai interval bersiap (*prep*) dan jam berangkat (*due*). |
| **Pesan Banner Jadwal** | *"Jadwal bertanggal X. Tanggal pilihan: Y"* (Membingungkan karena tidak ada date picker). | *"Jadwal tersimpan bertanggal X (hari sebelumnya). Silakan buat jadwal baru untuk hari ini (Y)."* |
| **Pill Telemetri Ritase Lanjutan** | Menampilkan `"Ritase 2/3"` (hanya menampilkan jumlah putaran tanpa menghitung rit awal). | Menampilkan `"Ritase 2/4"` secara presisi (mencerminkan rit ke-2 menuju rit finish ke-4). |

---

## 3. Dampak Langsung bagi Dispatcher di Lapangan

1. **Kepercayaan Total pada Countdown HUD**: Dispatcher tidak lagi dikagetkan oleh timer merah aneh yang minus puluhan jam. Jam keberangkatan di layar kembali dapat dipercaya sebagai acuan keberangkatan armada.
2. **Kesesuaian Ritase Dinas Riil**: Dispatcher yang menyusun jadwal di shift siang (misal mulai dari ritase 2 sebanyak 3 rit) dapat memantau armada dengan tenang karena nomor putaran target tercantum jelas (`Ritase 2/4`, `3/4`, `4/4`), sejalan dengan Surat Perintah Jalan (SPJ) pengemudi di lapangan.
3. **Pengalaman Bebas Hambatan (Zero-Friction)**: Dispatcher tidak perlu memusingkan tanggal sama sekali. Aplikasi cukup dibuka, armada disesuaikan, tombol "Buat Jadwal" ditekan, dan sistem langsung siap bekerja mengawal operasional mikrotrans.
