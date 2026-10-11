# 04. Analogi & Dampak Non-Teknis — SnackBar Undo & Gerbang Perizinan Wajib

Dokumen ini menjelaskan perbaikan yang dilakukan menggunakan analogi dunia nyata dan menguraikan dampaknya bagi operasional dispatcher angkot Mikrotrans di lapangan.

---

## 1. Analogi Dunia Nyata

### Analogi A: Tanda Terima Transaksi dengan Tombol Simpan vs Batalkan
* **Sebelum Perbaikan:**
  Bayangkan kasir mencetak struk bukti keberangkatan armada dan menempelkannya tepat di depan mata Anda. Anda tidak bisa melipat atau menyingkirkan struk itu ke kantong. Satu-satunya cara menyingkirkannya adalah dengan merobeknya dan membatalkan keberangkatan mobil.
* **Sesudah Perbaikan:**
  Kini ada klip di sudut struk. Jika Anda sudah membaca dan ingin meja kerja Anda bersih, cukup sentuh tombol silang (X) untuk menyingkirkan struk tersebut tanpa membatalkan keberangkatan mobil yang sudah meluncur. Tombol merah "Batalkan" tetap ada jika Anda memang keliru mencatat.

---

### Analogi B: Pemeriksaan Kelengkapan Surat Kendaraan Sebelum Gerbang Dibuka
* **Sebelum Perbaikan:**
  Petugas dispatch mengizinkan armada masuk ke lintasan tanpa memeriksa apakah sirine, radio HT, dan lampu strobo berfungsi. Begitu berada di tengah rute yang macet, sirine mati dan komando dispatcher tidak pernah terdengar oleh supir.
* **Sesudah Perbaikan:**
  Pintu gerbang shelter memiliki palang keamanan otomatis (*gatekeeper*). Sebelum dispatcher mulai bekerja, sistem melakukan inspeksi 4 alat komunikasi penting:
  1. **Radio HT Utama (Notifikasi):** Untuk mendengar pengumuman.
  2. **Jam Digital Presisi (Alarm Tepat):** Agar tidak ada selisih detik waktu berangkat.
  3. **Lampu Darurat Layar Penuh (Layar Penuh):** Agar menyala terang walau HP di dalam saku gelap.
  4. **Panggilan Interkom Prioritas (Di Atas Aplikasi Lain):** Agar tetap terdengar walau dispatcher sedang membuka aplikasi lain.
  Jika salah satu alat belum dinyalakan, palang gerbang tetap tertutup dan layar memandu dispatcher menyalakan alat yang kurang. Setelah lengkap, palang terbuka otomatis.

---

## 2. Dampak Langsung bagi Dispatcher di Lapangan

1. **Bebas Salah Pencet (Zero False Cancellation):** Dispatcher tidak lagi khawatir membatalkan keberangkatan secara tidak sengaja hanya karena ingin menutup notifikasi di layar.
2. **Kenyamanan Mata di Terik & Malam Hari:** Desain SnackBar yang menyatu dengan tema HEDGE tidak lagi menyilaukan atau terlihat janggal.
3. **Kepastian Alarm Berbunyi 100%:** Dengan gerbang izin wajib, tidak ada lagi kasus "HP hening" atau "alarm telat bunyi 5 menit" akibat Android Doze Mode atau ketiadaan izin overlay. Semua dispatcher di lapangan beroperasi dengan standar sistem yang sama kuatnya.
