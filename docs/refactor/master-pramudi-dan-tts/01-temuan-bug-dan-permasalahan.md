# Temuan Masalah & Latar Belakang: Master Data Pramudi, Penugasan Shift & Integrasi Suara Alarm TTS

## 1. Konteks Masalah
Sebelum pembaruan arsitektur ini, aplikasi **HEDGE (Headway Generator By Mikrotrans Utara)** mengelola jadwal headway bus kecil Mikrotrans (JakLingko) murni berbasis nomor bodi armada unit (`FleetUnit`). Setiap kartu armada hanya menampilkan status aktif/tidak aktif dan nomor kendaraan (misal `540`, `0865`), tanpa memiliki asosiasi terhadap siapa pengemudi (pramudi) yang bertugas di balik kemudi.

Dalam realitas operasional harian operator Mikrotrans di DKI Jakarta:
1. **Sistem 2 Shift per Unit (Tandem Shift):**
   - Satu armada unit mikrotrans dioperasikan oleh 2 pramudi dalam satu hari operasional:
     - **Shift 1 (Pagi):** Mulai dinas pagi (~05:00) hingga jam pergantian (aplusan).
     - **Shift 2 (Siang):** Mulai dinas aplusan hingga penutupan layanan malam (~22:00).
2. **Waktu Aplusan Independen per Rute (*Route-Specific Aplusan*):**
   - Jam pergantian shift pramudi tidak seragam di seluruh DKI Jakarta. Setiap trayek/rute memiliki waktu aplusan yang berbeda-beda tergantung jarak tempuh rit, titik pangkalan pengendapan, dan kepadatan lalu lintas (misal rute JAK.115 aplusan pukul 13:00, sedangkan rute lain pukul 13:30 atau 14:00).
3. **Fleksibilitas & Rolling Shift Rutin:**
   - Jadwal dinas pramudi mengalami *rolling* bergantian secara periodik (setiap 1 atau 2 minggu). Pramudi pagi bertukar menjadi pramudi siang, dan sebaliknya. Tanpa mekanisme rolling cepat, dispatcher harus mengubah penugasan satu per satu yang sangat memakan waktu.
4. **Panggilan Alarm TTS Tanpa Nama Supir:**
   - Suara pengumuman alarm otomatis pos pantau (*Text-to-Speech*) hanya melafalkan nomor armada (`{unit}`), tanpa menyebut nama pramudi. Di pangkalan terminal yang bising, supir sering kali tidak sadar bahwa gilirannya telah tiba karena mereka lebih terbiasa dan responsif dipanggil menggunakan nama sapaan akrabnya.
5. **Redundansi Visual Subtitle:**
   - Pada kartu armada di Halaman 02 Armada, terdapat teks statis `"Aktif untuk jadwal baru"` yang memakan vertikal layar smartphone secara mubazir dan tidak memberikan nilai informatif bagi dispatcher di lapangan.

---

## 2. Analisis Titik Kegagalan & Kebutuhan Teknis

### A. Ketiadaan Struktur Data Entitas Driver
Model domain `models.dart` belum memiliki representasi entitas `Driver` dengan status dinas (`tetap` vs `cadangan`) serta relasi slot shift (`driverShift1Id` & `driverShift2Id`) pada `FleetUnit`. Database Supabase `hedge-cross` juga belum memiliki tabel penyimpanan master pramudi rute.

### B. Otomasi Penugasan Supir di Engine Penjadwalan
Mesin generator jadwal `Scheduler.generate()` dan penyesuaian dinamis `replan()` sebelumnya memetakan `Departure` tanpa mengidentifikasi apakah jam keberangkatan tersebut masuk kategori shift pagi atau shift siang. Ketiadaan logika perbandingan terhadap jam aplusan rute (`shiftChangeTime`) menyebabkan jadwal tidak mengetahui pramudi mana yang sedang aktif bertugas pada menit tersebut.

### C. Jebakan Sintaks Komparasi Waktu (*Time Comparison Pitfall*)
Waktu keberangkatan dihitung dalam menit sejak tengah malam (`minuteOfDay`), sementara waktu aplusan disimpan dalam format string waktu `"HH:mm"`. Jika penugasan shift hanya membandingkan string secara leksikografis atau tidak mem-parsing jam aplusan secara konsisten, armada yang diberangkatkan pasca aplusan dapat salah memanggil supir pagi.

### D. Tantangan Sanitasi Variabel `{pramudi}` & Fallback Cerdas di Android Kotlin
Ketika variabel `{pramudi}` ditambahkan pada template teks alarm (misal: `"Unit {unit}, {pramudi}, saatnya berangkat."`), terdapat kondisi di mana slot supir belum ditugaskan (string kosong).
- Penggantian naif string kosong menghasilkan teks: `"Unit 540, , saatnya berangkat."`.
- Tanda baca koma ganda `, ,` atau koma gantung di awal/tengah menyebabkan mesin Android Text-to-Speech (TTS) terhenti sesaat (*awkward pause*) atau menghasilkan pelafalan jeda yang janggal dan tidak natural di pengeras suara.

---

## 3. Akar Masalah Teknis (Root Causes)
1. **Model Domain Minimalis:** `FleetUnit`, `PlanConfig`, dan `Departure` belum mengakomodasi atribut supir dan konfigurasi jam aplusan per rute.
2. **Ketiadaan UI Manajemen Kru di Cockpit:** Belum ada modal lembar kerja untuk mengelola master supir (tambah, edit, status tetap/cadangan, filter supir).
3. **Ketiadaan Fitur Swap & Rolling Cepat:** Tidak ada tombol cepat `⇄` untuk menukar supir pada tingkat unit armada individual maupun tombol massal rolling shift se-rute.
4. **Android Native TTS Tidak Mengenali Variabel Supir:** `AlarmSpeechText.kt` dan `AlarmSpec` hanya mengenali tag `{unit}` dan `{detik}`.
