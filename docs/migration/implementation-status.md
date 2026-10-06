# Status implementasi HEDGE native

Tanggal: 2026-10-05. User meminta implementasi langsung sambil menyepakati kekurangan berjalan. Semua implementasi dilakukan pada branch devmode di D:/MINE/HEDGE-FLUTTER. Main tidak disentuh. Source produksi web tidak dimodifikasi.

## Dokumen dipindahkan

hedge-v2-blueprint.md, current-state-evidence.md, scheduler-analysis.md, legacy-scheduler-reference.json dan verify-legacy-oracle.mjs telah disalin, dibandingkan dan dihapus dari lokasi lama. Empat dokumen/fixture sama byte demi byte. Harness hanya mengubah relative path dari ../../app.js menjadi ../legacy/app.js agar memakai sumber dibekukan. Tidak merekam ulang fixture; commit asal tetap d8edf44c45625bc93d2716e0e8e1c6c6265b3afe.

Source app.js dibekukan di docs/legacy/app.js dengan SHA-256 b2e7547a7ebdb817a55fdc0bde95b146866060a1db9ef4a0a5a4bd1085084bba. Link ke file web di dokumen analisis merupakan lokasi/provenance saat analisis, bukan source Dart baru.

## Irisan operasional yang diimplementasikan

Native runners Android/iOS/Windows; domain pure Dart; Riverpod controller; Drift/SQLite dengan transaksi, WAL dan foreign keys; draft terpisah dari snapshot; revisi immutable dengan parent ID; ID keberangkatan dan ledger aktual/ack; outbox lokal tanpa klaim sync; layar jadwal, armada, urutan, rute; papan gabungan, jam WIB dan wakelock; tema gelap/terang/sistem; JSON legacy v5 dan core v4 importer dengan preview, backup raw dan alarm off; backup native dengan semua histori; clipboard/share/TXT/XLSX/PDF dengan metadata shift/label ritase; adapter notifikasi OS rolling horizon.

## Keputusan sementara untuk memungkinkan implementasi

Ini keputusan implementasi konservatif, bukan persetujuan bisnis final:

1. Headway minimum satu menit dalam satu rute; validasi menolak jadwal simultan/nol/negatif. Non-peak feasible mempertahankan algoritma blok floor/ceil dan round-robin legacy.
2. Peak di-clamp ke window dan periode bersentuhan/overlap digabung dengan interval minimum. Durasi peak wajib kelipatan interval; segmen off-peak mendapat jumlah gap proporsional dan minimal satu gap. Batas tiap segmen dijaga; tidak ada padding/truncation/forced endpoint yang menyembunyikan infeasibility.
3. Satu keberangkatan menggunakan jam mulai. Jadwal lintas tengah malam ditolak sementara.
4. Replan menggunakan draft terbaru untuk ritase, end time, roster, urutan dan peak. Semua rencana yang waktunya <= sekarang dibekukan, bukan otomatis menjadi aktual. Baris baru mulai paling cepat menit berikutnya; splice headway dihitung ulang. Target ritase dikurangi berdasarkan planned prefix per unit ID.
5. Ack alarm berbeda dari departure actual. Frozen departure ID dipertahankan across revisions, sehingga actual/ack tidak hilang ketika replan.
6. Alarm impor mati sampai dispatcher memeriksa tanggal dan mengaktifkannya. Snapshot lama tanpa tanggal menerima tanggal yang dipilih secara eksplisit di UI import. Snapshot invalid dikarantina dengan warning, roster/config bisa disimpan; raw file tetap tersedia.
7. Duplicate/ambiguity identitas importer ditolak. Tidak ada fallback diam-diam ke data default saat import/read DB gagal. Default roster hanya untuk DB baru.
8. Native restore berupa merge ID ke instalasi baru/terpisah, bukan replace DB. Histori dan ledger diikutkan dalam backup; perubahan revisi yang sudah tersimpan tidak ditulis ulang.
9. Implementasi awal membatasi notifikasi ke 48 event terdekat. Source 2.0.2 mengganti Android dengan antrean native seluruh event masa depan; batas 48 dan replenishment saat aktif/resume tetap berlaku pada iOS. Perilaku Android di background/layar terkunci harus diuji pada perangkat fisik sesuai bagian terbaru di bawah.
10. Android debug/release sementara menggunakan signing debug untuk distribusi internal. Tidak ada publish/store submission.

## Bukti awal

