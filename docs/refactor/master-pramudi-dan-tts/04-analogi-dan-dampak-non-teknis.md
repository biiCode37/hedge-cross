# Analogi & Dampak Non-Teknis: Master Data Pramudi, Penugasan Shift & Integrasi Suara Alarm TTS

## 1. Analogi Dunia Nyata

### *Papan Gantungan Kunci Armada & Petugas Pengeras Suara Terminal*

Bayangkan sebuah pos pantau terminal Mikrotrans tradisional:
- **Sebelum Perbaikan:** Di dinding pos pantau hanya ada deretan paku gantungan kunci bertuliskan nomor armada: "540", "001", "1865". Petugas pengeras suara hanya berteriak: *"Mobil lima ratus empat puluh, siap-siap jalan!"*. Para supir yang sedang ngopi atau istirahat di warung terminal sering kali tidak mendengarkan atau lupa nomor lambung mobilnya hari itu, sehingga jadwal sering terlambat diberangkatkan. Selain itu, petugas tidak mencatat siapa supir pagi dan siapa supir siang; saat aplusan tiba di siang hari, pos pantau menjadi kacau karena tidak tahu siapa yang harus menggantikan siapa.
- **Sesudah Perbaikan:** Sekarang, di setiap gantungan kunci nomor armada terdapat **dua label gantungan nama supir**: label **☀️ Pagi** (misal: "Bambang") dan label **🌙 Siang** (misal: "Rudi"). Petugas pengeras suara otomatis memanggil langsung nama orangnya: *"Unit lima ratus empat puluh, Mas Bambang, saatnya berangkat!"*. Begitu jam aplusan tiba pukul 13:00, petugas cukup melihat sistem yang secara otomatis telah membalik jadwal ke nama supir siang tanpa perlu ditebak-tebak. Ketika jadwal mingguan di-rolling, petugas cukup menekan satu tuas, dan seluruh gantungan nama bertukar posisi secara instan!

---

## 2. Tabel Komparasi: Sebelum vs. Sesudah Perbaikan

| Aspek Operasional | Sebelum Perbaikan (Old HEDGE) | Sesudah Perbaikan (New HEDGE) |
| :--- | :--- | :--- |
| **Identitas Armada** | Hanya nomor bodi kendaraan (misal `540`). | Terikat dengan 2 slot pramudi tandem: **Shift 1 (Pagi)** dan **Shift 2 (Siang)**. |
| **Waktu Aplusan (Pergantian)** | Tidak ada konsep aplusan; jadwal tidak mengenal pergantian shift. | Didukung waktu aplusan independen per rute (`shiftChangeTime`, misal 13:00, 13:30). |
| **Suara Alarm TTS** | Hanya menyebut nomor mobil: *"Unit 540, saatnya berangkat."* | Cerdas memanggil nama supir bertugas: *"Unit 540, Bambang, saatnya berangkat."* |
| **Fallback Saat Supir Kosong** | Template kustom dengan supir kosong melafalkan jeda koma janggal: *"Unit 540, , saatnya berangkat."* | Otomatis disanitasi bersih tanpa koma ganda: *"Unit 540, saatnya berangkat."* |
| **Tukar Supir per Unit** | Harus mengedit jadwal secara manual di luar aplikasi. | Tombol cepat satu sentuhan **`⇄`** langsung menukar supir pagi $\leftrightarrow$ siang pada unit terkait. |
| **Rolling Shift Massal** | Tidak ada. Dispatcher harus mengubah puluhan data supir satu demi satu. | Tombol **`Rolling Shift`** di header armada langsung menukar supir seluruh unit se-rute dalam 1 detik. |
| **Visual Kartu Armada** | Memuat teks subtitle mubazir: *"Aktif untuk jadwal baru"*. | Teks mubazir dihapus; digantikan bar supir tandem interaktif yang modern dan informatif. |
| **Manajemen Master Supir** | Tidak ada lembar kerja supir. | Lembar kerja terpusat **`DriverMasterSheet`** dengan filter supir **Tetap** vs **Cadangan**. |
| **Sinkronisasi Cloud** | Hanya unit dan rute. | Tabel Supabase `master_drivers` otomatis tersinkronisasi ke server pusat. |

---

## 3. Dampak Langsung bagi Pengguna Lapangan

### A. Bagi Dispatcher di Pos Pantau
1. **Ergonomi Jempol Cepat (*Thumb-Friendly*):**
   - 90%+ dispatcher menggunakan smartphone Android satu tangan sambil memegang radio HT atau papan jalan. Tombol swap `⇄` dan rolling shift massal menghemat ratusan ketukan jari setiap minggunya.
2. **Nol Salah Panggil Saat Aplusan:**
   - Tidak ada lagi insiden salah panggil nama supir yang sudah pulang dinas. Sistem secara otomatis mengganti nama panggilan begitu waktu keberangkatan melewati jam aplusan rute.
3. **Layar Bersih & Padat Informasi:**
   - Dihapuskannya teks redundan `"Aktif untuk jadwal baru"` memberikan ruang bagi informasi penting yang benar-benar dibutuhkan: nomor unit, operator, dan nama supir tandem.

### B. Bagi Pramudi Mikrotrans di Lapangan
1. **Panggilan Lebih Personal & Cepat Respons:**
   - Di tengah kebisingan knalpot dan klakson terminal, supir jauh lebih sensitif mendengar nama sapaan akrabnya (`callName`) dibandingkan sekadar nomor angka lambung mobil.
2. **Kepastian Dini Giliran Bertugas:**
   - Supir cadangan maupun supir tetap memiliki kejelasan penugasan sejak pagi hari melalui papan monitor keberangkatan pos pantau.

### C. Bagi Ketepatan Headway & Kualitas Layanan Publik
- Mengurangi *dispatch lag* (keterlambatan armada meninggalkan pangkalan) hingga 30–60 detik per rit.
- Headway Mikrotrans JakLingko menjadi lebih teratur, interval kedatangan bus di halte penumpang lebih presisi, dan keteraturan layanan angkutan umum massal Jakarta semakin meningkat.
