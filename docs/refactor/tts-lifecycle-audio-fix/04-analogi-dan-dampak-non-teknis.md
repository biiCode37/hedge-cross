# Analogi & Dampak Non-Teknis: Pemulihan Suara Alarm TTS HEDGE

Dokumen ini menyajikan penjelasan non-teknis melalui analogi dunia nyata mengenai akar masalah yang terjadi, serta perbandingan pengalaman nyata bagi petugas dispatcher Mikrotrans di lapangan sebelum dan sesudah perbaikan.

---

## 1. Analogi Sederhana Dunia Nyata

### Analogi 1: Petugas Pengeras Suara Terminal yang "Pamit Pulang"
Bayangkan di sebuah terminal angkutan umum (Mikrotrans) ada seorang **petugas pengeras suara (speaker)** khusus yang bertugas memanggil nomor unit armada:

1. **Situasi Awal (Sebelum Perbaikan):**
   - Suatu saat, pengawas terminal memberi aba-aba: *"Tolong matikan pengumuman suara sebentar, kita sedang koordinasi"* (fitur dimatikan).
   - Petugas pengeras suara mulai membereskan tas dan berjalan menuju pintu keluar terminal untuk pulang.
   - Dua detik kemudian, pengawas berubah pikiran: *"Eh, tolong aktifkan suaranya lagi sekarang!"* (fitur diaktifkan kembali).
   - Koordinator gerbang terminal melihat ke arah meja pengeras suara dan berkata: *"Oh, petugasnya masih terlihat ada di lorong keluar kok, nggak usah panggil petugas pengganti!"*.
   - Namun, petugas tersebut sebenarnya sedang melangkah keluar terminal dan pulang ke rumah.
   - Akibatnya, meja pengeras suara kosong melompong. Saat jam keberangkatan unit tiba, **tidak ada seorang pun yang membacakan jadwal keberangkatan**. Terminal hening total sampai terminal tutup dan buka kembali besok hari.

2. **Setelah Perbaikan:**
   - Ketika petugas mulai beres-beres untuk pamit, ia langsung memakai tanda pengenal *"Sedang Proses Pulang"*.
   - Jika ada perintah baru untuk menyalakan suara, koordinator melihat tanda tersebut dan tahu bahwa petugas lama tidak bisa diandalkan lagi. Koordinator **segera memanggil petugas baru yang segar** untuk langsung duduk di meja pengeras suara.
   - Pengumuman keberangkatan unit Mikrotrans langsung berbunyi lantang tanpa jeda atau macet.

---

### Analogi 2: Peluit yang Tersumpal Saat Ada Klakson Lewat
- **Sebelum Perbaikan:** Saat petugas sedang meniup peluit panjang untuk memberangkatkan unit JAK.115, tiba-tiba ada motor membunyikan klakson *"tin!"* sekali lewat di jalan (*notifikasi WhatsApp masuk*). Petugas kaget, langsung membuang peluitnya ke tong sampah, dan menolak meniup peluit lagi untuk unit itu. Pengemudi unit tidak tahu kapan harus jalan.
- **Setelah Perbaikan:** Petugas tetap fokus meniup peluit sampai tuntas meskipun ada suara klakson kecil di sekitarnya. Arahan keberangkatan terdengar jelas oleh pengemudi dan dispatcher.

---

## 2. Perbandingan Pengalaman Lapangan (Sebelum vs Sesudah)

| Aspek Operasional | Sebelum Perbaikan (Bug) | Sesudah Perbaikan (Stabil) |
| :--- | :--- | :--- |
| **Gonta-ganti Tombol Suara di Pengaturan** | Jika dispatcher sempat mematikan suara lalu menyalakannya lagi di rute yang sama, suara TTS mati permanen. Dispatcher harus menutup paksa (*Force Stop*) aplikasi agar suara kembali. | Dispatcher bebas mematikan dan menghidupkan kembali suara kapan saja. TTS langsung bersuara secara instan pada alarm berikutnya. |
| **Pesan Chat / Telepon Masuk** | Notifikasi chat masuk menyebabkan kalimat TTS terputus di tengah jalan (*"Rute JAK satu..." lalu hening*). | TTS tetap menyelesaikan kalimat panggilan armada (*"Rute JAK 115, unit 1865, saatnya berangkat"*). |
| **Mengaktifkan Suara saat Alarm Sedang Muncul** | Jika alarm sudah muncul di layar tanpa suara, menyalakan toggle suara tidak menghasilkan efek apa pun karena jadwal dianggap sudah hangus. | Begitu tombol suara diaktifkan, alarm yang sedang aktif di layar langsung membacakan unitnya seketika. |
| **Kejelasan Pengaturan Volume** | Dispatcher menaikkan "Volume Alarm HP" hingga 100%, tapi suara tetap hening karena volume "Media/Musik" ternyata sedang di-nolkan. Teks aplikasi membingungkan. | Teks aplikasi diperjelas menjadi *"mengikuti volume Media/Speaker Android"*, cocok dengan tombol volume samping HP dan pemakaian headset Bluetooth di lapangan. |
| **Tombol OFF di Layar Penuh** | Mematikan alarm lewat tombol OFF berisiko mengunci rute ke status mati permanen jika dispatcher membuka menu tanpa keluar aplikasi lebih dulu. | Status sinkronisasi otomatis berjalan setiap menit dan setiap kali menu pengaturan disentuh, memastikan rute yang dihidupkan kembali langsung aktif. |

---

## 3. Dampak Nyata bagi Operasional Dispatcher

1. **Zero Missed Dispatch:** Pengemudi Mikrotrans tidak lagi tertinggal jam keberangkatan akibat dispatcher tidak menyadari alarm yang hening.
2. **Kenyamanan Lapangan dengan Headset Bluetooth:** Suara pengumuman terdengar stabil di telinga dispatcher lapangan meskipun ponsel berada di saku atau terhubung ke speaker pos pantau.
3. **Ketahanan Tanpa Perlu Restart Aplikasi:** Dispatcher tidak perlu lagi melakukan trik teknis seperti *Clear Cache* atau *Force Stop* aplikasi saat ingin mengaktifkan kembali suara alarm.
