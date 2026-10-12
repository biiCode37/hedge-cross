# 01. Temuan Bug & Permasalahan — Keterbatasan Form AVIONICS CONFIG & Input Jam Manual

Dokumen ini memuat analisis mendalam mengenai akar masalah (*root cause*), aliran data (*data flow*), dan kondisi kendala ergonomi dari antarmuka konfigurasi operasional armada (`AVIONICS CONFIG` / [`ConfigurationSheet`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart)) pada HEDGE (Headway Generator).

---

## 1. Ringkasan Eksekutif Temuan

Sebelum dilakukan rekonstruksi, panel konfigurasi sistem HEDGE ([`ConfigurationSheet`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart)) memiliki sejumlah kelemahan struktural dan ergonomis yang kontras dengan filosofi *Cyberpunk Cockpit HUD* aplikasi:

1. **Input Jam Manual Primitif (Ketik Angka & Titik Dua `:`):**
   - Pemilihan jam mulai dan jam selesai operasi (`startHour` dan `endHour`) mengharuskan pengguna mengetik string teks secara manual ke dalam field teks (contoh: mengetik `"05:00"` atau `"22:00"`).
   - Pengguna harus berhati-hati mengetik karakter titik dua `:`, yang rentan salah ketik (*typo*), format string tidak valid, atau memicu kegagalan parsing waktu.
   - Tidak ada picker visual atau dial 24 jam interaktif yang memudahkan input cepat di lapangan dengan satu tangan.

2. **Beban Kognitif dari Form Linear yang Terlalu Panjang:**
   - Semua pengaturan (jam dinas, ritme headway, peak hour, audio alert, durasi alarm, batas toleransi, dan target rit) ditumpuk dalam satu scroll vertikal monolitik tanpa pembagian modul kerja yang fungsional.
   - Dispatcher harus menggulir berulang kali untuk mencari pengaturan yang ingin diubah di bawah terik matahari atau saat armada bergerak cepat.

3. **Input Numerik Headway & Toleransi Tanpa Kendali Taktil Satu Jempol:**
   - Nilai headway menit, durasi alarm detik, dan batas toleransi armada mengandalkan keyboard numerik ponsel yang menutupi separuh layar saat aktif.
   - Tidak ada tombol stepper cepat (`[-]` dan `[+]`) untuk menaikkan/menurunkan parameter secara presisi tanpa memunculkan soft keyboard.

4. **Teks Informasi Redundan Pasca-Unifikasi Alert Layar Penuh:**
   - Teks panduan alarm masih merujuk pada konsep ganda *"Layar Penuh (hanya saat aplikasi dibuka)"* yang membingungkan dispatcher, padahal sistem alert fullscreen telah disatukan secara universal.

---

## 2. Analisis Akar Masalah (Root Cause Analysis)

### A. Fragmentasi Parsing Jam String Manual
- Pada arsitektur sebelumnya, input waktu diikat langsung ke text controller yang mem-parsing input regex/substring `HH:mm`.
- Masalah:
  - Validasi error hanya muncul saat form disubmit atau tombol simpan ditekan.
  - Dispatcher di lapangan sering tergesa-gesa; mengetik angka jam dengan keyboard virtual pada layar guncang di dalam kendaraan mikrotrans sangat rawan salah tekan.

### B. Ketiadaan Desain Segmentasi MFD (Multi-Function Display)
- Konsep cockpit avionik modern pada pesawat dan kendaraan tempur membagi instrumen ke dalam panel segmen digital (*Multi-Function Display / MFD*).
- Panel konfigurasi lama tidak memiliki segmentasi tugas (`OPERASIONAL`, `PEAK HOURS`, `DISPATCH ALARM`), sehingga seluruh instrumen bercampur aduk dalam satu halaman panjang.

### C. Kurangnya Kontrol Stepper Ergonomis Lapangan
- Standar kenyamanan dispatcher smartphone Android (aturan AGENTS.md: *thumb-first*, touch-target minimal 44–48px) menuntut adanya tombol aksi fisik digital yang dapat ditekan instan tanpa membuka keyboard Android.
- Field teks polos memaksa sistem operasi menampilkan keyboard virtual, yang sering kali menutupi tombol *"Terapkan Parameter"* di bagian bawah layar.
