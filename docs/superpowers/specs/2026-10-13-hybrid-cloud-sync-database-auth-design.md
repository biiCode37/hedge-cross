# Spesifikasi Desain: Hybrid Cloud Sync & Dispatcher Authentication HEDGE

- **Tanggal:** 2026-10-13
- **Topik:** Sinkronisasi Master Data Rute & Armada (Hybrid Offline-First) serta Autentikasi Dispatcher
- **Target Platform:** Android (Smartphone Dispatcher Mikrotrans Utara) & Web/Cloud Backend (Supabase)
- **Status:** Dalam Perancangan (Brainstorming / Spec In-Progress)

---

## 1. Latar Belakang & Masalah

Saat ini, HEDGE menyimpan seluruh data rute, armada, dan jadwal keberangkatan secara eksklusif pada basis data lokal perangkat (`hedge_v2.sqlite` via Drift).
Akibatnya:
1. **Cold-Start Kosong saat Install Baru:** Jika aplikasi diinstal pada perangkat baru atau perangkat lain milik dispatcher, daftar rute dan nomor unit armada tidak ada (hanya memuat data contoh hardcode `JAK.115`).
2. **Tidak Ada Sinkronisasi Antar Perangkat:** Penambahan atau perubahan armada yang dilakukan oleh Dispatcher A di satu perangkat tidak dapat dinikmati oleh Dispatcher B di perangkat lain.
3. **Risiko Integritas Data:** Tanpa identitas pengubah (audit trail), perubahan armada tidak dapat dilacak siapa yang memperbarui.

---

## 2. Bagian 1: Arsitektur Data & Mekanisme Sinkronisasi (Hybrid Offline-First)

### 2.1. Prinsip Utama Arsitektur
1. **SQLite Lokal Tetap sebagai *Single Source of Truth* UI:**
   - Semua layar HEDGE (jadwal, rotasi unit, alarm headway) membaca dan menulis langsung ke database SQLite lokal di perangkat.
   - Aplikasi tidak pernah menunggu respons jaringan internet untuk menampilkan rute atau mencatat keberangkatan (100% instan dan bebas lag).
2. **Zero Cold-Start & Seed Data Resmi:**
   - Setelah akun petugas terverifikasi melalui login Google & whitelist, aplikasi langsung mengunduh master rute & armada dari Supabase.
   - Sebagai fondasi awal (*baseline*), katalog resmi Mikrotrans Utara disediakan di `assets/data/routes_catalog.json` untuk inisialisasi awal data master. Seluruh data ini terkunci rapat dan tidak dapat diakses sebelum otentikasi akun berhasil.
3. **Mekanisme Dua Arah (Two-Way Synchronization):**
   - **Tarik (Inbound/Pull):** Saat perangkat mendeteksi koneksi internet, background sync engine memeriksa versi / timestamp pembaruan terakhir di Cloud (Supabase). Perubahan rute atau penambahan unit dari cloud akan digabungkan (*merge*) ke SQLite lokal.
   - **Kirim (Outbound/Push via Outbox Pattern):** Setiap perubahan rute atau unit yang dilakukan di perangkat dicatat ke tabel `outbox` lokal (`status: 'pending'`). Background worker mengirimkan antrean ini ke Supabase saat sinyal stabil, kemudian menandainya sebagai `synced`.

### 2.2. Diagram Alur Data

```mermaid
flowchart LR
    subgraph Gate [Keamanan & Akses]
        AuthGate[Login Google & Whitelist Guard]
    end

    subgraph Local_Device [Penyimpanan HP]
        SQLite[(Drift SQLite Lokal)]
        Outbox[(Tabel Outbox)]
    end

    subgraph Sync_Engine [Background Engine]
        SyncWorker[Sync Service]
    end

    subgraph Cloud_Server [Supabase Cloud]
        CloudDB[(PostgreSQL Supabase)]
    end

    AuthGate -->|Setelah Terverifikasi| SQLite
    SQLite <==>|Operasional Instan & Offline| UI[Layar PDO / Rute]
    SQLite --> Outbox
    Outbox --> SyncWorker
    SyncWorker <-->|REST / Realtime| CloudDB
    SyncWorker --> SQLite
```

