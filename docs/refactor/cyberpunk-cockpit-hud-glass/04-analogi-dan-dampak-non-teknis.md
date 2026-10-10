# 04 — Analogi & Dampak Non-Teknis: Cyberpunk Cockpit HUD Glass

## 1. Analogi Dunia Nyata: Kokpit Jet Tempur F-35 vs Panel Sakelar Biasa

Bayangkan seorang pilot jet tempur modern yang sedang melakukan misi berkecepatan tinggi:
- **Sebelum Refactor:**
  Dashboard pesawat diisi tombol-tombol radio plastik rumah tangga biasa dari berbagai merk yang berbeda. Di satu sisi ada sakelar AC rumahan, di sisi lain ada remote TV biasa. Tampilannya tidak konsisten, informasi penting terselip di balik panel datar, dan dalam kondisi silau matahari atau guncangan, mata pilot kesulitan membedakan prioritas informasi.
- **Sesudah Refactor (Kokpit F-35 Glass MFD):**
  Seluruh kabin kini seragam menggunakan panel digital kaca avionik terintegrasi (*Glass Cockpit Multi-Function Display*). Setiap panel dibingkai bingkai pelindung taktis beveled 45° dengan sudut penanda neon khusus. Warna Electric Cyan menunjukkan status sistem operasional normal, sedangkan Tactical Amber menyala otomatis saat ada unit atau sektor yang butuh perhatian. Di bagian bawah, tombol MFD taktis dengan nomor fungsi militer (`01`, `02`, `03`, `04`) memungkinkan perpindahan instrumen dengan satu ketukan jari tanpa perlu berpikir panjang.

---

## 2. Dampak Langsung bagi Dispatcher di Lapangan

1. **Konsistensi Visual di Segala Kondisi Cuaca (Day & Night Operations):**
   - Di bawah terik matahari siang hari di terminal (mode Polar Slate Light), garis kontras border neon dan tipografi tebal memastikan nomor unit dan jam keberangkatan tetap terbaca jelas tanpa perlu memicingkan mata.
   - Di malam hari (mode Obsidian Dark), warna dasar hitam pekat dipadukan dengan aksen pendaran lembut mencegah silau dan kelelahan mata operator yang bertugas berjam-jam.
2. **Operasi Satu Jempol (Thumb-First Ergonomics):**
   - Navigasi MFD bawah berjarak ideal dari jangkauan jempol dispatcher saat memegang ponsel Android dengan satu tangan di lapangan yang ramai.
   - Tombol geser urutan unit (`Naik`, `Turun`, `Drag`) memiliki ukuran responsif yang pas sehingga tidak saling tumpang tindih meskipun diakses di layar kecil.
3. **Penyampaian Hierarki Status Instan:**
   - Unit yang aktif menyala dalam pendaran cyan, sementara unit cadangan/nonaktif tampil dalam amber. Dispatcher cukup melirik 0,5 detik untuk mengetahui armada mana yang siap meluncur dan armada mana yang sedang istirahat.
