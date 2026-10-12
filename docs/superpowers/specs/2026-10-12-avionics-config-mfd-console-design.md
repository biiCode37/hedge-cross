# Spesifikasi Desain: Avionics Config Cockpit MFD Console

**Tanggal:** 2026-10-12  
**Status:** Disetujui (Approved)  
**Tujuan:** Mentransformasi `ConfigurationSheet` (AVIONICS CONFIG) dari formulir vertikal generic berbasis ketik manual menjadi konsol MFD (Multi-Function Display) Cockpit taktis yang ergonomis, memanfaatkan 3 segmen navigasi MFD, komponen pemilih jam (*Time Picker*) profesional dan modern tanpa ketik tanda titik dua `":"` manual, serta pengatur angka berbasis Stepper Digital `[+] / [-]`.

---

## 1. Latar Belakang & Kebutuhan Pengguna

1. **Masalah Input Jam Saat Ini:**
   - Jam mulai dan jam selesai saat ini menggunakan `TextFormField` teks biasa.
   - Dispatcher di lapangan harus mengetik angka dan mencari tanda titik dua `":"` pada keyboard virtual smartphone, yang lambat, rentan salah ketik format (*validation error*), dan tidak profesional.
2. **Masalah Tata Letak Panjang (*Long Scroll*):**
   - Seluruh pengaturan operasional, jam sibuk (*peak hours*), dan alarm menumpuk dalam satu daftar vertikal panjang, memaksa dispatcher menggulir berulang kali untuk menjangkau pengaturan tertentu.
3. **Ketiadaan Kontrol Ramah Jempol (*Thumb-First Steppers*):**
   - Angka ritase dan detik persiapan/durasi diinput via keyboard numerik yang sering menutupi layar bagian bawah (*keyboard overflow*).

---

## 2. Arsitektur & Spesifikasi Solusi

### A. Navigasi 3 Segmen Cockpit MFD
Di bawah header judul `Atur [Rute]`, disediakan selector segmen taktis horizontal:
- **`[1. OPERASIONAL]`**: Pengaturan jam kerja (mulai & selesai), target ritase per unit, dan urutan lambat terlebih dahulu.
- **`[2. PEAK HOURS]`**: Sakelar periode jam sibuk, interval headway menit, dan rentang jam Peak 1 & Peak 2.
- **`[3. ALARM]`**: Preferensi alert layar penuh Cockpit HUD terpadu, notifikasi banner, pengingat sebelum berangkat, durasi timeout, suara TTS, dan getaran.

Dispatcher berpindah kategori secara instan dengan satu sentuhan jempol (*zero unnecessary scroll*).

### B. Komponen Tactical Time Selector (`CockpitTimeTile`)
Menghapus seluruh `TextFormField` waktu manual.
- **Visual Card:** Kartu chamfered futuristik berlatar obsidian (Dark) / sleek white (Light) dengan ikon jam, label deskriptif, dan display waktu digital besar (misal: `06:00 WIB`).
- **Interaksi Profesional:**
  - Mengetuk kartu langsung membuka dialog pemilih waktu 24 jam modern (`showTimePicker` dengan `builder` bertema Cyber-Transit HEDGE, jarum dial neon cyan/amber, `initialEntryMode: TimePickerEntryMode.dial`).
  - Nol pengetikan keyboard virtual; nol pengetikan tanda titik dua `":"`. Nilai waktu terformat otomatis `HH:mm`.

### C. Digital Cockpit Steppers (`[-] VALUE [+]`)
Menggantikan input teks angka dengan kontrol stepper digital:
- **Target Ritase per Unit:**
  - Rentang 1–30, tombol stepper jempol: `[-]`  `12 RITASE`  `[+]`
- **Interval Peak:**
  - Rentang 1–60 menit: `[-]`  `3 MENIT`  `[+]`
- **Persiapan Sebelum Berangkat:**
  - Rentang 1–300 detik: `[-]`  `10 DETIK`  `[+]` (step 5 atau 10 detik).
- **Tutup Alert Otomatis (Timeout):**
  - Rentang 1–300 detik: `[-]`  `20 DETIK`  `[+]` (step 5 atau 10 detik).

*(Catatan: Sesuai arahan pengguna, Quick Preset Chips ditiadakan agar antarmuka tetap bersih, rapi, dan tidak sesak).*

### D. Penyelarasan Informasi Alert Terunifikasi
- Memperbarui teks penjelasan alert layar penuh:
  - *"Dialog HUD Cyberpunk layar penuh muncul otomatis baik saat aplikasi aktif maupun saat membuka aplikasi lain."*
- Merapikan sakelar taktis dengan visual kontras ganda (Dark/Light mode).

---

## 3. Rencana Pengujian & Kriteria Keberhasilan

1. **Uji Validasi Form:** Jam selesai harus setelah jam mulai tetap divalidasi dengan pesan ramah.
2. **Uji Widget Test:** Seluruh test suite `test/alarm_test.dart` (termasuk tes `Configuration saves alarm controls without rebuilding schedule`) dan seluruh test aplikasi (75/75) tetap PASS.
3. **Uji Dual Theme:** Tampilan dan dialog time picker tampil sempurna pada tema Dark (`#070B12`) dan Light (`#F8FAFC`).
