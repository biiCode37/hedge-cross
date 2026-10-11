# 01. Temuan Bug & Permasalahan — SnackBar Undo & Gerbang Perizinan Wajib (Permission Gate)

Dokumen ini memuat analisis mendalam mengenai kekurangan pada mekanisme notifikasi in-app (SnackBar) pembatalan keberangkatan dan ketiadaan validasi perizinan wajib sistem pada saat aplikasi HEDGE (Headway Generator by Mikrotrans Utara) pertama kali dibuka.

---

## 1. Ringkasan Eksekutif Temuan

Berdasarkan pengujian langsung di perangkat Android fisik dan evaluasi alur kerja dispatcher di lapangan, teridentifikasi 2 masalah signifikan:

1. **Defisiensi UX SnackBar Keberangkatan (Tidak Ada Tombol Tutup & Inkonsistensi Tema):**
   - Pesan *"Keberangkatan unit {nomor unit} tercatat."* menggunakan implementasi default `SnackBar` Flutter.
   - Dispatcher yang telah yakin mencatat keberangkatan tidak memiliki cara untuk menutup banner tersebut secara manual selain menunggu durasi 5 detik atau terpaksa menekan tombol *"BATALKAN"*.
   - Jika tombol *"BATALKAN"* ditekan hanya demi menyingkirkan banner yang menutupi layar, status keberangkatan aktual malah terhapus.
   - Warna dan kontras `SnackBar` default tidak harmonis dengan palet Cyber-Transit HEDGE (`#070B12` Obsidian vs `#F8FAFC` Light Mode), tampak canggung dan mengganggu keterbacaan.

2. **Ketiadaan Gerbang Perizinan Wajib Saat Aplikasi Dibuka (Cold Start Permission Bypass):**
   - HEDGE sangat bergantung pada 4 perizinan native Android tingkat sistem untuk menjamin alarm headway dan pengingat armada berbunyi tepat waktu:
     1. **Notifikasi (`POST_NOTIFICATIONS`):** Menampilkan banner alarm dan pengingat latar belakang.
     2. **Alarm Tepat (`SCHEDULE_EXACT_ALARM`):** Mencegah Android Doze Mode menunda alarm hingga lewat waktu keberangkatan.
     3. **Layar Penuh (`USE_FULL_SCREEN_INTENT`):** Memunculkan alert langsung saat HP dispatcher berada dalam kondisi layar terkunci/mati di saku.
     4. **Di Atas Aplikasi Lain (`SYSTEM_ALERT_WINDOW`):** Memunculkan modal alarm saat dispatcher sedang membuka aplikasi lain (seperti WhatsApp, Google Maps, dll).
   - Sebelumnya, pengecekan izin hanya berada di tab Pengaturan / Jadwal. Pengguna dapat langsung masuk ke halaman utama tanpa satu pun izin ini aktif.
   - Akibatnya di lapangan, alarm sering kali hening atau tidak muncul karena izin-izin penting tersebut belum diberikan oleh dispatcher.

---

## 2. Analisis Mendalam Kebutuhan Solusi

### Permasalahan A: SnackBar Pembatalan Keberangkatan
- **Akar Masalah:**
  Penggunaan `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` standar tanpa tombol dismiss eksplisit (`Icons.close`) dan tanpa styling token HEDGE.
- **Dampak Lapangan:**
  Banner menutupi sebagian panel kontrol bawah. Dispatcher yang ingin segera membersihkan layar dari banner tidak sengaja membatalkan keberangkatan unit yang baru saja jalan.

### Permasalahan B: Akses Aplikasi Tanpa Izin Wajib
- **Akar Masalah:**
  Alur navigasi aplikasi langsung me-render `HomeScreen` tanpa adanya gerbang validasi (*gatekeeper*).
- **Kondisi Lapangan:**
  Pengguna baru atau dispatcher yang baru menginstal aplikasi sering melewatkan pemberian izin, sehingga armada terlambat diberangkatkan karena ponsel tidak berdering saat jadwal tiba.
- **Kebutuhan Solusi:**
  - Halaman loading pemeriksaan izin saat cold start ("Memeriksa Perizinan Sistem...").
  - Blokir akses ke `HomeScreen` jika salah satu dari 4 izin wajib belum terpenuhi.
  - Tampilan visual status ke-4 izin dengan tombol aksi langsung ke pengaturan Android terkait.
  - Auto-unlock saat seluruh izin berhasil dipenuhi (termasuk deteksi otomatis saat kembali dari menu pengaturan Android).
