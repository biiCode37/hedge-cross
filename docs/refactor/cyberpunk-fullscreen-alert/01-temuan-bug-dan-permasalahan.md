# 01. Temuan Bug & Permasalahan — Blank Space Masif & Dialog Alert Fullscreen Keberangkatan

Dokumen ini memuat laporan audit visual dan fungsional terhadap komponen dialog alert layar penuh (*Fullscreen Alarm Dialog / Overlay*) pada lapisan Flutter ([`ForegroundAlarmOverlay`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/alarm_overlay.dart)) dan lapisan native Android ([`AlarmActivity`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmActivity.kt) & [`AlarmSurface`](file:///d:/MINE/HEDGE-FLUTTER/android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt)).

---

## 1. Ringkasan Eksekutif Temuan

Meskipun halaman **JADWAL** dan mode **Papan HEDGE** telah menerapkan standar desain **Cyber-Transit HUD** (palet Obsidian `#070B12`, Amber Glow `#FF9800`, Electric Cyan `#00E5FF`, font monospaced futuristik, dan kontras ganda tinggi), komponen alert layar penuh saat keberangkatan armada mengalami beberapa masalah kritis UI/UX:

1. **Rongga Kosong Masif (*Massive Blank Space* ~250–300dp):**
   - Kartu informasi keberangkatan armada mengambang terisolasi di paruh atas layar dengan tinggi fixed yang pendek.
   - Tombol-tombol tindakan terdorong jauh ke bagian paling bawah layar (*extreme bottom anchor*).
   - Di antara kartu dan deretan tombol tindakan, tercipta jurang kosong tak terpakai setinggi lebih dari 250dp. Hal ini menyebabkan proporsi UI tampak janggal, kerdil, dan tidak memanfaatkan real estat layar smartphone dispatcher secara optimal.

2. **Inkonsistensi Estetika & Skalabilitas Typografi:**
   - Komponen countdown dan nomor armada berukuran relatif kecil dibandingkan besarnya layar perangkat. Pada jarak pandang operasional dispatcher (30–60 cm dari dasbor atau meja kerja), dispatcher kesulitan membaca armada mana yang harus segera diberangkatkan secara sekilas (*at-a-glance visibility*).
   - Indikator timeout otomatis hanya berupa progress bar tipis 3dp di header dan teks sederhana, tanpa visualisasi circular telemetry terpadu.

3. **Defisiensi Ergonomi Lapangan (Jebakan UX "Matikan Alarm Rute"):**
   - Saat pop-up alert muncul, sebelumnya hanya tersedia 2 tombol: *"Sudah Berangkat"* dan *"Matikan alarm rute"*.
   - Jika armada belum siap meluncur (misal pengemudi masih menunggu penumpang di shelter) dan dispatcher hanya ingin menutup pop-up alert sementara waktu, dispatcher tidak memiliki tombol *Tutup Alert* sementara.
   - Akibatnya, dispatcher secara keliru menekan *"Matikan alarm rute"*, yang mematikan alarm seluruh rute tersebut sepanjang hari operasional.

4. **Konflik Dua Model Tampilan Alert Berbeda (*Dual Alert Conflict*):**
   - Metode `AlarmEngine.openWhenForeground()` secara keliru meluncurkan `AlarmActivity` (Activity native Android) ketika `MainActivity` (Flutter) sedang aktif di foreground.
   - Hal ini memicu rendering ganda dua tampilan berbeda secara bersamaan yang tumpang tindih dan membingungkan pengguna di lapangan.
