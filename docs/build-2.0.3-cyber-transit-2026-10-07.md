# Build APK HEDGE 2.0.3 (Cyber-Transit HUD Update) — 2026-10-07

User menginstruksikan membangun APK terbaru setelah penyelesaian desain dan implementasi **Cyber-Transit HUD Telemetry UI/UX**. Source **2.0.3+6** selesai diverifikasi dan ketiga APK debug split-per-abi berhasil dibangun pada branch **devmode**. Paket di `dist` memuat seluruh perombakan antarmuka operasional modern serta peningkatan alarm overlay & TTS pintar.

## Fitur Baru & Peningkatan yang Disertakan

1. **Cyber-Transit HUD Telemetry UI/UX**:
   - **Fleet Telemetry Pill Bar**: 3 kapsul telemetri horisontal (Unit Aktif, Ritase, Headway) dengan auto-scroll responsif untuk dispatcher.
   - **Live Capsule Hero**: Kartu keberangkatan centerpiece berbingkai neon glow, status badge dinamis (*WAKTU BERANGKAT* / *KEBERANGKATAN BERIKUTNYA*), ring hitung mundur berbasis `CustomPaint` (`CountdownRingPainter`), dan aksi sentuh satu jempol.
   - **Cyber Transit Timeline Schedule**: Linimasa rel transit vertikal (`TransitRailPainter`) menggantikan baris datar konvensional. Rel solid untuk armada berangkat, node aura berdenyut untuk armada aktif, dan garis putus-putus (*dashed line*) untuk jadwal mendatang.
   - **Papan TV / Board Monitor FIDS Matrix Table**: Tampilan layar lebar TV posko bergaya FIDS (*Flight Information Display System*) dengan jam digital format detik (`HH:mm:ss WIB`), kode rute, nomor unit raksasa 26–28px, dan badge status berdenyut (*BOARDING*, *BERSIAP*, *STANDBY*).
   - **Dukungan Dual-Theme & Tabular Figures**: Kontras tinggi pada Dark Mode & Light Mode serta font angka tetap sejajar tanpa jitter.
2. **Overlay & Smart TTS Enhancement**:
   - Pembacaan suara rute dua digit cerdas Bahasa Indonesia (belasan, puluhan, dan satuan).
   - Peringatan visual otomatis jika volume audio Android berada pada posisi hening (volume 0).

## Paket APK Terverifikasi di `dist/`

| Paket | Target Perangkat | Ukuran | SHA-256 |
| --- | --- | --- | --- |
| [ARM64](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm64.apk) | Android 64-bit (Utama / HP Dispatcher) | 122.8 MB (122,817,493 byte) | `e7865cd2dd6371176a4df691062a5258f1b6b2c28325d5aa3582b499453aad73` |
| [ARM32](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm32.apk) | Android 32-bit (HP Lama / Tablet Entry) | 102.0 MB (102,020,311 byte) | `65d63095eeb8464fb33309b7de1c3dc4cc3a6f2e24e8a26032cae1f1382c5b20` |
| [x64](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-x64.apk) | Emulator / Android x86_64 | 108.7 MB (108,737,856 byte) | `9e002ba5fb069dc800e9c0faebb412ea2d7ca6edc014627a43348dad39f41548` |

Hash keluaran build diverifikasi cocok dengan `dist/SHA256SUMS.txt`.

## Checklist Verifikasi Kualitas

- [x] `flutter build apk --debug --split-per-abi` selesai dengan exit code 0.
- [x] SHA256 checksums diverifikasi valid melalui `sha256sum -c SHA256SUMS.txt`.
- [x] Branch aktif: `devmode`.
- [x] `flutter analyze`: **0 issues found**.
- [x] `flutter test`: **62/62 test cases passed**.
- [x] `pnpm run verify:legacy`: **53/53 legacy oracle cases PASS**.
- [x] `./gradlew :app:testDebugUnitTest`: **BUILD SUCCESSFUL**.
