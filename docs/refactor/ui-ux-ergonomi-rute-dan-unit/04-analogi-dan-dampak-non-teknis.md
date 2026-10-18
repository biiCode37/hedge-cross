# Analogi & Dampak Non-Teknis: Ergonomi Tampilan Rute dan Unit

## 1. Analogi Dunia Nyata: Papan Jadwal Penerbangan Bandara & Kunci Kontak Lemari Armada

Bayangkan seorang petugas pengatur lalu lintas penerbangan di bandara atau pos pemantau terminal:

- **Sebelum Perbaikan:**
  - Di papan informasi monitor cepat (*fast status board*), setiap maskapai ditulis lengkap bersama seluruh kota transitnya: `"GA-123 JAKARTA SOEKARNO HATTA KE SURABAYA JUANDA LANJUT DENPASAR BALI"`. Akibatnya, monitor hanya muat 1 baris penerbangan dan petugas harus menggeser layar bolak-balik hanya untuk melihat apakah ada pesawat yang siap berangkat.
  - Pada papan rute, tulisan nama kota dipaksa berhimpitan di samping nomor penerbangan, sehingga tulisannya terpotong menjadi `"GA-123 JAK..."`. Petugas jadi tidak tahu rute tersebut sebenarnya mengarah ke mana.
  - Pesawat yang sedang terbang aktif bercampur aduk posisinya di bawah pesawat yang sedang mogok atau parkir di hanggar.
  - Ketika mencatat supir yang membawa armada, petugas harus menulis tangan nomor seri kendaraan tanpa melihat daftar kunci kontak yang tersedia, sehingga sering terjadi salah catat angka.

- **Setelah Perbaikan:**
  - Di monitor cepat bagian atas, hanya tertera kode singkat yang tegas: **`JAK.01`**, **`JAK.115`**, **`JAK.110A`**, dan **hanya yang sedang bertugas hari ini yang muncul**. Petugas bisa melihat 5 rute sekaligus dalam sekali lirik tanpa perlu menyentuh layar.
  - Di buku master rute, nomor rute terpampang besar di baris atas (**`JAK.01`**), dan nama lengkap trayeknya tertulis rapi di baris bawahnya (**`Tanjung Priok — Plumpang`**). Tidak ada lagi huruf yang terpotong menjadi "TA...".
  - Rute yang sedang beroperasi aktif langsung otomatis naik ke rak paling atas papan jadwal, siap dipantau setiap detik.
  - Ketika dispatcher menugaskan supir, dispatcher cukup membuka laci nomor unit digital: tinggal ketik 2 digit angka atau pilih dari daftar armada yang ada, langsung terkunci secara presisi.

---

## 2. Dampak Langsung bagi Dispatcher di Lapangan

1. **Efisiensi Navigasi Sekali Lirik (*Glanceable UI*):** Dispatcher tidak lagi menghabiskan waktu berharga menggeser (*scrolling*) deretan pill rute yang kepanjangan di bawah terik matahari.
2. **Keterbacaan Informasi 100% Bebas Truncation:** Nama trayek dapat dibaca utuh pada halaman rute tanpa terpotong badge atau tombol opsi.
3. **Pemberangkatan Armada Lebih Cepat:** Rute aktif selalu berada di jangkauan jempol paling atas, memangkas waktu pencarian rute hingga 80%.
4. **Nol Kesalahan Input Nomor Unit:** Fitur pencarian dropdown menjamin pengisian nomor unit armada selalu akurat, seragam, dan tervalidasi.
