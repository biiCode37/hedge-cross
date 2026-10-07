# Build APK HEDGE 2.0.4 (Cyber-Transit Polish & HUD Update) — 2026-10-07

User menginstruksikan membangun APK terbaru setelah penyelesaian penyesuaian:
1. **Clockwise Depleting Gauge**: Indikator cincin hitung mundur Live Hero Card berputar mengikis searah jarum jam (*clockwise depleting*) menuju waktu berangkat (00:00).
2. **Breathing Room Padding**: Padding interior lingkaran di sekeliling teks waktu dan label diperlebar serta ketebalan cincin dirampingkan menjadi `size.width * 0.07` sehingga teks tidak lagi berhimpitan dengan ring.
3. **Penyederhanaan Papan HEDGE**: Menghapus badge dekoratif `FIDS KIOSK` dan icon monitor agar bilah jam dan tanggal lebih lega dan tidak berdesakan.
4. **Futuristic Cyber Timeline**: Penyempurnaan linimasa vertikal baik pada daftar jadwal utama maupun Papan HEDGE TV Screen.

Source **2.0.4+7** selesai diverifikasi dan ketiga APK debug split-per-abi berhasil dibangun pada branch **devmode**.

## Paket APK Terverifikasi di `dist/`

| Paket | Target Perangkat | Ukuran | SHA-256 |
| --- | --- | --- | --- |
| [ARM64](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm64.apk) | Android 64-bit (Utama / HP Dispatcher) | 88.8 MB (93,155,005 byte) | `554211fc203d075343061c1ed7983e60eed04eb780bdb8186dc2e1717ab4e13e` |
| [ARM32](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-arm32.apk) | Android 32-bit (HP Lama / Tablet Entry) | 69.0 MB (72,357,823 byte) | `cb62c56c3aa2120c5da21d2aabebaeb5bc553a8090ce85f5e948a94ad2d3dfc3` |
| [x64](file:///D:/MINE/HEDGE-FLUTTER/dist/HEDGE-v2-trial-x64.apk) | Emulator / Android x86_64 | 75.4 MB (79,075,372 byte) | `fd57d1c1a62a915446f798079af88a50b552edb8f9265b1fb4e3a7192e144e3a` |

Checksum keluaran build diverifikasi cocok dengan `dist/SHA256SUMS.txt`.

## Checklist Verifikasi Kualitas

- [x] `flutter build apk --debug --split-per-abi` selesai dengan exit code 0.
- [x] SHA256 checksums diverifikasi valid.
- [x] Branch aktif: `devmode`.
- [x] `flutter analyze`: **0 issues found**.
- [x] `flutter test`: **66/66 test cases passed**.