## 3. Bagian 2: Autentikasi Google Sign-In, Whitelist & Manajemen Sesi

### 3.1. Mekanisme Google Sign-In 1-Tap
- Menggunakan Google OAuth 2.0 (Google Sign-In) untuk pengalaman login instan (1 sentuhan tanpa input manual password/PIN).
- Mengambil identitas resmi: Email, Nama Lengkap, dan Foto Profil.

### 3.2. Whitelist & Kontrol Akses Terbatas (Authorized Dispatchers / PDO)
Untuk memastikan HEDGE hanya dapat diakses oleh personel resmi Mikrotrans Utara:
1. **Tabel Pengawas (`authorized_dispatchers`) di Supabase:**
   - Menyimpan daftar email yang diizinkan, role (`superadmin` / `admin` / `pdo`), dan status (`active`, `pending`, `blocked`).
   - `pdo`: Petugas Driving Order (lapangan).
   - `admin`: Koordinator Lapangan / Pengawas Pool.
   - `superadmin`: Pimpinan / IT Administrator.
2. **Validasi Berjenjang:**
   - Setelah user memilih akun Google, backend Supabase mencocokkan email dengan daftar whitelist.
   - **Jika Terdaftar & Active:** Sesi disahkan, data rute dan armada disinkronkan, status token disimpan permanen di HP.
   - **Jika Belum Terdaftar:** Akses ditolak secara elegan. Tampilkan halaman: *"Akun Belum Terdaftar. Hubungi Koordinator Lapangan"* dengan opsi kirim permohonan akses (*Request Access*) atau berganti akun Google.

### 3.3. Sesi Permanen & Operasional Offline Lapangan
1. **Zero-Lockout di Terminal:**
   - Koneksi internet hanya dibutuhkan satu kali saat login pertama kali setelah instalasi APK.
   - Token otentikasi dan status whitelist disimpan secara aman di perangkat lokal (`flutter_secure_storage`).
   - Setiap kali aplikasi dibuka pada hari-hari berikutnya, PDO langsung masuk ke antarmuka jadwal tanpa perlu internet atau login ulang.
2. **Audit Trail Otomatis:**
   - Setiap operasi penambahan/pengubahan rute atau nomor unit menyertakan referensi `added_by` dan `updated_by` (merujuk ke `authorized_dispatchers.id`).

---

## 4. Bagian 3: Struktur Skema Database (Supabase vs SQLite Lokal)

### 4.1. Prinsip Identitas & Relasi (Offline-First)
- **Dual Identifier (`id` dan `uuid`):**
  - `id BIGINT`: Primary Key auto-increment untuk efisiensi indeks internal relasional di server.
  - `uuid UUID`: Global Unique Identifier sebagai kunci sinkronisasi antara perangkat lokal (HP) dan Cloud untuk menghindari tabrakan ID auto-increment saat offline.
- **Relasi Unit ke Rute:** `master_units.route_uuid` merujuk ke `master_routes.uuid`.
- **Integritas Audit Trail:** Kolom `added_by` dan `updated_by` dibuat `NULLABLE` dengan aturan `ON DELETE SET NULL` agar penghapusan akun tidak merusak data historis rute maupun armada.
- **Fleksibilitas Masa Depan (`config JSONB`):** Menyimpan nilai default ritase, interval headway jam sibuk/normal, jam operasional awal/akhir, dan preset rute tanpa perlu migrasi DDL jika ada parameter baru.

### 4.2. DDL PostgreSQL Supabase

