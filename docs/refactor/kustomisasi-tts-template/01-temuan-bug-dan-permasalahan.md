# Temuan Masalah & Keterbatasan TTS Bawaan

## 1. Konteks Masalah
Sebelum perbaikan ini dilakukan, Text-to-Speech (TTS) alarm keberangkatan Mikrotrans pada aplikasi HEDGE dikonfigurasi dengan kalimat statis (*hardcoded*) di lapisan native Android (`AlarmDeliveryService.kt` dan `AlarmSpeechPlayer.kt`).

Format kalimat bawaan yang dilafalkan sistem adalah:
1. **Fase Persiapan (*Preparation* / Sebelum Berangkat):**
   > *"Segera bersiap, rute JAK.115 dengan nomor armada nol delapan enam lima, akan diberangkatkan dalam tiga puluh detik."*
2. **Fase Jatuh Tempo (*Due* / Saatnya Berangkat):**
   > *"Perhatian, rute JAK.115 dengan nomor armada nol delapan enam lima, saatnya berangkat sekarang."*

## 2. Masalah di Lapangan (Pain Points Dispatcher)
1. **Terlalu Panjang & Bertele-tele:**
   - Kalimat memakan waktu 5–7 detik untuk dibacakan oleh mesin TTS. Di lingkungan terminal/pos pantau yang bising dan dinamis dengan headway pendek (2–5 menit), kalimat panjang mengaburkan informasi inti dan mengganggu komunikasi radio antar kru.
2. **Nomor Unit Tidak Alami (*Unnatural Fleet Pronunciation*):**
   - Format asli melafalkan digit per digit ("nol delapan enam lima"), padahal dispatcher di lapangan selalu memanggil dengan kaidah angka singkat ("delapan enam puluh lima" atau "delapan ratus enam puluh lima").
3. **Penyebutan Rute yang Redundan di Titik Pengendapan Tunggal:**
   - Di pos pantau yang hanya mengoperasikan 1 rute (misal hanya JAK 115), menyebutkan nama rute di setiap alarm keberangkatan terasa mubazir dan membuang waktu.
4. **Ketiadaan Fleksibilitas Pengguna:**
   - Dispatcher maupun koordinator lapangan tidak memiliki opsi untuk mengubah, menyederhanakan, atau mengatur variabel apa saja yang ingin diperdengarkan via pengeras suara.
   - Tidak ada tombol pintas untuk menyisipkan variabel dan tidak ada tombol pratinjau audio langsung (*live speech test*).

## 3. Analisis Akar Masalah Teknis (Root Cause)
- **Hardcoded String di Native:** String pesan dirakit langsung di `AlarmDeliveryService.kt` tanpa membaca preferensi rute dari payload alarm SharedPreferences.
- **Model AlarmPreferences Belum Mendukung Template:** Objek Dart `AlarmPreferences` dan `AlarmEvent` hanya menyimpan boolean `sound`, tanpa atribut `prepTemplate` maupun `dueTemplate`.
- **Platform Channel Terbatas:** Channel Method `testSpeech` tidak menerima parameter template maupun tahapan simulasi suara.
