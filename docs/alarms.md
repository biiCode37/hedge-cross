# Alarm HEDGE — source 2.0.2

Aturan user: **LAKUKAN BUILD APK HANYA KETIKA SAYA PERINTAHKAN.** Aturan disimpan di AGENTS.md kedua repository. APK dist **2.0.2** berhasil dibangun pada **2026-10-06** setelah perintah eksplisit user. Lihat [paket dan bukti build](build-2026-10-06.md). Sesi implementasi sebelumnya 2026-10-05 hanya mengubah source.

## Pengaturan dispatcher

Di **Jadwal → Atur**, setiap rute memiliki:

| Pengaturan | Perilaku |
| --- | --- |
| Alarm rute | OFF membatalkan antrean dan alert aktif rute itu. ON mengaktifkan pengingat sesuai konfigurasi dan jadwal tersimpan. |
| Banner notifikasi | Memilih tampilan notifikasi biasa. |
| Alert layar penuh | Mengaktifkan Activity alarm native Android. Memerlukan notifikasi sistem sebagai pembawa full-screen intent, sehingga Android tetap dapat memakai banner saat layar sedang digunakan. |
| Pengingat sebelum berangkat | ON/OFF terpisah; lead time dapat diatur 1–300 detik. Nilai 0 dari data lama diperlakukan tanpa pengingat persiapan. |
| Alarm saat waktunya berangkat | ON/OFF terpisah untuk event tepat pada jam rencana. |
| Tutup alert otomatis | Durasi tampil 1–300 detik. Default mengikuti durasi rute yang tersimpan (8 detik pada data awal). |
| Suara / getaran | Dikendalikan per rute; pilihan Android/channel/DND tetap dihormati. |

Pengaturan alarm berlaku setelah **Simpan pengaturan**, tanpa membuat ulang jadwal. Mengubah jam, ritase, peak, roster atau urutan tetap memakai revisi jadwal baru. Pengaturan alarm tidak membuat fingerprint jadwal menjadi dirty.

Alert mempertahankan hierarki nomor unit → countdown → jam WIB → rute/ritase, dengan warna amber/cyan dan tema gelap/terang. **Sudah Berangkat** mencatat aktual pada saat tombol ditekan, termasuk jika unit benar-benar berangkat ketika pengingat persiapan masih tampil. Ini membatalkan persiapan dan alarm keberangkatan unit tersebut. **Timeout hanya menutup alert**, tidak mencatat aktual, tidak mengakui semua alarm dan tidak mematikan fitur. **Matikan alarm rute** menghentikan pengingat rute sampai user mengaktifkannya kembali.

Jika persiapan masih tampil ketika jam keberangkatan tiba, event due menggantikan persiapan untuk unit itu dan memulai durasi tampil baru. Beberapa rute dengan waktu sama disimpan sebagai alert terpisah; layar menampilkan jumlah alert aktif dan memprioritaskan due. Tidak menimpa alert rute lain. Setiap instance memiliki timeout sendiri.

## Arsitektur Android

