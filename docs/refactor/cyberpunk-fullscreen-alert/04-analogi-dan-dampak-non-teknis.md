# 04. Analogi & Dampak Non-Teknis — Cyberpunk Telemetry Cockpit Fullscreen Alert

Dokumen ini memuat analogi dunia nyata non-teknis, komparasi situasi sebelum vs sesudah perbaikan, dan dampak operasional langsung bagi dispatcher mikrotrans di lapangan.

---

## 1. Analogi Dunia Nyata: "Kokpit Pesawat Tempur vs Stiker Kertas di Dinding Kosong"

Bayangkan seorang pilot jet tempur yang sedang bersiap lepas landas dari kapal induk:
- **Sebelum Perbaikan (Stiker di Dinding Kosong):**
  Di tengah dashboard pesawat yang luas dan canggih, informasi peluncuran hanya ditempelkan pada selembar stiker kecil di pojok atas dinding kokpit, sementara tombol kemudi diletakkan jauh di bawah lantai. Ruang tengah dashboard dibiarkan kosong melompong. Saat sirene berbunyi, sang pilot harus menyipitkan mata untuk membaca tulisan kecil pada stiker tersebut, dan kebingungan apakah ada tombol untuk menunda alarm tanpa harus mematikan seluruh mesin jet.
- **Sesudah Perbaikan (Kokpit Telemetri Cyberpunk):**
  Seluruh dashboard kokpit kini menyala dengan panel instrumen HUD modern. Di tengah pandangan langsung mata pilot, terpampang radar melingkar besar berputar (*giant chrono-dial radar*) dengan angka waktu tebal yang menghitung mundur detik demi detik. Nomor panggilan pesawat (*Unit Identifier*) menyala besar di atasnya, diapit oleh 3 kotak telemetri presisi: Jam Penerbangan, Jalur Misi, dan Putaran Tugas. Tepat di bawah jempol tangan kanan tersedia tombol peluncuran amber menyala, tombol penutup layar sekunder, dan sakelar mesin darurat. Tidak ada ruang kosong yang terbuang sia-sia; setiap piksel memberikan informasi operasional yang jernih, tegas, dan membangkitkan rasa percaya diri.

---

## 2. Tabel Komparasi Situasi: Sebelum vs Sesudah

| Aspek | Sebelum Perbaikan (v2.0.8) | Sesudah Perbaikan (v2.0.9 Cockpit HUD) |
| :--- | :--- | :--- |
| **Pemanfaatan Layar** | Kartu kecil mengambang di atas, tombol di bawah, ada jurang kosong ~250–300dp (*blank space*). | Terstruktur padat dan proporsional menyerupai kokpit instrumen penerbangan (*zero wasted space*). |
| **Keterbacaan Armada** | Nomor unit berukuran standar dan mudah luput dari pandangan sekilas. | Monolith Unit 72sp bold menyala, terlihat jelas dari jarak 50–100 cm. |
| **Visualisasi Countdown** | Angka digital standar tanpa elemen dial radar. | Giant Chrono-Dial Radar 220dp dengan 12 tick radial & busur timeout dinamis. |
| **Informasi Misi** | Tertulis menyatu dalam satu baris teks kecil. | 3 Kartu Telemetri Mandiri bergaya HUD: `JADWAL` WIB, `RUTE`, `PUTARAN RITASE`. |
| **Ergonomi Aksi** | Tidak ada tombol tutup sementara (hanya berangkat & matikan rute). | Dilengkapi tombol *✕ Tutup Alert* ergonomis dan tombol utama gradien Amber glow 48px. |
| **Konsistensi Platform** | Lapisan native Android berbeda model dengan lapisan Flutter. | Lapisan Flutter dan native Android 100% konsisten mengadopsi radar dial 200dp & 3 telemetri box. |

---

## 3. Dampak Operasional bagi Dispatcher di Lapangan

1. **Kecepatan Respon Dispatcher:**
   Dispatcher tidak perlu lagi memfokuskan pandangan secara teliti ke layar HP yang diletakkan di meja atau dasbor; nomor unit dan sisa waktu detik langsung terbaca secara instan.
2. **Nol Salah Pencet (Zero Accidental Route Shutdown):**
   Tombol *Tutup Alert* sementara menghilangkan risiko rute mati seharian akibat dispatcher salah menekan *Matikan alarm rute*.
3. **Kepuasan & Kebanggaan Pengguna (Aesthetic Wow-Factor):**
   Nuansa visual Cyber-Transit HUD yang kohesif antara halaman Jadwal, Papan HEDGE, dan Alert Keberangkatan memberikan pengalaman aplikasi transit profesional kelas dunia yang modern, canggih, dan menyenangkan untuk digunakan sepanjang hari.