- pnpm run verify:legacy: PASS 53/53 selected legacy function characterization. Ini bukan uji browser/native end-to-end.
- flutter test: 33/33 lulus setelah perbaikan layout 360 px. Termasuk 400 kombinasi fleet/ritase/grouping dalam satu invariant test, positive/exact boundaries, peak overlap, replan frozen prefix/splice/new draft, __proto__ ID, WIB/date validation, real SQLite reopen/rollback, backup+ledger, importer quarantine/duplicates, XLSX/PDF signatures, dan widget dark/light ukuran 360×800 serta 1200×800.
- Build Windows dicoba: Flutter belum menemukan suitable Visual Studio toolchain (Build Tools 2026 tersedia tetapi tidak sesuai instalasi yang dikenali Flutter). Tidak menginstal/mengubah toolchain global.
- iOS belum dibangun karena host Windows; perlu macOS/Xcode dan signing.
- Gradle pertama gagal Java NIO Unix-domain loopback; properti process-local jdk.net.unixdomain.tmpdir ke direktori workspace pendek memperbaiki startup.

Verifikasi final: flutter analyze --no-pub → No issues found; flutter test --no-pub → 33/33 PASS; build APK --debug --split-per-abi → sukses pada ARM64, ARM32 dan x86_64. Setelah perapihan kontrol UI, seluruh tes dan APK dibangun kembali dari source final. APK ARM64 telah diperiksa dengan aapt: package id.mikrotrans.hedge.hedge_flutter, versionName 2.0.0, label HEDGE, minSdk 24, targetSdk 36. Isi paket menyertakan libsqlite3.so ARM64, logo resmi, font Roboto dan manifest. Paket internal di dist/HEDGE-v2-trial-arm64.apk (sekitar 117 MiB); checksum ketiga paket di dist/SHA256SUMS.txt. Build debug ini tidak dipublish, belum dipasang pada perangkat fisik dan bukan rilis produksi. Keberhasilan uji widget, build dan inspeksi paket bukan bukti pengujian Android runtime/alarms penuh.

Preview kedua tema di docs/screenshots/ telah diperiksa secara visual. Ikon, logo, kontrol jadwal satu baris pada 360 px, kontras dan layout desktop terlihat sesuai. Perangkat fisik dan font-scale accessibility tetap perlu diuji. App belum selesai seluruh roadmap blueprint. Prioritas berikutnya setelah APK: uji lapangan Android dan alarm, penyempurnaan PNG/edit unit/bulk/history, pipeline build Windows/iOS, aturan peak/replan bersama dispatcher, kemudian layanan backend authenticated sync.
## Design system 2.0.1 — implementasi dan verifikasi terbaru

Keputusan brainstorming telah diimplementasikan: unit pertama (44 px dispatcher / 64 px papan lebar), countdown kedua (28/40 px), jam WIB ketiga dan metadata terakhir. ThemeExtension mengendalikan kedua tema; Material tidak lagi memakai palette seed/tint yang menggeser branding. Amber #FF9800, cyan #38BDF8, obsidian #070B12 dan silver #F8FAFC menjadi basis; tema terang memakai accent teks lebih gelap untuk kontras. Permukaan solid, radius terukur, tanpa gradient/blur/animasi berulang. Transisi tema 180 ms menghormati reduced motion; kontrol memakai target 48 px.

Countdown cyan dalam keadaan normal, amber <=60 detik, lalu “Waktu berangkat” pada nol. Fokus tetap pada unit tersebut selama durasi alarm (1–60 detik) tanpa otomatis mencatat aktual. Aktual dan ack tetap berbeda. Daftar jadwal/papan memakai consumer timer terpisah dan RepaintBoundary; pengujian membuktikan widget baris jadwal tidak dibangun ulang pada tick biasa. Ini bukan pengukuran FPS/baterai Android.

Bukti source final:

- `flutter analyze --no-pub`: **No issues found**.
- `HEDGE_CAPTURE=1 flutter test --no-pub`: **40/40 PASS**. Tambahan mencakup pasangan kontras >=4.5:1, fokus stabil/due hold/actual vs ack, countdown sub-detik, urgency 60 detik, identitas widget antar-tick, serta viewport 320×640 dengan teks 160% pada keempat tab dan papan. Pengujian lama 360×800 dan 1200×800 di kedua tema tetap lulus.
- `pnpm run verify:legacy`: **53/53 PASS**, salinan app.js tetap memiliki checksum asal dan branch devmode.
- `flutter build apk --debug --split-per-abi --no-pub`: **sukses** ARM64, ARM32 dan x64 dari source final 2.0.1+2.
- APK final di dist telah dibandingkan hash-nya dengan output build; tanda tangan **APK Signature Scheme v2 valid untuk ketiganya**.
- Inspeksi aapt ARM64: package `id.mikrotrans.hedge.hedge_flutter`, versionName **2.0.1**, versionCode **2002**, label HEDGE, minSdk 24, targetSdk 36, native-code arm64-v8a; SQLite, logo dan kedua font Roboto terkemas.
- Ukuran: ARM64 **93,014,128 byte** (~88.7 MiB), ARM32 **72,216,946 byte**, x64 **78,934,491 byte**. Build debug tetap memakai signing internal; bukan ukuran/artefak release produksi.
- Branch akhir kedua repository **devmode**. Source web D:/MINE/HEDGE bersih. Tidak ada commit, merge atau publish.

