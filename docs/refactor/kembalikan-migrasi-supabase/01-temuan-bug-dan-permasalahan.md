# 01. Temuan & Evaluasi: Pengalihan Kembali Backend Cloud ke Supabase

**Tanggal:** 2026-11-23  
**Branch:** `devmode`  
**Topik:** Evaluasi Kebutuhan Pengalihan Backend Cloud dari Google Firebase Firestore Kembali ke Supabase PostgreSQL  

---

## 1. Konteks Permintaan

Sistem backend cloud HEDGE sebelumnya telah dialihkan ke Google Firebase Firestore. Namun, diputuskan untuk mengembalikan integrasi backend cloud ke **Supabase** (`https://mkffwfvaxuqifflpeaib.supabase.co`) dengan fokus utama pada pemindahan data **pramudi (drivers)**, sementara dependensi Firebase dipertahankan tanpa dihapus total dari project (*dormant*) guna menjaga stabilitas build Gradle Android.

---

## 2. Hasil Pengecekan Kondisi Awal Database

### 2.1. Status Proyek Supabase (`mkffwfvaxuqifflpeaib`)
Sebelum tindakan dilakukan, dilakukan inspeksi langsung terhadap endpoint REST Supabase:
* **Tabel `master_drivers`:** Hanya memiliki **6 baris data lama** (Mansyur, Mad Noer, Matnur, Parikunun, Rosidi, Beni) untuk rute JAK.115 (`d2c14c0e-0bfe-42a5-b7da-8f40fa212e8a`).
* **Tabel `master_routes`:** Berisi **0 baris data** (kosong).
* **Tabel `master_units`:** Berisi **0 baris data** (kosong).
* **Tabel `authorized_dispatchers`:** Berisi **0 baris data** (kosong / terlindungi Row Level Security).
* **Tabel `outbox`:** Belum tersedia di schema publik.

### 2.2. Status Proyek Firebase Firestore (`hedge-mikrotrans`)
* **Koleksi `routes` (Dokumen JAK.115):** Tersimpan **69 data pramudi riil** yang terdiri dari 58 pramudi tetap dan 11 pramudi cadangan, lengkap dengan pemetaan nomor armada KWK bawaan dan shift penugasan.
* **Koleksi `authorized_dispatchers`:** Tersimpan 7 akun dispatcher whitelist.

---

## 3. Identifikasi Tantangan Teknis & Potensi Titik Kegagalan

1. **Ketergantungan Join `master_routes` di `SupabaseCloudSyncClient.pullRoutes`:**
   Pada implementasi awal Supabase, fungsi `pullRoutes` menjalankan query:
   ```dart
   _supabase.from('master_routes').select('*, master_units(*), master_drivers(*)');
   ```
   Jika `master_routes` kosong, query akan menghasilkan daftar kosong (`[]`), sehingga 69 data pramudi yang dimigrasikan ke `master_drivers` tidak akan pernah terbaca oleh perangkat dispatcher lokal.
2. **Ketergantungan Pencarian UUID di `pushDrivers`:**
   Jika dispatcher mengirimkan rute berdasarkan kode non-UUID (misal `"JAK.115"`), `pushDrivers` berusaha mencari UUID ke tabel `master_routes`. Jika tabel kosong, proses push akan terhenti (*abort*).
3. **Konflik Timpa Data di `mergeCloudRoutesIntoLocal`:**
   Jika data rute cloud hanya membawa pramudi tanpa metadata rute lengkap, fungsi merge berisiko menimpa nama rute lokal dengan teks default `'RUTE — RUTE'`.

---

## 4. Matriks Solusi

| Masalah | Solusi Kode / Arsitektur |
| :--- | :--- |
| Data 69 pramudi masih di Firestore | Ekstraksi otomatis dan `upsert` ke `master_drivers` Supabase via REST API |
| `master_routes` kosong di Supabase | Penambahan fallback cerdas di `pullRoutes`: langsung query `master_drivers` jika `master_routes` kosong |
| Resolusi UUID rute non-UUID | Penambahan peta katalog statis `_catalogRouteUuids` di klien Supabase |
| Proteksi penimpaan nama rute lokal | Pemeriksaan `route_code` sebelum memperbarui `name`, `color`, dan `config` rute |
