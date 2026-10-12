# 01. Temuan Bug & Permasalahan — Header Redundan, Ritase Statis & Ketiadaan Aksi Massal Armada

Dokumen ini memuat analisis mendalam akar masalah (*root cause*), aliran data (*data flow*), dan kendala ergonomi operasional terkait redundansi date picker di jadwal, penomoran ritase statis, serta ketiadaan kontrol batch pada manifest armada HEDGE (Headway Generator).

---

## 1. Ringkasan Eksekutif Temuan

Dalam operasional harian armada mikrotrans di lapangan, ditemukan tiga kendala signifikan:

1. **Redundansi Date Picker di Halaman Jadwal Utama:**
   - Halaman jadwal menampilkan tombol pemilih tanggal (`showDatePicker`) dan indikator teks `Lokal` pada baris atas.
   - Pada kenyataannya, dispatcher di lapangan hanya berfokus pada rute aktif dan pergerakan armada saat bertugas. Tanggal kerja merupakan konteks global yang jarang diubah-ubah.
   - Keberadaan baris tanggal ini memakan ruang vertikal layar smartphone (terutama resolusi kecil 360dp) yang sangat berharga untuk melihat timeline headway dan armada berikutnya.

2. **Penomoran Ritase Statis Selalu Dimulai dari Rit 1:**
   - Generator jadwal ([`Scheduler.generate()`](file:///d:/MINE/HEDGE-FLUTTER/lib/domain/scheduler.dart)) secara kaku menghitung nomor putaran dengan rumus `round: (i ~/ units.length) + 1`.
   - Di lapangan, pembuatan jadwal sering dilakukan pada pergantian shift (misal shift siang) atau ketika armada masuk di tengah hari saat operasional riil sudah berjalan di **Rit ke-3** atau **Rit ke-4**.
   - Akibatnya, badge ritase di timeline dan kartu telemetri menampilkan **R1** padahal armada sebenarnya sedang menjalankan **R3** di lapangan. Terjadi ketidaksinkronan data antara sistem dan kondisi nyata lapangan.

3. **Ketiadaan Kontrol Multi-Select / Operasi Massal pada Halaman 02 Armada:**
   - Untuk menonaktifkan 10 unit yang sedang tidak beroperasi atau membersihkan beberapa armada sekaligus, dispatcher terpaksa mengetuk tombol toggle switch satu per satu sebanyak 10 kali.
   - Setiap ketukan memicu satu siklus update rute dan simpan database individual.
   - Tidak ada tombol *Pilih Semua* (*Select All*), *Aktifkan Massal*, *Nonaktifkan Massal*, maupun *Hapus Massal dengan Konfirmasi*.

---

## 2. Analisis Akar Masalah (Root Cause Analysis)

### A. Asumsi Desain Tanggal yang Monolitik
- Date picker diletakkan di header halaman jadwal tanpa mempertimbangkan prioritas ergonomi dispatcher smartphone di lapangan. Menghilangkan baris ini menghemat ~40dp ruang vertikal, langsung menaikkan visibilitas kartu timeline keberangkatan.

### B. Rigiditas Domain Model `PlanConfig`
- `PlanConfig` tidak memiliki atribut penentu ritase awal (`startRound`). Nilai ronde selalu di-offset dari 1.
- `Scheduler.generate()` dan `Scheduler.replan()` tidak memiliki parameter yang memungkinkan ritase awal melompat ke nomor dinas tertentu.

### C. Aliran Data Atomic pada Mutasi Armada
- `WorkspaceController` sebelumnya hanya menyediakan `setUnitActive(route, unit, active)` dan `deleteUnit(route, id)` per individu.
- Mutasi berulang membebani I/O SQLite (`save`) dan memicu banyak notifikasi state Riverpod ke widget tree. Diperlukan mutasi massal `setUnitsActive` dan `deleteUnits` yang berjalan dalam 1 transaksi atomic tunggal.