Checksum terbaru berada di [SHA256SUMS.txt](<D:/MINE/HEDGE-FLUTTER/dist/SHA256SUMS.txt>); APK siap uji di [ARM64](<D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm64.apk>), [ARM32](<D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm32.apk>) dan [x64](<D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-x64.apk>). Nama paket dist dipertahankan dan isinya diperbarui dari build 2.0.1.

[Design system](<D:/MINE/HEDGE-FLUTTER/docs/design-system.md>) memuat keputusan/token; [inventaris perubahan desain](<D:/MINE/HEDGE-FLUTTER/docs/design-system-changes.md>) menghubungkan setiap file perubahan. Keempat preview docs/screenshots diperbarui memakai Roboto dan ikon asli, data contoh serta clock tetap sebelum keberangkatan. Preview widget telah diperiksa secara visual. App masih membutuhkan uji Android fisik untuk performa, izin notifikasi, alarm dan perilaku perangkat; build Windows/iOS dan batas fitur roadmap tetap seperti bukti awal di atas.
## Alarm 2.0.2+3 — verifikasi source 2026-10-05, tanpa build APK sesi itu

Tanggal verifikasi: 2026-10-05. User menetapkan **LAKUKAN BUILD APK HANYA KETIKA SAYA PERINTAHKAN.** Aturan ditambahkan ke AGENTS.md kedua repository. APK dist/output 2.0.1 tidak dibangun ulang, tidak disalin ulang dan belum memuat perubahan bagian ini.

- Pengaturan per rute: banner/full-screen, persiapan dengan lead 1–300 detik, due, suara, getaran, serta auto-close 1–300 detik. Pilihan tersimpan di SQLite dan backup JSON; data lama tetap dapat dibaca. Pengaturan alarm berlaku tanpa regenerasi jadwal.
- Activity alarm native Android membawa nomor unit, countdown, jam WIB dan identitas rute dalam tema gelap/terang. **Sudah Berangkat** mencatat aktual; timeout hanya menutup instance. OFF membatalkan pengingat serta alert aktif rute.
- Antrean native durable menyimpan seluruh event masa depan, menjadwalkan trigger berikutnya melalui AlarmManager, dan dipulihkan receiver saat boot/update/perubahan waktu/izin. Tidak membutuhkan Flutter engine untuk menampilkan alarm ketika background/layar terkunci/proses biasa berhenti.
- Tindakan native disimpan sebelum UI ditutup, kemudian direkonsiliasi ke SQLite dan baru diakui setelah penyimpanan berhasil. Snapshot lama tidak mengaktifkan ulang OFF atau keberangkatan aktual. Dua tahap ini diuji untuk idempotensi dan referensi yang tidak dikenali.
- Panel izin perangkat menampilkan status notifikasi, alarm tepat, full-screen dan channel. Android dapat menampilkan heads-up saat perangkat sedang digunakan; Force Stop tetap membatalkan pending intents sampai user membuka aplikasi kembali. Implementasi tidak menjanjikan mengesampingkan keputusan OS.

Bukti final source 2.0.2:

| Pemeriksaan | Hasil |
| --- | --- |
| Branch kedua repository | **devmode** |
| `flutter analyze --no-pub` | **No issues found** |
| `flutter test --no-pub` | **50/50 PASS** |
| `:app:compileDebugKotlin :app:testDebugUnitTest` | **Sukses; 8/8 unit test PASS**, tanpa assemble/package APK |
| `pnpm run verify:legacy` | **53/53 PASS** |
| Widget alert gelap/terang | **320×640, teks 160%, PASS**; transisi prep/due, timeout, OFF dan aktual tercakup |
| Source web | Hanya AGENTS.md berubah; app.js tidak berubah |
| APK dist 2.0.1 | SHA-256 ketiga arsitektur tetap sama dengan SHA256SUMS.txt |

ARM64 SHA-256: `3a31a67f53c0cf0c92f8f21494447618c152533aa4d3ab01dc08cd9856af26ef`.
ARM32 SHA-256: `b44b8e302aba0404af9fe2e511879d30399edf60ef472b8f62ceeebebdde413d`.
x64 SHA-256: `79ac07896bd9aac3eecd5bd6bfe549837d3c920961a8c584af8b0dabe87c5e4c`.

Kompilasi memakai API kompatibilitas untuk Android lama dan menghasilkan beberapa warning deprecation Kotlin; analisis Dart tidak memiliki issue. Tidak ada commit, merge, install atau publish pada sesi alarm. Uji HP fisik untuk foreground/background/lock/process death, reboot, izin/channel/DND dan vendor belum dilakukan. Matriks uji itu menunggu perintah build APK dari user; keberhasilan unit test/kompilasi tidak membuktikan perilaku runtime tersebut.

