# 04. Analogi & Dampak Non-Teknis: Kisah Stempel Paspor Gerbang Terminal

**Tanggal:** 2026-11-24  
**Branch:** `devmode`  

---

## 1. Analogi Dunia Nyata: "Ganti Stempel Tanpa Lapor ke Penjaga Gerbang"

Bayangkan **Gerbang Utama Terminal Mikrotrans** memiliki sistem keamanan ketat.
Setiap petugas dispatcher yang ingin masuk wajib menunjukkan **kartu paspor dinas** (Akun Google) yang memiliki **stempel segel resmi** dari kantor pusat (Sidik Jari SHA-1).

### Apa yang Terjadi Kemarin?
1. Saat merilis seragam baru kemarin (`v2.2.1`), mesin pembuat stempel di kantor diperbarui. Tanpa disengaja, tinta dan cap stempel yang baru memiliki pola ukiran berbeda (**Pola SHA-1 Baru**).
2. Sayangnya, buku panduan petugas jaga gerbang Google (**Google Cloud / Firebase Console**) masih mencatat pola stempel lama.
3. Begitu dispatcher mengetuk pintu gerbang sambil menyodorkan kartu, petugas jaga gerbang Google melihat pola stempelnya tidak cocok dengan buku daftar:
   > *"Maaf, stempel di kartu Anda tidak kami kenali! Anda tidak boleh masuk!"* (Terjadilah `ApiException: 10: DEVELOPER_ERROR`).
4. Akibatnya, seluruh petugas dispatcher yang hendak dinas tertahan di luar pintu gerbang dan tidak bisa membuka dasbor jadwal.

### Apa yang Dilakukan Sekarang?
1. **Daftarkan Pola Stempel Baru:** Kantor pusat langsung mendaftarkan pola stempel baru ke buku panduan penjaga gerbang Google. Keduanya kini dicatat resmi.
2. **Kunci Mesin Stempel Permanen:** Mesin stempel dikunci ke dalam brankas repositori (`android/app/hedge_debug.keystore`), sehingga polanya tidak akan pernah berganti lagi secara otomatis kapan pun dan di mana pun aplikasi dibangun.
3. **Buku Tamu Whitelist Siap di Meja:** Buku daftar 7 akun dispatcher resmi sudah siap dan terbuka, sehingga begitu stempel lolos, petugas langsung dipersilakan masuk dan bertugas mengatur jadwal armada Mikrotrans.

---

## 2. Perbandingan Situasi Sebelum vs Sesudah Perbaikan

| Aspek | Sebelum Perbaikan (`v2.2.1`) | Sesudah Perbaikan (`v2.2.2`) |
| :--- | :--- | :--- |
| **Sidik Jari SHA-1 di Firebase** | Hanya terdaftar versi lama (`49:78:...`), versi baru (`71:ff:...`) ditolak | Kedua sidik jari terdaftar resmi dan aktif di server Google/Firebase |
| **Keystore Penandatangan APK** | Bergantung pada folder lokal OS yang bisa ter-reset kapan saja | Dikunci permanen di repositori (`android/app/hedge_debug.keystore`) |
| **`google-services.json`** | Array `oauth_client` kosong | Memuat pemetaan resmi Android Client dan Web Client ID |
| **Web Client ID di Dart** | Menggunakan client ID proyek eksternal (`1066127378433`) | Menggunakan Web Client ID resmi `hedge-mikrotrans` (`817255308741`) |
| **Dampak bagi Dispatcher** | Muncul kotak teks merah error `ApiException: 10`, semua akun tertolak | Login 1-ketukan Google langsung mulus, aman, dan langsung masuk dasbor |
| **Sinkronisasi Data Armada** | Tetap berjalan normal | Tetap tersinkronisasi 100% via Supabase PostgreSQL |
