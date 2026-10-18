# 04 Analogi & Dampak Non-Teknis: Sinkronisasi Supabase, Auto-Pairing Pramudi, & Indikator Aktif TTS

**Tanggal:** 18 Oktober 2026  
**Target Pengguna:** Dispatcher Operasional Lapangan Mikrotrans  

---

## 1. Analogi Dunia Nyata

### Kasus 1: Buku Catatan Pribadi vs Papan Induk Terminal (Sinkronisasi Supabase)
- **Sebelum Perbaikan:**  
  Dispatcher mencatat nama 67 pramudi di buku catatan saku pribadinya di HP. Buku itu lengkap, namun papan pengumuman induk di kantor pusat terminal (database Supabase) masih kosong melompong karena belum ada kurir yang mengantarkan salinan catatan tersebut ke pusat.
- **Setelah Perbaikan:**  
  Kini ada kurir otomatis yang menghubungkan buku saku dispatcher dengan papan pusat. Saat supir ditambah atau diedit, kurir langsung mengirimkannya ke Supabase. Dispatcher juga memiliki tombol **"Sinkronkan ke Cloud Supabase"** untuk mengirim seluruh 67 daftar pramudi sekaligus ke server pusat dengan satu sentuhan.

### Kasus 2: Absensi Supir vs Duduk di Kursi Kemudi (Auto-Pairing Pramudi)
- **Sebelum Perbaikan:**  
  Dispatcher sudah mendaftar nama supir lengkap dengan nomor mobil bawaannya (misal: Tahmidi bawa KWK 222153 shift pagi). Namun sistem hanya memasukkan nama mereka ke buku daftar induk, tanpa menyuruh supir duduk di kursi kemudi unitnya masing-masing. Di halaman "02 Armada", semua mobil masih kosong (`Pagi: -`, `Siang: -`) dan dispatcher harus mendudukkan supir satu demi satu (60 kali klik!).
- **Setelah Perbaikan:**  
  Setiap kali supir didaftarkan beserta mobil bawaannya, sistem langsung menempatkannya di kursi kemudi unit tersebut secara instan. Bagi supir yang sudah terlanjur didaftarkan sebelumnya, dispatcher cukup menekan tombol hijau **"Pasangkan Bawaan"** di halaman Armada: *klik satu kali, semua 30 armada langsung terisi supir pagi dan siangnya secara otomatis!*

### Kasus 3: Lampu Helm Supir yang Sedang Mengemudi (Indikator Aktif TTS)
- **Sebelum Perbaikan:**  
  Di dalam mobil tertera nama supir pagi dan supir siang berdampingan. Petugas pengeras suara (TTS) sebenarnya tahu bahwa sebelum jam 13:00 ia harus memanggil supir pagi, dan setelah jam 13:00 ia harus memanggil supir siang. Tetapi dispatcher di pinggir jalur cemas karena melihat dua nama sejajar tanpa tanda siapa yang sedang bertugas saat ini.
- **Setelah Perbaikan:**  
  Kini ada lampu indikator neon bulat `●` yang menyala tegas di samping nama supir yang sedang aktif bertugas:
  - Sebelum jam 13:00 $\rightarrow$ Kotak supir pagi menyala dengan border Cyan terang dan titik neon `●`.
  - Setelah jam 13:00 $\rightarrow$ Otomatis berpindah, kotak supir siang menyala dengan border Amber/Orange terang dan titik neon `●`.
  Dispatcher dapat melihat sekilas dan 100% yakin nama supir itulah yang akan dibacakan oleh suara TTS terminal saat jadwal keberangkatan tiba.

---

## 2. Tabel Perbandingan Sebelum vs Sesudah

| Fitur | Sebelum Perbaikan | Sesudah Perbaikan |
|---|---|---|
| **Database Supabase Cloud** | Tabel `master_drivers` kosong (0 rows), RLS anon ditolak. | RLS anon `ALL` aktif, didukung fungsi push otomatis & tombol "Sinkronkan ke Cloud". |
| **Pemasangan Unit Armada** | Semua unit kosong (`Pagi: -`, `Siang: -`). Harus dipasangkan satu per satu manual. | Supir baru langsung terpasang otomatis. Ada tombol **"Pasangkan Bawaan"** untuk memasangkan 67 supir sekaligus. |
| **Penyimpanan Lokal (SQLite)** | ID supir shift 1 & 2 hilang saat aplikasi direstart karena kolom SQLite belum ada. | Kolom `driver_shift1_id` dan `driver_shift2_id` permanen tersimpan di SQLite lokal. |
| **Kepastian Suara TTS** | Tidak ada tanda visual siapa yang aktif; dispatcher khawatir supir tertukar. | Titik neon neon `●` menyala di supir yang aktif saat ini sesuai batas `shiftChangeTime` (13:00). |
| **Ergonomi Layar Sempit** | Header armada berpotensi overflow di ukuran layar tertentu. | Tombol armada responsif dengan scroll horizontal, bebas overflow di segala resolusi. |
