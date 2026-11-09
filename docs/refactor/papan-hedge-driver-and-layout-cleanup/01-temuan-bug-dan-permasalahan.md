# Temuan Masalah: Tampilan Papan HEDGE (FIDS) Berantakan, Tertindih, dan Ketiadaan Informasi Pramudi

## 1. Konteks Masalah
Pada layar **Papan HEDGE (FIDS Kiosk Display)**, petugas dispatcher memantau giliran keberangkatan armada secara *real-time*. Berdasarkan bukti tangkapan layar pengguna:
1. **Label Statis "STANDBY" yang Berulang & Tidak Informatif:**
   Seluruh armada pada linimasa keberangkatan mendatang menampilkan label teks statis `[ STANDBY ]`, padahal dispatcher memerlukan informasi krusial mengenai **siapa Pramudi yang bertugas** membawa masing-masing armada tersebut.
2. **Ketiadaan Nama Pramudi pada Komponen Utama (Hero Focus Card):**
   Pada panel *Keberangkatan Berikutnya* di bagian atas, nomor unit (`KWK 222171`) tampil besar namun nama pramudi yang ditugaskan tidak ditampilkan di antara nomor unit dan lingkaran *countdown*.
3. **Tampilan Sisi Kanan Berantakan & Tertindih (Overflow Meluber):**
   Badge nama pramudi diposisikan dalam satu baris horizontal (`Row`) di sebelah kanan nomor unit yang berukuran raksasa (`fontSize: 26`). Akibatnya, badge supir memanjang ke kanan melebihi lebar kolom tengah (*unconstrained width*), lalu **menabrak, menimpa, dan menindih** angka jam hitung mundur dan label abu-abu `HITUNG MUNDUR` di kolom sebelah kanan.
4. **Sisi Kiri Dempet dan Pendaran Rel Meluber (*Bleeding Artifacts*):**
   - Kolom waktu memiliki lebar sempit (`width: 58`) dengan jarak vertikal mepet ke kode rute.
   - Pendaran efek pendaran neon (*glow aura*) pada node rel vertikal (`TransitRailPainter`) menggunakan radius blur sebesar 6px dan lingkaran luar berlebih, sehingga cahaya cyan dan amber tumpah (*bleeding*) ke teks waktu di sebelah kiri dan nomor armada di sebelah kanan.
   - Kolom kanan `HITUNG MUNDUR` hanya dialokasikan lebar sempit `width: 68`, menyebabkan teks `HITUNG MUNDUR` (lebar ~75px) terkompresi dan terpotong.
