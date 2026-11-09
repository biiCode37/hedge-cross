# Analogi dan Dampak Non-Teknis: Suara TTS Mandiri & Bebas Distorsi

## 1. Analogi Dunia Nyata: "Radio Meja vs Pengeras Suara Komando Terminal"

Bayangkan sebuah pos pantau dispatcher di terminal bus:

- **Kondisi Sebelum Perbaikan:**
  Hanya ada satu corong pengeras suara di pos. Jika dispatcher mengecilkan volume corong itu menjadi 30% untuk memutar siaran radio lagu santai agar pos tidak berisik, maka ketika ada panggilan darurat jadwal keberangkatan armada (*"Rute JAK 115 unit 1865 berangkat!"*), suara panggilan darurat tersebut ikut keluar dari corong yang sama dengan volume 30% yang pelan. Akibatnya, pengemudi di lapangan parkir tidak mendengar panggilan tersebut dan ritase terlambat.

- **Kondisi Sesudah Perbaikan (3 Pilar Harmonis):**
  Pos kini memiliki dua perangkat terpisah:
  1. **Radio Meja (Saluran Media/Musik):** Memutar lagu favorit dispatcher dengan volume santai dan tenang.
  2. **Sirine & Megafon Komando (Saluran Alarm Mandiri HEDGE):** Tergantung di tiang luar dengan amplifier berkekuatan penuh.
  3. **Peredam Otomatis (*Ducking*):** Begitu megafon komando hendak mengumumkan jadwal keberangkatan armada, radio meja secara otomatis mengecilkan volumenya sejenak. Megafon berbicara dengan lantang di level maksimal (100%), lalu setelah selesai, volume radio meja kembali normal.

---

## 2. Tabel Perbandingan Sebelum vs Sesudah

| Aspek Operasional | Sebelum Perbaikan | Sesudah Perbaikan |
|---|---|---|
| **Saluran Suara Audio** | Menumpang di `STREAM_MUSIC` (Saluran Media lagu). | Berdiri mandiri di `STREAM_ALARM` (Saluran Jam Alarm Android). |
| **Ketergantungan Musik** | Terikat 100%. Jika musik pelan (30%), suara TTS ikut pelan (30%). | Bebas merdeka. Musik disetel pelan (20%–40%), TTS tetap menggelegar di level 100%. |
| **Peredaman Lagu Otomatis** | Tidak efektif; suara TTS dan vokal lagu sering bertabrakan. | *Audio Ducking* aktif; musik otomatis meredam drastis saat alarm bicara, lalu pulih mulus. |
| **Jaminan Suara Maksimal** | Tidak ada; jika volume HP sedang kecil, panggilan tidak terdengar. | *Auto-Boost & Auto-Restore*; HEDGE otomatis menaikkan ke 100% saat bicara dan memulihkan setelan semula. |
| **Transparansi Status di UI** | Hanya menampilkan satu angka volume umum yang membingungkan. | Menampilkan volume Alarm TTS dan volume Media Musik secara jelas dan terpisah. |

---

## 3. Dampak Langsung bagi Dispatcher dan Pramudi di Lapangan

1. **Kenyamanan Kerja Dispatcher Meningkat:** Dispatcher tidak perlu lagi menahan diri dari memutar musik atau video santai di pos jaga karena khawatir alarm keberangkatan tidak terdengar.
2. **Zero Missed Departures (Nol Ritase Terlewat):** Suara panggilan armada selalu terdengar jelas dan lantang ke area parkir/jalur pengendapan, bahkan saat kondisi terminal sedang bising.
3. **Tanpa Gangguan Volume Ponsel:** Setelah alarm selesai berbicara, volume ponsel dispatcher tidak meledak atau berubah permanen; lagu kembali bermain pada volume nyaman seperti sedia kala.