```sql
-- 1. Tabel Whitelist Petugas Driving Order (PDO) & Admin
CREATE TABLE authorized_dispatchers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('superadmin', 'admin', 'pdo')),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'pending', 'blocked')),
    added_by BIGINT REFERENCES authorized_dispatchers(id) ON DELETE SET NULL,
    updated_by BIGINT REFERENCES authorized_dispatchers(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 2. Tabel Master Rute
CREATE TABLE master_routes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    route_code TEXT NOT NULL UNIQUE, -- Contoh: 'JAK.115', 'JAK.117'
    route_name TEXT NOT NULL,        -- Contoh: 'Terminal Tanjung Priok - Pegangsaan Dua'
    color BIGINT NOT NULL DEFAULT 4294940672, -- Format ARGB 0xFFFF9800
    position INTEGER NOT NULL DEFAULT 0,
    config JSONB NOT NULL DEFAULT '{}'::jsonb, -- Preset headway, jam awal/akhir, ritase
    added_by BIGINT REFERENCES authorized_dispatchers(id) ON DELETE SET NULL,
    updated_by BIGINT REFERENCES authorized_dispatchers(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3. Tabel Master Unit Armada per Rute
CREATE TABLE master_units (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    route_uuid UUID NOT NULL REFERENCES master_routes(uuid) ON DELETE CASCADE,
    number TEXT NOT NULL,            -- Nomor unit, contoh: '1000', '1001'
    active BOOLEAN NOT NULL DEFAULT true,
    position INTEGER NOT NULL DEFAULT 0,
    added_by BIGINT REFERENCES authorized_dispatchers(id) ON DELETE SET NULL,
    updated_by BIGINT REFERENCES authorized_dispatchers(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_route_unit_number UNIQUE(route_uuid, number)
);
```

### 4.3. Pemetaan ke SQLite Lokal di Perangkat (`HedgeDatabase` Drift)
- Tabel lokal `routes` dan `units` menambahkan kolom pelacak sinkronisasi: `server_id`, `updated_at`, dan `sync_status` (`'synced'`, `'modified'`).
- Tabel `outbox` lokal mencatat setiap modifikasi lokal dengan format payload terstandar untuk dikirimkan ke endpoint Supabase.
- Tabel `settings` menyimpan identitas PDO aktif (`logged_in_user`), role, token autentikasi, serta timestamp sinkronisasi terakhir (`last_sync_timestamp`).

---

## 5. Bagian 4: Antarmuka UI/UX (Layar Login Google, Indikator Sinkronisasi, dan Manajemen Akses)

Sesuai identitas brand HEDGE (**Headway Generator By Mikrotrans Utara**) dan standar ergonomi jempol (*Thumb-First*):

### 5.1. Layar Login Utama (`LoginScreen`)
- **Tampilan:** Permukaan gelap futuristik (*Deep Obsidian Surface* `#070B12`) dipadukan dengan aksen *Amber Glow* `#FF9800` dan *Cyan Accent* `#00E5FF`. Mendukung dual-theme (Dark & Light).
- **Elemen Utama:** Tombol autentikasi Google besar setinggi **52px** yang mudah dijangkau satu jempol:
  - `[ G  |  Masuk dengan Akun Google ]`
- **Keamanan Ketat (Strict Gate):**
  - **TIDAK ADA tombol bypass offline pada instalasi baru.**
  - Pengguna luar yang mendapatkan APK tidak akan pernah bisa mengakses data rute atau jadwal jika akun Google-nya belum terdaftar dan disetujui di whitelist.
  - Koneksi internet hanya diwajibkan 1 kali saat proses login awal setelah instalasi APK baru.

### 5.2. Layar Penjaga Whitelist (`PendingApprovalScreen`)
Jika akun Google berhasil login namun belum terdaftar atau masih berstatus `pending` di tabel `authorized_dispatchers`:
- Menampilkan kartu status dengan avatar dan email pengguna (misal: `ahmad@gmail.com`).
- Badge status visual: **`Menunggu Izin Akses`** (Amber Glow).
- Pesan informatif:
  > *"Akun Google ini belum terdaftar dalam sistem resmi Petugas Driving Order (PDO) Mikrotrans Utara. Silakan ajukan izin atau hubungi Koordinator Lapangan."*
