# Spesifikasi Desain: Kustomisasi Template Kalimat Suara TTS Cerdas Berbasis Konteks

**Tanggal:** 2026-10-17  
**Status:** Disetujui (Approved)  
**Tujuan:** Memberikan kendali penuh kepada pengguna/dispatcher untuk menentukan format kalimat Text-To-Speech (TTS) alarm keberangkatan, menyederhanakan pelafalan agar ringkas dan padat, serta mengotomasi penghilangan penyebutan rute pada titik pengendapan tunggal (1 rute).

---

## 1. Latar Belakang & Masalah

Pada versi saat ini, kalimat TTS yang dibacakan oleh HEDGE bersifat *hardcoded*:
- **Tahap Persiapan (*Prep*):** `"Segera berangkat, Rute {rute}, unit {unit}, berangkat dalam {detik} detik."`
- **Tahap Keberangkatan (*Due*):** `"Rute {rute}, unit {unit}, saatnya berangkat."`

Hal ini menimbulkan kendala di lapangan:
1. **Terlalu Panjang & Bertele-tele:** Di pos pantau yang sibuk, dispatcher hanya membutuhkan sinyal audio yang cepat, tegas, dan padat. Kalimat yang panjang berisiko terpotong atau tumpang tindih.
2. **Redundansi pada Pengendapan 1 Rute:** Pada pos pengendapan yang hanya mengoperasikan satu rute tunggal, menyebutkan nama/kode rute berulang kali adalah mubazir karena seluruh armada di lokasi tersebut berasal dari rute yang sama.
3. **Nama Rute Panjang:** Jika nama rute memuat deskripsi lintasan (misal `"JAK.115 — Terminal Tanjung Priok - Pegangsaan Dua"`), TTS membacakan seluruh teks tersebut jika tidak dipangkas.
4. **Nomor Bodi Panjang (>4 Digit):** Beberapa armada memiliki prefix operator atau kode seri panjang (misal `"MJU-01865"`), padahal dispatcher hanya mengenali dan memanggil **4 digit terakhir** dari nomor bodi tersebut.
5. **Ketiadaan Opsi Kustomisasi:** Pengguna tidak dapat menyesuaikan kata pembuka atau penutup sesuai budaya komunikasi pos pantau lokal (misal: kata *"jalan!"*, *"siap-siap"*, dsb.).

---

## 2. Aturan Tag Variabel & Format Suara Cerdas

### A. Daftar Tag Variabel yang Didukung
| Tag | Keterangan & Sumber Data | Contoh Hasil Pelafalan |
| :--- | :--- | :--- |
| **`{rute}`** | **Kode Rute Murni Ringkas** (bukan deskripsi panjang).<br>⚡ **Auto-Context:** Jika dalam jadwal hari itu hanya ada **1 rute aktif** yang berpartisipasi, tag ini otomatis **kosong/hening**. Jika ada $\ge 2$ rute aktif, membacakan kode rute. | Multirute: *"JAK 115"* atau *"JAK tujuh enam"*<br>1 Rute: *hening* |
| **`{unit}`** | **4 Digit Terakhir Nomor Bodi**. Mengambil 4 digit angka terakhir dari nomor lambung armada dan melafalkannya dengan kaidah cerdas belasan/puluhan khas radio HT dispatcher. | Unit `1865` $\rightarrow$ *"delapan belas enam lima"*<br>Unit `002213` $\rightarrow$ *"dua dua tiga belas"*<br>Unit `MJU-1870` $\rightarrow$ *"delapan belas tujuh puluh"* |
| **`{detik}`** | **Sisa Hitung Mundur Detik** (khusus alert persiapan). Dihitung *real-time* saat alarm berbunyi: `(departureAt - now + 999) / 1000`. | *"10 detik"*, *"7 detik"* |
| **`{jam}`** | **Jam Rencana Keberangkatan (WIB)**. Format jam dan menit alami. | *"tujuh lewat lima belas"* |
| **`{ritase}`** | **Angka Putaran / Ritase**. Diambil dari field `round` jadwal. | *"ritase satu"*, *"ritase dua"* |

