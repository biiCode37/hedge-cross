# 05. Analisis Mendalam & Audit UX: Temuan Defect, Error Tersembunyi, & Solusi

**Tanggal:** 2026-11-24  
**Branch:** `devmode`  
**Cakupan Audit:** Seluruh Modul (Autentikasi, Sinkronisasi Cloud, Audio Alarm TTS, Form Input, & Tampilan Responsif)

---

## 1. Matriks Temuan Isu, Dampak UX, & Rekomendasi Solusi

| No | Modul / Lokasi | Temuan Isu Teknis | Dampak bagi Pengguna (UX) | Solusi / Perbaikan Skala Industri |
| :--- | :--- | :--- | :--- | :--- |
| **1** | `lib/data/auth_service.dart:299` | Raw Exception teknis bahasa Inggris (misal `PlatformException`, `ApiException`) langsung dilempar ke UI. | Kotak merah bertuliskan istilah teknis yang menakutkan dan membingungkan dispatcher lapangan. | Implementasi pemetaan pesan error ramah Bahasa Indonesia (*user-friendly error translator*). |
| **2** | `lib/data/auth_service.dart:208` | Pembatalan pemilihan akun Google memunculkan error *"Masuk dengan Google dibatalkan."*. | Muncul banner merah saat user hanya menekan tombol *back*, seolah sistem mengalami kegagalan. | Jangan munculkan pesan error jika pembatalan dilakukan dengan sengaja oleh pengguna. |
| **3** | `lib/data/auth_service.dart:171` | `restoreSession()` tidak memiliki batas waktu (*timeout*) saat kueri online ke Firestore. | Aplikasi berpotensi *freeze* atau *stuck* di layar *loading* saat dibuka di area pool bus bersinyal lemah. | Berikan batas *timeout* ketat (3 detik) sebelum langsung beralih ke sesi lokal (*True Offline-First*). |
| **4** | `lib/ui/pending_approval_screen.dart:113` | Tombol "Ajukan Permohonan Akses" tidak memberikan *feedback* sukses setelah ditekan. | User tidak tahu apakah permohonan sudah terkirim, memicu penekanan tombol berulang (*rage tapping*). | Tampilkan dialog / SnackBar konfirmasi sukses: *"Permohonan akses berhasil dikirim ke Koordinator!"*. |
| **5** | `lib/application/sync_controller.dart:43` & `lib/data/sync_service.dart:404` | `pullRoutes()` dijalankan tetapi hasilnya tidak pernah di-merge ke `WorkspaceController` dan SQLite. `mergeCloudRoutesIntoLocal` tidak pernah dipanggil di `lib/`. | Status pil berubah hijau ("Sinkron"), tetapi data supir di HP tetap kosong / tidak bertambah (*Kebohongan Visual*). | Tangkap hasil `pullRoutes`, masukkan ke `mergeCloudRoutesIntoLocal`, dan simpan ke database SQLite lokal. |
| **6** | `lib/ui/driver_master_sheet.dart` | Tidak ada tombol **"Tarik Data Pramudi dari Cloud"** (*Missing Pull Feature*), hanya ada tombol Upload/Push. | Saat install APK di HP baru, dispatcher tidak bisa mengunduh 69 data supir JAK.115 yang ada di Supabase ke HP-nya. | Tambahkan tombol aksi "Tarik dari Cloud" di header Master Pramudi yang mengeksekusi alur *pull & merge*. |
| **7** | `lib/ui/driver_master_sheet.dart:124, 168` | Teks tooltip dan dialog masih bertuliskan **"Cloud Firebase"**. | Dispatcher dan tim teknis bingung karena database master supir saat ini resmi menggunakan Supabase. | Perbarui teks menjadi **"Cloud Supabase"** atau **"Cloud HEDGE"**. |
| **8** | `lib/ui/driver_master_sheet.dart:200` | Tidak ada validasi duplikasi nama panggilan (*call_name*) supir pada rute yang sama. | Supir bernama sama berisiko menimpa data satu sama lain di database cloud (*silent overwrite*). | Tambahkan validasi pencegahan duplikasi *call_name* sebelum form disimpan. |

---

## 2. Rencana Implementasi Perbaikan UX (Tahap Demi Tahap)

1. **Paket 1 — Error Handling & Sesi Login Ramah Pengguna:**
   - Filter pembatalan Google Sign-In agar tidak memunculkan kotak merah.
   - Terjemahkan pesan teknis menjadi saran tindakan nyata bagi dispatcher.
   - Tambahkan *timeout* 3 detik pada `restoreSession()` agar aplikasi langsung terbuka cepat saat offline.
   - Tambahkan dialog/SnackBar sukses pada pengajuan izin akses.
2. **Paket 2 — Kesempurnaan Sinkronisasi 2 Arah (Pull & Push Supabase):**
   - Buat fungsi `pullDriversFromCloud()` di `WorkspaceController` yang menyambungkan `pullRoutes` dengan `mergeCloudRoutesIntoLocal`.
   - Tambahkan tombol "Tarik dari Cloud" berdampingan dengan tombol "Setorkan ke Cloud" di `DriverMasterSheet`.
   - Perbaiki label teks Firebase menjadi Supabase pada dialog sinkronisasi.
3. **Paket 3 — Validasi Form & Integritas Data:**
   - Validasi nama panggilan supir agar tidak terjadi duplikasi pada rute yang sama.
