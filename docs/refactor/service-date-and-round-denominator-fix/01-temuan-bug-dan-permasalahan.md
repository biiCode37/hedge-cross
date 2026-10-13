# 01. Temuan Bug & Permasalahan — Tanggal Operasional Kemarin & Denominator Ritase Telemetri

Dokumen ini memuat analisis mendalam akar masalah (*root cause*), aliran data (*data flow*), dan kendala operasional dispatcher terkait dua temuan bug:
1. Hitungan mundur (countdown) keberangkatan menghitung dari hari kemarin akibat tanggal jadwal tidak tersinkronisasi setelah date picker dihapus.
2. Badge pill telemetri menampilkan ritase yang salah ("Ritase 2/3" alih-alih "Ritase 2/4") saat rute dikonfigurasi 3 ritase mulai dari ritase ke-2.

---

## 1. Temuan Bug 1: Countdown Keberangkatan Menghitung dari Hari Kemarin

### Gejala & Perilaku di Lapangan
- Pengguna (dispatcher) membuka aplikasi hari ini dan menekan tombol **"Buat Jadwal"**.
- Jadwal berhasil di-generate. Namun, indikator countdown pada layar dispatch utama dan TV board menunjukkan waktu yang aneh: waktu sudah kedaluwarsa puluhan jam yang lalu atau format countdown menampilkan `+24:xx:xx` (overdue lebih dari sehari).
- Pada saat yang sama, alert alarm keberangkatan tidak berbunyi pada jam yang semestinya karena sistem menganggap waktu keberangkatan telah lewat kemarin.
- Teks warning banner di halaman jadwal menampilkan informasi ganjil:
  `Jadwal bertanggal 2026-10-12. Tanggal pilihan: 2026-10-12.`
  Padahal pengguna tidak pernah memilih tanggal tersebut karena kontrol DatePicker sudah dihapus dari antarmuka.

### Analisis Akar Masalah (Root Cause)
1. **Persistensi Tanggal Statis di Database SQLite**:
   - `LocalWorkspaceRepository.load()` membaca tanggal kerja dari tabel database settings:
     ```dart
     date: settings['date'] ?? serviceDate(DateTime.now())
     ```
   - Setiap kali aplikasi menyimpan workspace kemarin (misal `2026-10-12`), nilai `'date'` tersimpan di SQLite sebagai string tanggal hari tersebut.
2. **Ketiadaan Sinkronisasi Otomatis Setelah Penghapusan DatePicker**:
   - Sebelumnya, terdapat komponen `DatePicker` di UI yang memungkinkan pengguna mengubah tanggal secara manual lewat `controller.setDate(date)`.
   - Ketika DatePicker dihapus dari antarmuka pengguna, satu-satunya pemanggil `controller.setDate()` hilang. Akibatnya, `workspace.date` beku permanen pada tanggal saat database terakhir kali ditulis.
3. **Penggunaan Tanggal Beku pada Pembuatan Jadwal Baru**:
   - Saat tombol **"Buat Jadwal"** ditekan hari ini, `WorkspaceController.generate()` memanggil scheduler dengan parameter:
     ```dart
     date: state.workspace.date // Tanggal beku dari database (kemarin)
     ```
   - Akibatnya, jadwal yang baru saja di-generate tetap dicap dengan tanggal kemarin (`revision.date = '2026-10-12'`).
4. **Dampak pada Kalkulasi Countdown & Dispatch Focus**:
   - `plannedInstant(revision.date, row.minute)` menghitung waktu absolut keberangkatan berdasarkan tanggal kemarin.
   - Fungsi `CountdownIndicator` dan `selectDispatchFocus` menghitung selisih waktu terhadap jam sekarang:
     `remaining = at.difference(now.toUtc())`
   - Karena `at` adalah jam pada hari kemarin, nilainya bernilai negatif lebih dari 24 jam.

---

## 2. Temuan Bug 2: Denominator Badge Telemetri "Ritase 2/3" Seharusnya "Ritase 2/4"

### Gejala & Perilaku di Lapangan
- Pengguna mengonfigurasi rute dengan:
  - Jumlah ritase total: **3 rit** (`rounds = 3`)
  - Mulai dari ritase ke: **2** (`startRound = 2`)
- Di lapangan, armada akan bertugas menjalankan 3 putaran: **Rit 2, Rit 3, dan Rit 4**. Putaran terakhir hari itu adalah Rit ke-4.
- Namun, pada bar kapsul telemetri jadwal ([`FleetTelemetryPillBar`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/telemetry_bar.dart)), pill menampilkan:
  `Ritase 2/3`
- Seharusnya pill menampilkan:
  `Ritase 2/4` (karena unit sedang berada di ritase ke-2 dari total rentang yang berakhir di ritase ke-4).

### Analisis Akar Masalah (Root Cause)
1. **Kesalahan Pemahaman Semantik Denominator**:
   - Parameter yang dikirimkan oleh [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart) ke `FleetTelemetryPillBar` adalah:
     ```dart
     totalRounds: route.config.rounds // Nilai ini adalah 3
     ```
   - Komponen `FleetTelemetryPillBar` mencetak:
     `'Ritase $currentRound/$totalRounds'` -> `'Ritase 2/3'`
2. **Pengabaian Offset `startRound`**:
   - Rumus matematika ritase di scheduler:
     `round = startRound + (i ~/ units.length)`
   - Untuk 3 ritase yang dimulai dari ritase 2:
     - Putaran pertama = Rit 2
     - Putaran kedua = Rit 3
     - Putaran ketiga (terakhir) = `startRound + rounds - 1` = `2 + 3 - 1` = **Rit 4**.
   - Denominator bagi dispatcher bukanlah *banyaknya putaran* (3), melainkan *nomor putaran target / putaran terakhir* (**4**). Menampilkan "2/3" memberi kesan seolah-olah putaran terakhir adalah Rit 3.