### B. Aturan Pemrosesan & Sanitasi Kalimat
1. **Ekstraksi Kode `{rute}`:**
   Regex mengekstrak pola kode rute resmi (seperti `JAK\s*[0-9]+[A-Za-z]?` atau mengambil segmen sebelum tanda strip/pemisah `—`). Teks deskripsi rute di belakangnya dibuang.
2. **Ekstraksi 4 Digit `{unit}`:**
   Sistem mencari deretan angka pada nomor bodi dan mengambil maksimal 4 digit terakhir. Jika nomor bodi kurang dari 4 digit (misal armada perintis `"630"` atau `"01"`), seluruh digit diproses tanpa error.
3. **Pembersihan Whitespace & Tanda Baca:**
   Ketika `{rute}` kosong pada mode 1 rute, kalimat seperti `"{rute}, unit {unit}, jalan!"` otomatis dibersihkan dari spasi ganda, koma di awal kalimat, atau tanda titik yatim menjadi `"Unit {unit}, jalan!"`.

---

## 3. Desain Antarmuka Pengguna (UI/UX)

Pengaturan format kalimat suara ditempatkan pada halaman [lib/ui/configuration.dart](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart) di dalam kartu konfigurasi alarm, tepat di bawah sakelar *Suara alarm (TTS Bahasa Indonesia)*.

### A. Komponen Antarmuka
1. **Dropdown / Selector Preset Cepat:**
   - **Ringkas (Default Baru / Rekomendasi):**
     - Sebelum Berangkat: `"{rute} unit {unit}, {detik} detik lagi."`
     - Saatnya Berangkat: `"{rute} unit {unit}, saatnya berangkat."`
   - **Super Singkat (Pos Pantau Cepat):**
     - Sebelum Berangkat: `"{rute} {unit}, {detik} detik."`
     - Saatnya Berangkat: `"{rute} {unit}, jalan!"`
   - **Standar Formal (Kompatibilitas Lama):**
     - Sebelum Berangkat: `"Segera berangkat, {rute} unit {unit}, berangkat dalam {detik} detik."`
     - Saatnya Berangkat: `"Rute {rute}, unit {unit}, saatnya berangkat."`
   - **Kustom:** Otomatis aktif saat pengguna mengedit teks di dalam text field.
2. **Dua Input Card Berdampingan / Berurutan:**
   - Kolom 1: Template **Sebelum Berangkat (Persiapan)**
   - Kolom 2: Template **Saatnya Berangkat (Jatuh Tempo)**
3. **Baris Tombol Chip Variabel (Quick Insertion Chips):**
   Tepat di bawah tiap kolom input tersedia tombol chip:
   - `+ {rute}` | `+ {unit}` | `+ {detik}` | `+ {jam}` | `+ {ritase}`
   - Menekan chip langsung menyisipkan tag ke posisi kursor pengguna di kolom input tanpa perlu mengetik simbol kurung kurawal secara manual.
4. **Live Audio Preview & Reset:**
   - Menampilkan teks simulasi nyata (jika 1 rute vs jika multirute).
   - Tombol **Uji Suara Template** untuk mendengarkan hasil konfigurasi langsung ke speaker/headset.
   - Tombol **Reset ke Default** untuk memulihkan preset awal.

### B. Desain Ergonomi & Aksesibilitas
- **One-Thumb Friendly:** Target sentuh tombol chip dan aksi minimal 44–48 px.
- **Dual Theme Support:**
  - *Dark Mode:* Latar Obsidian (`#0C1017`), teks Amber Glow (`#FF9800`) dan Cyan (`#00E5FF`).
  - *Light Mode:* Latar Putih/Silver (`#F8FAFC`), kontras teks pekat `#0F172A` terbaca jelas di bawah sinar matahari.

---

## 4. Arsitektur Teknis & Alur Data

### A. Lapisan Flutter / Dart
1. **`lib/domain/models.dart` (`AlarmPreferences`):**
   ```dart
   class AlarmPreferences {
     final String prepTemplate;
     final String dueTemplate;
     ...
   }
   ```
   Nilai default:
   - `prepTemplate`: `"{rute} unit {unit}, {detik} detik lagi."`
   - `dueTemplate`: `"{rute} unit {unit}, saatnya berangkat."`
