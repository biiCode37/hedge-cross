# 04. Analogi & Dampak Non-Teknis — Cockpit MFD Console

Dokumen ini menjelaskan perbaikan antarmuka konfigurasi avionik dalam bahasa analogi non-teknis dunia nyata yang mudah dipahami, perbandingan kondisi sebelum vs sesudah, serta dampak langsung bagi para dispatcher Mikrotrans di lapangan.

---

## 1. Analogi Dunia Nyata: Mesin Ketik Manual vs. Dashboard Kokpit Pesawat Modern

### Sebelum Perbaikan (Ibarat Formulir Kertas & Mesin Ketik Tua)
Bayangkan seorang pengatur lalu lintas penerbangan atau masinis yang ingin mengatur jadwal keberangkatan kereta. Alih-alih memutar kenop jam dinding atau memilih jarum jam digital, dia disodori formulir ketik manual di mana dia harus mengetik karakter demi karakter: angka `0`, angka `5`, tanda titik dua `:`, dan angka `0`, `0`. Jika jarinya terselip menekan titik koma `;` atau spasi, formulir itu ditolak mentah-mentah. Ditambah lagi, seluruh aturan jadwal dari pagi sampai malam, sirine stasiun, hingga alarm darurat dicetak bersambung dalam satu gulungan kertas panjang yang harus digulung naik-turun secara melelahkan di bawah terik matahari.

### Sesudah Perbaikan (Dashboard Kokpit MFD Modern)
Kini, konsol konfigurasi diubah menjadi **Multi-Function Display (MFD) Kokpit Digital**:
1. **Pemilih Jam Visual (Visual Dial):** Seperti jam arloji digital pintar—cukup ketuk kartu jam, lalu lingkaran dial 24 jam elegan muncul. Dispatcher tinggal menyentuh angka jam dan menit yang diinginkan dengan satu sentuhan ujung jari. Tidak ada lagi mengetik titik dua `:` manual, tidak ada lagi salah ketik format.
2. **Tombol Stepper Digital (`[-]` dan `[+]`):** Untuk mengubah interval headway armada dari 10 menit ke 12 menit, dispatcher cukup mengetuk tombol `[+]` dua kali dengan jempol, persis seperti mengatur volume radio mobil. Keyboard virtual yang biasanya menutupi layar kini tidak perlu muncul lagi.
3. **Panel 3 Segmen Terfokus:** Layar dibagi menjadi 3 tombol tab tugas yang rapi:
   - **OPERASIONAL:** Mengatur jam dinas dan jarak waktu armada reguler.
   - **PEAK HOURS:** Khusus mengatur jam sibuk pagi dan sore.
   - **DISPATCH ALARM:** Khusus mengatur nada alarm, durasi sirine, dan toleransi keterlambatan.

---

## 2. Perbandingan Kondisi Sebelum vs. Sesudah Perbaikan

| Parameter | Kondisi Sebelum (Form Lama) | Kondisi Sesudah (Cockpit MFD) |
|---|---|---|
| **Input Jam Operasional** | Mengetik teks manual angka dan titik dua `:` | Mengetuk kartu telemetri yang membuka **Dial Jam 24 Format Visual** |
| **Resiko Human Error (Typo)** | Tinggi (salah ketik titik dua, spasi, atau format jam) | **Nol** (dipilih langsung dari dial angka jam valid) |
| **Pengaturan Interval Menit** | Keyboard numerik virtual menutupi separuh layar ponsel | **Tombol Stepper Digital `[-]` dan `[+]`** (ramah satu jempol di lapangan) |
| **Navigasi Form** | Scroll vertikal monolitik panjang yang melelahkan | **3 Segmen MFD Modular** (`OPERASIONAL`, `PEAK HOURS`, `DISPATCH ALARM`) |
| **Quick Preset Chips** | Tidak ada pembersihan / menu menumpuk | **Dihapus tuntas** agar antarmuka bersih, fokus, dan tidak membingungkan |
| **Kejelasan Status Alarm** | Deskripsi membingungkan menyebut alert terpisah | **Deskripsi terpadu** menegaskan alert cockpit universal |

---

## 3. Dampak Langsung bagi Dispatcher Mikrotrans di Lapangan

1. **Kecepatan Setting di Lapangan Naik Drastis:**
   - Mengubah parameter saat pergantian shift dinas (misal dari headway normal 12 menit ke 8 menit) kini hanya butuh beberapa detik tanpa harus berurusan dengan keyboard layar sentuh yang sering *misstype*.
2. **Kenyamanan Operasi dengan Satu Tangan (Thumb-First):**
   - Dispatcher sering memegang smartphone dengan satu tangan sambil memegang papan jalan atau berkomunikasi dengan pengemudi mikrotrans. Tombol stepper besar `[-]` dan `[+]` serta ubin dial jam dapat dijangkau dan dioperasikan dengan mudah menggunakan satu jempol.
3. **Bebas Gangguan Keyboard Menutupi Tombol Simpan:**
   - Pada ponsel layar kecil berukuran 360dp, keyboard numerik sering kali menutupi tombol *"Terapkan Parameter"*. Dengan stepper digital, keyboard tidak perlu muncul sehingga tombol simpan tetap terlihat jelas.
4. **Tampilan Profesional Cyber-Transit:**
   - Nuansa warna gelap Obsidian dengan aksen Cyan dan Amber memberikan keterbacaan tinggi di bawah sinar matahari langsung di terminal, sekaligus terlihat modern dan selaras dengan identitas HEDGE.