- `buildAlarmPlan` mengirim semua event masa depan dari snapshot tersimpan, bukan hanya 48 event terdekat. Semua waktu merupakan instant UTC dari tanggal layanan WIB.
- `AlarmEngine` menyimpan plan, event yang sudah dikirim, alert aktif, penekanan tombol dan status OFF di SharedPreferences dengan commit. Ini terpisah dari SQLite sehingga receiver dapat berjalan tanpa Flutter engine.
- AlarmManager hanya menyimpan trigger berikutnya. Receiver mengirim alarm yang tiba, membatalkan alert kedaluwarsa, lalu menjadwalkan trigger selanjutnya. Antrean seharian tidak memerlukan aplikasi dibuka setiap 48 event.
- Dengan izin exact alarm, trigger menggunakan `setAlarmClock`, termasuk saat Doze. Tanpa izin exact, fallback waktu perkiraan tetap terlihat pada status; akurasi H-10 detik tidak dijanjikan. [Android: schedule alarms](https://developer.android.com/develop/background-work/services/alarms).
- Notification kategori ALARM, channel importance HIGH, full-screen intent dan Activity `showWhenLocked`/`turnScreenOn` memungkinkan alarm di layar terkunci. Activity ini menggunakan views/font lokal native, bukan dialog Flutter yang membutuhkan app aktif.
- Android 15+ memakai creator opt-in pada PendingIntent Activity. Izin POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, USE_FULL_SCREEN_INTENT dan keadaan channel ditampilkan melalui **Pengaturan & data → Izin alarm perangkat**.
- Receiver boot, update paket, perubahan jam/zona dan pemberian izin alarm tepat merekonstruksi trigger dari plan yang tersimpan. Jadwal berasal dari tanggal snapshot; tidak membuat jadwal hari berikutnya secara otomatis.
- Persiapan yang terlambat sampai melewati jam rencana dilewati; due yang terlambat satu menit atau lebih dilewati. Durasi tampil terpisah dari batas keterlambatan ini: alert 1 detik masih dapat ditampilkan 1 detik jika OS mengirimnya beberapa detik terlambat. Event yang sudah terkirim tidak diputar ulang.
- Timeout disimpan per instance, diikuti trigger cleanup native dan timer Activity. Notification Android 8+ juga diberi timeout sistem. Menutup karena timeout tidak menghasilkan ledger aktual.

Tombol native menulis tindakan ke antrean durable sebelum UI ditutup/notifikasi dibatalkan. Saat HEDGE dibuka/resume, tindakan divalidasi terhadap revisi, disimpan ke SQLite, lalu ID-nya diakui ke Android. Jika penyimpanan SQLite gagal, tindakan native tetap tersedia untuk retry. Catatan aktual dideduplikasi berdasarkan departure ID/kind. Tindakan dengan referensi revisi yang tidak dikenali tetap tersimpan di native queue; tidak dibuang diam-diam. Snapshot Flutter lama tidak boleh membatalkan penekanan OFF atau mengaktifkan ulang unit yang telah ditandai berangkat.

## Batas Android yang tidak dapat dijamin oleh aplikasi

| Kondisi | Perilaku yang dituju / batas |
| --- | --- |
| HEDGE sedang aktif | Receiver dapat membuka Activity alert secara langsung; izin sistem yang diperlukan tetap ditampilkan. |
| Background / layar terkunci / proses dihentikan OS | Antrean AlarmManager dan Activity native tidak membutuhkan proses Dart lama. Tampilan penuh bergantung izin dan keputusan Android/vendor. |
| Swipe dari recent apps | Pada Android standar tidak sama dengan Force Stop; perilaku vendor perlu diuji. |
| Sedang menggunakan aplikasi lain | Android dapat memilih heads-up banner meskipun full-screen intent diaktifkan. [Android: time-sensitive notifications](https://developer.android.com/develop/ui/views/notifications/time-sensitive#ongoing-notification). |
| Force Stop dari pengaturan Android | Android menempatkan paket dalam stopped state dan membatalkan pending intents. Alarm tidak dapat dijamin sampai user membuka aplikasi lagi; saat dibuka queue didaftarkan kembali. [Android: stopped state](https://developer.android.com/about/versions/15/behavior-changes-all#stopped-state). |
| Notifikasi/channel/full-screen/exact permission diblokir, perangkat mati atau pembatasan vendor | Aplikasi tidak mengesampingkan keputusan OS. Status izin membantu dispatcher memeriksa kondisi tersebut. |

Karena batas ini, janji “selalu tampil dalam setiap jenis kill dan hanya berhenti saat OFF” tidak mungkin diberikan. Implementasi mengikuti izin Android, bukan overlay yang mengabaikan OS atau aplikasi lain.

Pada iOS/Windows, alert penuh tersedia saat aplikasi aktif melalui fallback Flutter. Full-screen takeover di luar aplikasi tidak diklaim. iOS masih memakai 48 pengingat OS terdekat dan membutuhkan app aktif/resume untuk memperpanjang antrean.

## Verifikasi tanpa APK

Dari Git Bash:

```bash
cd /d/MINE/HEDGE-FLUTTER
git branch --show-current
flutter analyze --no-pub
flutter test --no-pub
pnpm run verify:legacy
cd android
JAVA_TOOL_OPTIONS='-Djdk.net.unixdomain.tmpdir=D:/MINE/HEDGE-FLUTTER/.tmp -Djava.net.preferIPv4Stack=true' ./gradlew.bat :app:compileDebugKotlin :app:testDebugUnitTest --console=plain
```

Perintah terakhir mengompilasi Kotlin/resources/assets yang dibutuhkan tes dan menjalankan unit test; tidak menjalankan assemble/package APK. Perintah tes ini tidak menghasilkan APK. Build APK 2.0.2 terpisah dilakukan 2026-10-06 atas perintah user.

Verifikasi perangkat fisik tetap diperlukan setelah memasang APK 2.0.2: beri ketiga izin, buat jadwal dekat waktu sekarang, uji H-10/custom lead dan due saat foreground/background/layar terkunci, swipe recent, penghentian proses biasa, Force Stop lalu buka lagi, reboot/unlock, OFF, timeout, tombol aktual, DND/channel diblokir, mode hemat daya, beberapa rute bersamaan dan konfigurasi durasi pendek/panjang. Catat model HP, versi Android, izin, waktu aktual trigger serta hasilnya. Unit test/kompilasi bukan bukti hasil matriks runtime ini.
Hasil 2026-10-05: analyzer **No issues found**, Flutter **50/50 PASS**, Kotlin compile/unit test **8/8 PASS**, harness pnpm **53/53 PASS**, branch kedua repository **devmode**. Widget full-screen diuji pada 320×640 dengan teks 160% di tema gelap/terang. Hash APK dist 2.0.1 tetap sama. [Status lengkap](<D:/MINE/HEDGE-FLUTTER/docs/migration/implementation-status.md>) dan [daftar perubahan](<D:/MINE/HEDGE-FLUTTER/docs/alarm-changes.md>) memisahkan bukti source dari matriks perangkat yang belum diuji.
