# Overlay dan TTS pintar — source 2.0.3+4

Implementasi mengikuti keputusan user: izin tampil di atas aplikasi lain disetujui; volume mengikuti **pilihan B**, yaitu volume Alarm Android tanpa diubah aplikasi; kalimat TTS dan aturan angka di bawah disetujui. Setelah user memerintahkan melanjutkan pekerjaan dan build, ketiga APK dist **2.0.3** berhasil dibangun pada 2026-10-06 dan sudah memuat overlay/TTS ini. Lihat [laporan build terbaru](build-2.0.3-2026-10-06.md).

## Kalimat dan nomor unit

- Persiapan: **Segera berangkat, Rute [rute], unit [nomor], berangkat dalam [sisa waktu] detik.**
- Keberangkatan: **Rute [rute], unit [nomor], saatnya berangkat.**
- Dua digit terakhir diproses lebih dahulu: 11–19 sebagai belasan; 10 sebagai sepuluh; 20, 30, …, 90 sebagai puluhan; lainnya per digit. Sisa awalan dibaca per digit, menggabungkan pasangan 11–19 dari kiri ke kanan. Nol di depan dipertahankan. Huruf pada identitas unit tetap ada.

| Unit | Ucapan |
| --- | --- |
| 1865 | delapan belas enam lima |
| 2213 | dua dua tiga belas |
| 1870 | delapan belas tujuh puluh |
| 630 | enam tiga puluh |
| 111 | satu sebelas |
| 2113 | dua satu tiga belas |
| 1113 | sebelas tiga belas |

Sisa detik dihitung ketika ucapan akan dikirim ke mesin TTS, dibulatkan ke atas. Persiapan yang sudah melewati jam rencana tidak dibacakan sebagai nol detik. Tiap tahap dibacakan sekali, antrean due diprioritaskan, dan penanda ucapan yang sudah dimulai disimpan secara native untuk mencegah pengulangan setelah restart layanan. Beberapa rute dibacakan bergiliran selama masih aktif. Ucapan berhenti saat timeout, OFF, aktual, atau tahap persiapan digantikan due. Durasi alert yang terlalu pendek dapat memotong kalimat; sesuaikan durasi dengan kebutuhan lapangan.

## Tampilan dan suara Android

- **HEDGE aktif / layar terkunci:** Activity alarm native, dengan warna/tema dan tombol yang sama seperti sebelumnya.
- **Aplikasi lain terbuka:** overlay Android melalui izin **Tampilkan di atas aplikasi lain**, hanya selama ada alert aktif. Overlay ditutup ketika layar terkunci, layar tidak interaktif, Activity HEDGE tampil, fitur OFF atau durasi habis. Tidak memakai Accessibility Service.
- Activity dan overlay menggunakan `AlarmSurface` yang sama: nomor unit pertama, countdown kedua, jam WIB, rute/ritase, tombol **Sudah Berangkat**, OFF dan timeout. Keduanya mendukung tema gelap/terang/sistem.
- Layanan foreground sementara menangani overlay dan TTS. Tipe mediaPlayback digunakan untuk suara; specialUse menjelaskan alert dispatcher sementara. Layanan berhenti ketika tidak ada alarm/preview yang perlu ditangani. Antrean masa depan tetap dikelola AlarmManager.
- Notifikasi channel v3 tidak memutar ringtone default. TTS Android memakai suara **Bahasa Indonesia offline** yang tersedia, atribut audio Alarm dan gain pemutar 1.0. Tidak ada `setStreamVolume`/`adjustStreamVolume`: volume sistem mengikuti pilihan user. Tidak menambahkan nada pembuka yang belum disepakati.
- Fokus audio diminta selama ucapan. Fokus yang ditolak, engine/voice yang belum tersedia dan kegagalan overlay ditampilkan pada status perangkat. Tidak mengklaim TTS tetap terdengar saat sistem/panggilan menolak audio.
- Wake lock dibatasi sampai masa aktif alert, maksimum sekitar durasi 300 detik plus waktu cleanup; dilepas ketika layanan berakhir. Snapshot aktif di-cache agar tick UI tidak mem-parsing seluruh jadwal berulang kali.

## Pengaturan & data → Izin alarm perangkat

Tersedia tombol izin overlay, **Uji suara TTS**, **Hentikan uji suara**, pengaturan suara Bahasa Indonesia dan pengaturan volume Android. Panel menampilkan level volume Alarm Android dan status TTS terakhir. Uji suara menggunakan unit contoh 1865/rute JAK.115, tidak mengubah jadwal atau ledger. Alarm operasional yang berbunyi mengambil prioritas di atas uji suara.

Jika mesin TTS atau suara Indonesia offline belum tersedia, pasang/aktifkan suara melalui pengaturan TTS Android lalu uji lagi. Kualitas dan ketersediaan suara bergantung engine/voice perangkat. Aplikasi tidak memaksakan volume maksimum, tidak mengubah keluaran Bluetooth/headset, dan tidak melewati DND.

## Batas dan verifikasi perangkat

