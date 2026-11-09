# 01. Temuan Bug & Permasalahan: Migrasi Backend Cloud Supabase ke Google Firebase

**Tanggal:** 2026-11-09  
**Branch:** `devmode`  
**Topik:** Evaluasi Keterbatasan Supabase Cloud & Kebutuhan Migrasi Backend Permanen Anti-Sleep  

---

## 1. Konteks Operasional Lapangan

Aplikasi HEDGE (*Headway Generator By Mikrotrans Utara*) digunakan oleh dispatcher di terminal dan pos rute untuk mengatur interval headway, rotasi unit, dan pemantauan keberangkatan armada mikrotrans secara waktu nyata. 

Sebelumnya, sistem sinkronisasi master data dan otentikasi whitelist akun dispatcher dialokasikan pada proyek Supabase (`hedge-cross`).

---

## 2. Akar Masalah (Root Causes) & Keterbatasan Supabase

### 2.1. Mekanisme Auto-Pause Proyek Gratis (Sleep / Freeze)
* **Pemicu:** Kebijakan *free-tier* Supabase secara otomatis mematikan (*pause*) proyek database jika tidak menerima traffic selama 7 hari berturut-turut.
* **Dampak Lapangan:** Jika rute tertentu libur beberapa hari atau dispatcher off-duty, proyek tertidur. Saat aplikasi dibuka kembali, domain Supabase (`mkffwfvaxuqifflpeaib.supabase.co`) menjadi *unresolvable* (DNS dinonaktifkan oleh edge proxy Supabase). Hal ini menyebabkan kegagalan sinkronisasi master data dan error validasi whitelist bagi dispatcher di lapangan.

### 2.2. Kebutuhan 100% Bebas Biaya Permanen Tanpa Kartu Kredit
* Supabase memerlukan kewaspadaan terhadap batas kuota transfer dan aktivasi berulang.
* Diperlukan infrastruktur cloud yang menerapkan kebijakan *hard-cap* gratis tanpa perlu mencantumkan nomor kartu kredit, menjamin nol risiko tagihan tak terduga (*zero surprise billing*).

### 2.3. Friksi Otentikasi Google Sign-In di Android
* Supabase memerlukan pertukaran token OAuth / ID token manual (`signInWithIdToken`) yang rentan terhadap perubahan format dan kebijakan platform Google.
* Ekosistem Android smartphone dispatcher jauh lebih stabil jika menggunakan layanan otentikasi native Google (Firebase Auth).

### 2.4. Penonaktifan Proyek Supabase
* Proyek Supabase `hedge-cross` resmi dinonaktifkan. Data operasional terakhir diamankan dalam berkas dump PostgreSQL klaster `db_cluster-06-11-2026@05-52-29.backup.gz`.

---

## 3. Matriks Risiko Sebelum Migrasi

| Aspek | Kondisi pada Supabase | Risiko bagi Dispatcher |
| :--- | :--- | :--- |
| **Ketersediaan (Uptime)** | Pause otomatis setelah 7 hari tidak aktif | Dispatcher gagal login dan sinkronisasi rute |
| **Biaya & Billing** | Berisiko tagihan jika upgrade paket | Keraguan operasional jangka panjang |
| **Google Sign-In** | Token exchange pihak ketiga | Potensi token expired / rejected di HP |
| **Server Datacenter** | Singapura (`ap-southeast-1`) | Latensi ekstra dibandingkan server lokal |