- Aksi:
  - `[ Ajukan Permohonan Akses ]`: Mengirim data email & nama pengguna ke Supabase dengan status `pending` agar dapat diverifikasi oleh Koordinator.
  - `[ Ganti Akun Google Lain ]`: Keluar dari sesi dan mencoba login dengan email lain.

### 5.3. Indikator Status Sinkronisasi di Dashboard (`SyncStatusPill`)
Di bagian header dashboard jadwal, terdapat indikator berbentuk *pill badge*:
- 🟢 **Hijau (*Synced*):** Terhubung ke cloud, data rute & armada mutakhir.
- 🟡 **Amber (*Offline / Pending Outbox*):** Mode offline (operasional harian tetap berfungsi 100%). Menampilkan jumlah antrean lokal jika ada perubahan unit yang belum terkirim.
- 🔄 **Cyan Berkedip (*Syncing*):** Menandakan proses pertukaran data sedang berlangsung di latar belakang.
- **Interaksi Tap:** Membuka *Bottom Sheet* informasi PDO bertugas:
  - Profil: Nama, Email, Role (`PDO` / `Admin` / `Superadmin`).
  - Tombol aksi cepat: *"Sinkronkan Sekarang"* (manual trigger) dan *"Keluar / Ganti Akun"*.

### 5.4. Panel Kontrol Khusus Admin (`AdminControlScreen`)
Hanya muncul jika akun yang login memiliki role `admin` atau `superadmin`:
- **Tab Kelola PDO:** Menampilkan daftar akun berstatus `pending` disertai tombol 1-ketukan untuk *"Setujui & Aktifkan"*.
- **Tab Master Data Rute & Armada:** Mengelola penambahan rute baru atau nomor unit resmi secara global langsung dari smartphone.

---

## 6. Skenario & Penanganan Kasus Khusus (Edge Cases)

1. **Kehilangan Sinyal di Lapangan (Post-Auth):**
   - Setelah login awal berhasil, token sesi dan hak akses disimpan permanen di `flutter_secure_storage`.
   - PDO dapat membuka aplikasi di hari-hari berikutnya, membuat jadwal dinas, dan membunyikan alarm headway secara instan tanpa terhalang ketiadaan sinyal internet.
2. **Perubahan Armada saat Offline:**
   - Jika PDO menambah/mengubah nomor unit saat offline, perubahan disimpan ke SQLite lokal dan dicatat ke tabel `outbox`.
   - Saat sinyal internet kembali aktif, engine sinkronisasi otomatis mem-push antrean ke Supabase menggunakan prinsip *Last-Write-Wins*.
3. **Akun Dinonaktifkan (`status: blocked`):**
   - Jika seorang petugas dinonaktifkan oleh Koordinator di Supabase, saat HP terhubung internet, token sesi lokal akan dicabut dan aplikasi kembali menampilkan layar login.

---

## 8. Konfigurasi Proyek Cloud Supabase Resmi (`hedge-cross`)

- **Nama Proyek:** `hedge-cross`
- **Project ID:** `mkffwfvaxuqifflpeaib`
- **Project URL:** `https://mkffwfvaxuqifflpeaib.supabase.co`
- **Region:** `ap-southeast-1` (Singapura)
- **Status:** `ACTIVE_HEALTHY`
- **Publishable API Key:** `sb_publishable_g0BlvGNUb-uK98bvgc0gmQ_ahCSH3xD`
- **Anon Legacy Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rZmZ3ZnZheHVxaWZmbHBlYWliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4ODg2OTIsImV4cCI6MjEwNzQ2NDY5Mn0.4qp-uyaR-JOfgKqCbuOdl6ez2u0pNAxBAjeDZJl0V5Q`
- **Data Awal (Seeded):**
  - `authorized_dispatchers`: 6 akun petugas terdaftar (termasuk superadmin `biicode37@gmail.com` dan `muhammadabyn37@gmail.com`).
  - `master_routes`: 18 rute resmi Mikrotrans Jakarta Utara (JAK.01 s.d. JAK.120).
  - `master_units`: 49 unit armada (39 armada JAK.115 + 10 armada JAK.117).