Belum ada pengukuran loudness atau uji runtime HP fisik untuk source ini. Model HP, versi Android, keluaran audio dan pengaturan volume perangkat user belum diketahui. Karena itu perbaikan jalur audio tidak dianggap bukti bahwa keluhan suara kecil sudah teratasi pada HP user.

Setelah memasang APK 2.0.3, uji:

1. Izin notifikasi, alarm tepat, layar penuh dan overlay; pencabutan izin saat alert aktif.
2. Alert ketika foreground, home screen, aplikasi lain, layar terkunci, swipe recent dan proses dihentikan OS. Aplikasi/layer sistem tertentu dapat menyembunyikan overlay; Force Stop tetap membutuhkan aplikasi dibuka kembali.
3. TTS tujuh contoh di atas; persiapan dengan sisa waktu aktual, due, beberapa rute, tombol aktual, OFF, timeout dan prep yang digantikan due.
4. Volume Alarm rendah/maksimum, Bluetooth/headset/speaker, DND dan panggilan aktif; pastikan HEDGE tidak mengubah volume sistem.
5. Mesin TTS dimatikan atau suara offline belum tersedia; status harus menjelaskan masalah. Uji suara dihentikan atau digantikan alarm operasional tanpa mencatat aktual.
6. Tema gelap/terang, ukuran teks besar, rotasi, serta tombol/scroll overlay pada HP yang digunakan.

Rujukan: [overlay Android](https://developer.android.com/reference/android/view/WindowManager.LayoutParams#TYPE_APPLICATION_OVERLAY), [full-screen intent dan heads-up](https://developer.android.com/develop/ui/views/notifications/time-sensitive), [foreground service](https://developer.android.com/develop/background-work/services/fgs/service-types), [pengecualian exact alarm untuk layanan background](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start), [TTS Android](https://developer.android.com/reference/android/speech/tts/TextToSpeech).

## Verifikasi tanpa build APK

```bash
cd /d/MINE/HEDGE-FLUTTER
git branch --show-current
flutter analyze --no-pub
flutter test --no-pub
pnpm run verify:legacy
cd android
JAVA_TOOL_OPTIONS='-Djdk.net.unixdomain.tmpdir=D:/MINE/HEDGE-FLUTTER/.tmp -Djava.net.preferIPv4Stack=true' ./gradlew.bat :app:compileDebugKotlin :app:testDebugUnitTest --console=plain
```

## Hasil verifikasi source 2.0.3

- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub`: **52/52 PASS**, termasuk panel izin/TTS pada tema gelap/terang, 320×640, teks 160%.
- `:app:compileDebugKotlin :app:testDebugUnitTest`: **sukses; 16/16 PASS** (8 tes antrean + 8 tes ucapan). Tidak menjalankan assemble/package APK.
- `pnpm run verify:legacy`: **53/53 PASS**, app.js tidak berubah.
- Kedua repository tetap **devmode**; `git diff --check` tidak menemukan error whitespace. Tidak commit, merge atau install.
- Pada akhir verifikasi source sebelum perintah build, APK dist masih **2.0.2**. Setelah perintah user, build **2.0.3** berhasil; metadata, signature, aset dan checksum ketiga APK lulus pemeriksaan sebagaimana [laporan build](build-2.0.3-2026-10-06.md).

Kompilasi dan unit/widget test tidak menggantikan uji loudness, overlay, background, lock-screen dan TTS pada HP fisik. Hasil runtime tersebut belum diverifikasi.

## File ditambah/diubah

- [android/app/src/main/AndroidManifest.xml](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/AndroidManifest.xml>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmOverlay.kt>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechPlayer.kt>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt>)
- [android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt>)
- [android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechTextTest.kt](<D:/MINE/HEDGE-FLUTTER/android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechTextTest.kt>)
- [docs/alarm-changes.md](<D:/MINE/HEDGE-FLUTTER/docs/alarm-changes.md>)
- [docs/alarms.md](<D:/MINE/HEDGE-FLUTTER/docs/alarms.md>)
- [docs/migration/changed-files.md](<D:/MINE/HEDGE-FLUTTER/docs/migration/changed-files.md>)
- [docs/migration/implementation-status.md](<D:/MINE/HEDGE-FLUTTER/docs/migration/implementation-status.md>)
- [docs/overlay-tts.md](<D:/MINE/HEDGE-FLUTTER/docs/overlay-tts.md>)
- [lib/application/notification_service.dart](<D:/MINE/HEDGE-FLUTTER/lib/application/notification_service.dart>)
- [lib/ui/alarm_permissions.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/alarm_permissions.dart>)
- [lib/ui/configuration.dart](<D:/MINE/HEDGE-FLUTTER/lib/ui/configuration.dart>)
- [pubspec.yaml](<D:/MINE/HEDGE-FLUTTER/pubspec.yaml>)
- [README.md](<D:/MINE/HEDGE-FLUTTER/README.md>)
- [test/alarm_permissions_test.dart](<D:/MINE/HEDGE-FLUTTER/test/alarm_permissions_test.dart>)