2. **`lib/domain/alarm_plan.dart` (`buildAlarmPlan`):**
   Menghitung flag `isMultiRoute`:
   ```dart
   final participatingRoutesCount = workspace.routes.where((r) => r.participates && r.alarmEnabled).length;
   final isMultiRoute = participatingRoutesCount > 1;
   ```
   Flag ini dan kedua template disertakan ke dalam `AlarmEvent` dan dikirim melalui platform channel `MethodChannel('id.mikrotrans.hedge/alarms')`.

### B. Lapisan Android Native (Kotlin)
1. **`AlarmEngine.kt`:**
   Memperbarui model data `AlarmSpec` dengan field:
   - `prepTemplate: String`
   - `dueTemplate: String`
   - `isMultiRoute: Boolean`
   Nilai ini dipersistensikan ke SharedPreferences `hedge_alarms`.
2. **`AlarmSpeechText.kt`:**
   Menambahkan logika parser template dinamis:
   ```kotlin
   fun message(event: AlarmSpec, now: Long): String? {
       if (event.stage == "prep" && now >= event.departureAt) return null
       val rawTemplate = if (event.stage == "prep") event.prepTemplate else event.dueTemplate
       val template = if (rawTemplate.isBlank()) defaultTemplate(event.stage) else rawTemplate
       
       val routeStr = if (event.isMultiRoute) routeCode(event.routeName) else ""
       val unitStr = unitLast4(event.unitNumber)
       val secondsStr = ((event.departureAt - now + 999) / 1000).toString()
       
       return format(template, routeStr, unitStr, secondsStr, event)
   }
   ```
3. **`AlarmSpeechPlayer.kt` & `MainActivity.kt`:**
   Memperluas method `testSpeech` agar menerima draf template yang sedang diuji dari Flutter UI.

---

## 5. Ketahanan Sistem & Penanganan Kasus Ekstrem (*Edge Cases*)

1. **Template Dikosongkan Pengguna:**
   Sistem otomatis *fallback* ke template bawaan Ringkas jika kolom input kosong atau hanya berisi spasi, mencegah teks bisu/error pada TTS.
2. **Tag Typo atau Tidak Dikenal:**
   Tag yang salah ketik (misal `{rutee}`) dibersihkan secara aman tanpa merusak tag lainnya.
3. **Nomor Unit < 4 Digit atau Non-Numerik:**
   Unit pendek seperti `"01"` atau `"630"` diproses penuh tanpa error batas indeks regex. Unit teks seperti `"CAD"` dilafalkan sebagai huruf biasa.
4. **Tahap Persiapan yang Terlewat:**
   Jika alarm persiapan terpicu saat waktu sudah melewati rencana keberangkatan (`now >= departureAt`), fungsi tetap mengembalikan `null` untuk mencegah pelafalan "0 detik".

---

## 6. Skenario Pengujian & Verifikasi

1. **Unit Test Android Native ([AlarmSpeechTextTest.kt](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechTextTest.kt)):**
   - Penguraian template dengan berbagai kombinasi tag (`{rute}`, `{unit}`, `{detik}`, `{jam}`, `{ritase}`).
   - Verifikasi mode 1 rute (`isMultiRoute = false`): tag `{rute}` menghasilkan string kosong dan tanda koma di awal kalimat dibersihkan rapi.
   - Verifikasi mode multi-rute (`isMultiRoute = true`): tag `{rute}` membacakan kode rute ringkas.
   - Verifikasi nomor bodi panjang (`>4` digit) terpotong rapi mengambil 4 digit terakhir.
   - Verifikasi fallback saat template kosong.
2. **Flutter Widget & Domain Tests (`test/`):**
   - Serialisasi JSON `AlarmPreferences` dan `AlarmEvent` memuat `prepTemplate`, `dueTemplate`, dan `isMultiRoute`.
   - Interaksi pergantian preset dropdown dan penekanan tombol chip sisip tag.
   - Verifikasi kontras tema gelap & terang pada kartu pengaturan TTS.
3. **Verifikasi Tooling & Branch:**
   - Berada di branch `devmode`.
   - Menjalankan `flutter analyze --no-pub`, `flutter test --no-pub`, dan `./gradlew testDebugUnitTest`.
   - **TIDAK** melakukan build APK tanpa perintah eksplisit dari user.