Panduan konfigurasi, batas OS, sumber Android resmi dan langkah verifikasi tersedia di [alarms.md](<D:/MINE/HEDGE-FLUTTER/docs/alarms.md>); inventaris sesi tersedia di [alarm-changes.md](<D:/MINE/HEDGE-FLUTTER/docs/alarm-changes.md>). Bukti 2.0.0/2.0.1 di atas merupakan riwayat build sebelumnya, bukan izin atau hasil build APK sesi 2.0.2.

## Build APK terbaru 2026-10-06 — user memberi perintah eksplisit

Ketiga APK debug split ABI **2.0.2** berhasil dibangun dari source 2.0.2+3, lalu disalin ke dist dan dibandingkan hash-nya. Signature v2 valid dan sertifikat sama dengan 2.0.1. Version code naik: ARM64 2003, ARM32 1003, x64 4003. Package HEDGE, minSdk 24 dan targetSdk 36 terverifikasi. Manifest memuat Activity/receiver/full-screen permission dan flags layar terkunci; setiap paket memuat SQLite ABI, logo dan dua font Roboto.

`pnpm run verify:legacy` kembali **53/53 PASS**; kedua repository tetap **devmode**. Source aplikasi tidak berubah, sehingga bukti 50 tes Flutter/8 Kotlin/analyzer dan kedua tema 2026-10-05 tetap merupakan pemeriksaan source sebelumnya. Tidak mengulang tes tersebut, tidak memasang APK atau mengklaim uji fisik alarm. Percobaan awal build gagal DNS GitHub saat SQLite mengambil binary resmi; DNS pulih dan build ulang berhasil tanpa perubahan dependency.

Paket dist kini **2.0.2**, menggantikan 2.0.1. Riwayat checksum/hasil tanpa build pada bagian sebelumnya tetap merujuk sesi 2026-10-05. [Laporan build, hash dan daftar file terkini](<D:/MINE/HEDGE-FLUTTER/docs/build-2026-10-06.md>) mencatat hasil 2026-10-06. Aturan build hanya atas perintah eksplisit user tetap berlaku untuk build berikutnya.

## Riwayat verifikasi source 2.0.3+4 — sebelum perintah build

User menyetujui izin tampil di atas aplikasi lain, dua kalimat TTS Indonesia, aturan unit belasan/puluhan, serta pengelompokan dua digit terakhir untuk pola ambigu. Pilihan volume adalah **B: mengikuti volume Alarm Android tanpa mengubahnya**. Implementasi menambahkan layanan native sementara, overlay berizin dengan UI bersama Activity, suara TTS offline, penghentian audio sesuai status alarm, diagnosis volume dan tombol uji suara. Notifikasi baru tidak memutar ringtone bawaan. Alarm asli mengambil prioritas di atas preview suara.

Verifikasi final: **52/52 Flutter**, **16/16 Kotlin**, **53/53 legacy pnpm**, analyzer **No issues found**, branch kedua repository **devmode**. Widget panel izin diuji gelap/terang pada 320×640 dengan teks 160%; runtime overlay/native TTS dan loudness HP belum diuji. Tidak ada APK baru dibangun. Ketiga paket dist 2.0.2 tetap cocok dengan checksum sebelumnya dan belum memuat source 2.0.3.

[Keputusan, contoh angka, arsitektur, batas verifikasi dan daftar file](<D:/MINE/HEDGE-FLUTTER/docs/overlay-tts.md>) mendokumentasikan perbaikan ini. Build berikutnya tetap menunggu perintah eksplisit user.

## Build terbaru 2.0.3 — 2026-10-06

User memerintahkan melanjutkan pekerjaan yang terjeda dan membangun APK terbaru. Build debug split ABI dari source 2.0.3+4 berhasil (exit 0). Ketiga paket dist sekarang **2.0.3**, memuat overlay/TTS di atas, dengan code ARM64 **2004**, ARM32 **1004**, x64 **4004**. Signature v2 valid; sertifikat sama dengan APK 2.0.2. Manifest, library SQLite, font/logo dan checksum output serta salinan dist terverifikasi.

Source final sebelumnya lulus analyzer, **52 Flutter**, **16 Kotlin**, **53 legacy pnpm**, termasuk tema gelap/terang pada panel izin. Kedua repository tetap **devmode**. Tidak install, commit atau publish. Uji loudness, overlay dan TTS di HP fisik belum dilakukan. [APK, checksum, file berubah dan panduan uji](<D:/MINE/HEDGE-FLUTTER/docs/build-2.0.3-2026-10-06.md>) mencatat bukti terbaru. Build berikutnya tetap memerlukan perintah eksplisit user.
