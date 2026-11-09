# Analogi dan Dampak Non-Teknis: Papan Keberangkatan Bersih & Informasi Pramudi Siap Jalan

## 1. Analogi Dunia Nyata: "Papan Informasi Bandara (FIDS) yang Rapi dan Tertata"

Bayangkan sebuah layar monitor raksasa jadwal penerbangan di ruang tunggu bandara:

- **Kondisi Sebelum Perbaikan:**
  Pada setiap baris penerbangan, ada tulisan statis "STANDBY" berulang-ulang tanpa memberi tahu siapa pilotnya. Di sebelah nomor penerbangan yang dicetak besar, ditempel stiker nama pilot yang terlalu panjang sehingga stiker itu menutupi angka jam keberangkatan di sebelahnya. Cahaya neon di tiang pembatas juga terlalu silau dan tumpah ke angka jam di sebelah kiri, membuat penumpang dan petugas pusing melihat baris demi baris yang saling bertumpuk dan berantakan.

- **Kondisi Sesudah Perbaikan:**
  Layar kini tertata rapi seperti monitor bandara modern:
  1. **Pilot/Pramudi Langsung Terlihat:** Kata "STANDBY" yang monoton diganti dengan nama jelas sang kapten/pramudi (misal: `[ 👤 Munif ]`, `[ 👤 Dede ]`, `[ 👤 Rahmat ]`).
  2. **Hero Boarding yang Berwibawa:** Di bagian atas, nomor pesawat utama didampingi nama pramudi yang bertugas dengan badge bercahaya di atas lingkaran waktu.
  3. **Zero Overlap (Nol Tumpang Tindih):** Nomor unit berdiri bebas dan gagah, terpisah dari kolom hitung mundur dengan jarak yang pas dan lega.
  4. **Pendaran Cahaya Presisi:** Tiang linimasa bercahaya tajam dan elegan tanpa menyilaukan teks jam di sisi kirinya.

---

## 2. Tabel Perbandingan Sebelum vs Sesudah

| Aspek Tampilan | Sebelum Perbaikan | Sesudah Perbaikan |
|---|---|---|
| **Label Status Armada** | Tertulis `STANDBY` berulang-ulang, tidak ada nama pramudi di posisi ini. | Menampilkan nama Pramudi (`[ 👤 Munif ]`, `[ 👤 Dede ]`) menggantikan label monoton. |
| **Komponen Utama (Keberangkatan Berikutnya)** | Hanya nomor unit dan jam; nama pramudi tidak muncul di kartu atas. | Nama pramudi tampil jelas dan futuristik tepat di bawah nomor kode unit dan di atas lingkaran *countdown*. |
| **Kolom Hitung Mundur** | Tertindih dan tertabrak badge nama supir yang meluber dari kolom tengah. | Bersih 100%, dialokasikan lebar lega 80px, angka dan teks `HITUNG MUNDUR` terbaca jernih. |
| **Pendaran Rel & Sisi Kiri** | Pendaran blur tumpah (*bleeding*) menutupi teks jam dan nomor armada; jarak sempit. | Node rel terkunci presisi (blur 3px), kolom waktu diperlebar, teks jam & rute bernapas lega. |
| **Header Kolom** | `ARMADA · STATUS` | `ARMADA · PRAMUDI` (selaras sempurna dengan data yang ditampilkan). |

---

## 3. Dampak Nyata bagi Dispatcher dan Operasional Lapangan

1. **Visibilitas Instan:** Dispatcher sekali melirik ke Papan HEDGE langsung tahu unit mana yang akan jalan dan siapa nama pramudi yang memegang kemudi, tanpa perlu membuka menu edit jadwal atau mencari manifes kertas.
2. **Kenyamanan Membaca dari Jauh:** Dalam jarak pandang 2–3 meter di pos pantau/kiosk, tata letak yang rapi dan bebas tumpang tindih membuat dispatcher tidak lelah mata membaca giliran armada.
3. **Koordinasi Lebih Cepat:** Saat countdown mendekati 00:00, dispatcher bisa langsung memanggil nama pramudi bersangkutan dengan cepat dan akurat.
