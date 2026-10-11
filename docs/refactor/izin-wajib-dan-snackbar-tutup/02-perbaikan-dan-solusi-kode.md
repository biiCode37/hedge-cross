# 02. Perbaikan & Solusi Kode — SnackBar Undo & Gerbang Perizinan Wajib (Permission Gate)

Dokumen ini memuat detail arsitektur solusi teknis dan cetak biru kode (*code blueprint*) untuk perbaikan banner notifikasi SnackBar serta implementasi gerbang perizinan wajib (*Permission Gate*).

---

## 1. Arsitektur Solusi

### Solusi 1: Pembuatan Komponen `showDepartureUndoSnackBar`
- **File:** [`lib/ui/dispatch_components.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart)
- **Desain & Spesifikasi:**
  - Floating SnackBar dengan radius 14px dan border tematik (`p.cyanInk` pudar di Dark Mode, `p.border` di Light Mode).
  - Background surface adaptif (`#0C1017` Deep Obsidian di Dark Mode, `#FFFFFF` di Light Mode).
  - Teks informatif dua baris: judul "Keberangkatan Tercatat" (Cyan) dan detail "Unit $unitNumber telah diberangkatkan".
  - Tombol **"BATALKAN"** beraksen Amber dengan border rounded.
  - Tombol **"X" (Close Icon Button)** khusus untuk menutup SnackBar seketika via `ScaffoldMessenger.of(context).hideCurrentSnackBar()` tanpa membatalkan pencatatan.
  - Terapkan di 3 titik pemanggilan:
    1. [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart) pada `DepartureFocusPanel.onDispatch`
    2. [`lib/ui/app.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/app.dart) pada `ScheduleDepartureTile.onRecord`
    3. [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart) pada `BoardScreen` focus dispatch

---

### Solusi 2: Komponen Layar `PermissionGate` (Gatekeeper Mandatori)
- **File:** [`lib/ui/permission_gate.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/permission_gate.dart)
- **Alur Kerja:**
  1. Saat aplikasi dibuka pada Android (`isAndroid == true`):
     - Masuk ke state `_checking = true` dan tampilkan antarmuka pemeriksaan ("Memeriksa Perizinan Sistem... Mohon tunggu sebentar").
     - Jalankan `service.refreshStatus()`.
     - Jika izin notifikasi belum diberikan, panggil `service.requestPermission()` untuk memunculkan dialog runtime Android.
  2. Evaluasi 4 Izin Wajib:
     - `notifications`: Izin notifikasi Android.
     - `exact`: Izin alarm tepat (`canExact`).
     - `fullScreen`: Izin alert layar penuh (`canFullScreen`).
     - `overlay`: Izin tampil di atas aplikasi lain (`canDrawOverlays`).
  3. Logika Pemblokiran:
     - Jika ke-4 izin **terpenuhi**: Otomatis buka akses dan render `child` (`HomeScreen`).
     - Jika **ada salah satu/beberapa izin belum terpenuhi**: Akses ke `HomeScreen` diblokir sepenuhnya. Tampilkan layar peringatan mandatori.
  4. Antarmuka Layar Blokir:
     - Kartu status untuk masing-masing dari ke-4 izin dengan indikator status jelas (DIIZINKAN vs BELUM AKTIF).
     - Tombol aksi spesifik pada tiap izin yang belum aktif untuk langsung membuka halaman pengaturan sistem yang tepat di Android via `service.openPermission(kind)`.
     - Tombol utama "PERIKSA ULANG SEMUA IZIN".
  5. Deteksi Otomatis Saat Kembali ke Aplikasi:
     - Mengimplementasikan `WidgetsBindingObserver.didChangeAppLifecycleState`.
     - Saat dispatcher kembali ke HEDGE setelah mengaktifkan izin di menu Settings Android (`AppLifecycleState.resumed`), aplikasi otomatis memverifikasi ulang perizinan tanpa mengharuskan restart app.
