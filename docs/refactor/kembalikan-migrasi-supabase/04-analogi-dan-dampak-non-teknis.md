# 04. Analogi & Dampak Non-Teknis: Pengalihan ke Supabase

**Tanggal:** 2026-11-23  
**Branch:** `devmode`  
**Topik:** Pemahaman Non-Teknis dan Dampak Operasional Lapangan  

---

## 1. Analogi Non-Teknis

Bayangkan sistem sinkronisasi data HEDGE seperti **buku register induk pramudi di pos dispatcher**:
* **Sebelumnya (Firebase):** Register digital pramudi disimpan di lemari arsip cloud milik Google. Seluruh catatan supir yang bertugas di rute JAK.115 tersimpan rapi di map Firestore.
* **Kebutuhan Pengalihan (Supabase):** Kita diminta memindahkan register utama ke pos Supabase. Saat diperiksa, lemari arsip di pos Supabase ternyata hanya memuat 6 lembar catatan lama.
* **Tindakan yang Dilakukan:** Kita tidak memindahkan seluruh gudang barang, melainkan **hanya memindahkan lembar data pramudi riil (69 pramudi)** dari pos Google langsung ke rak master supir di pos Supabase.
* **Pengamanan Sistem:** Kita melengkapi kurir (aplikasi HEDGE di HP dispatcher) dengan instruksi cadangan: jika daftar rute di pos Supabase sedang kosong, kurir langsung mengambil arsip pramudi tanpa harus menunggu map rute diisi, lalu memasangkan supir tersebut ke angkot yang nomornya cocok.

---

## 2. Dampak Langsung bagi Dispatcher di Lapangan

1. **Kelengkapan Data Supir Terjaga 100%:**
   69 data pramudi (Tachmidi, Zaenuri, Deny, Warita, Kanang, dst.) tetap utuh dan tersedia di database Supabase tanpa ada kehilangan data (*zero data loss*).
2. **Koneksi Stabil & Offline-First:**
   Pekerjaan dispatcher di terminal tetap berjalan mulus meskipun jaringan internet mengalami fluktuasi karena SQLite lokal di HP tetap menjadi pengendali utama.
3. **Tanpa Gangguan pada Tampilan & Fungsi Dispatch:**
   Papan HEDGE, timeline ritase, kalkulator headway, penugasan shift supir, dan alarm TTS tetap berfungsi identik seperti biasa.
4. **Instalasi & Build Aman:**
   Tidak ada risiko crash kompilasi Android karena modul-modul native dibiarkan utuh di project.
