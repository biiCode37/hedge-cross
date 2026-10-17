# Perbaikan dan Solusi Kode: Kustomisasi Template TTS

## 1. Arsitektur Solusi
Solusi diimplementasikan secara menyeluruh (*end-to-end*) melintasi lapisan Dart (Domain & UI), Platform Channel, serta Android Native Kotlin (Engine & TTS Player):

```
┌─────────────────────────────────────────────────────────────────┐
│                     FLUTTER UI & DOMAIN                         │
│  - AlarmPreferences: prepTemplate & dueTemplate                 │
│  - ConfigurationSheet: Preset Dropdown, Chips Quick Insert,     │
│    Live Audio Test Button                                       │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                   MethodChannel: testSpeech(map)
                   SharedPreferences JSON: buildAlarmPlan()
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ANDROID NATIVE (KOTLIN)                      │
│  - AlarmSpeechText: Parser variabel {rute}, {unit}, {detik},   │
│    {jam}, {ritase}. Auto-silence {rute} jika single-route.      │
│  - Unit Pronunciation: Penguraian cerdas 4 digit terakhir       │
│    (belasan, puluhan, ratusan, ribuan dispatcher).              │
│  - AlarmEngine & DeliveryService: Integrasi template dinamis   │
│    ke Audio Focus & TextToSpeech engine.                       │
└─────────────────────────────────────────────────────────────────┘
```

## 2. Modifikasi Kode Detail

### A. Lapisan Domain Dart (`lib/domain/models.dart` & `lib/domain/alarm.dart`)
- Menambahkan properti `prepTemplate` dan `dueTemplate` pada kelas `AlarmPreferences` lengkap dengan nilai default:
  - `prepTemplate`: `"{rute} unit {unit}, {detik} detik lagi."`
  - `dueTemplate`: `"{rute} unit {unit}, saatnya berangkat."`
- Menambahkan flag `isMultiRoute` pada payload alarm untuk mendeteksi apakah sistem sedang melayani lebih dari satu rute.
- Menambahkan `prepTemplate`, `dueTemplate`, dan `isMultiRoute` ke serialisasi JSON `AlarmEvent.toJson()`.

### B. Dynamic Parsing Engine Kotlin (`AlarmSpeechText.kt`)
- Dibuat helper objek `AlarmSpeechText` yang bertugas:
  - `unitLast4(fleetNumber)`: Mengambil 4 digit angka terakhir dari armada (misal `JAK.115-0865` -> `865`).
  - `pronounceIndonesianNumber(number)`: Melafalkan angka ke dalam bahasa Indonesia alami:
    - `0..9`: "nol" s.d. "sembilan"
    - `10..19`: "sepuluh", "sebelas", s.d. "sembilan belas"
    - `20..99`: "dua puluh satu", "enam puluh lima", dll.
    - `100..999`: "delapan ratus enam puluh lima"
    - `1000..9999`: "seribu delapan ratus enam puluh lima"
  - `routeCode(routeName)`: Membersihkan simbol menjadi format ringkas (misal `JAK.115` -> `JAK 115`).
  - **Auto-Context Single Route:** Jika `!isMultiRoute`, tag `{rute}` dan frasa `rute {rute}` otomatis dieliminasi tanpa meninggalkan tanda baca yatim piatu.
  - Substitusi variabel: `{rute}`, `{unit}`, `{detik}`, `{jam}`, `{ritase}`.

### C. Platform Channel Live Audio Preview (`notification_service.dart` & `MainActivity.kt`)
- `NotificationService.testSpeech` diperluas menerima parameter opsional:
  - `prepTemplate`, `dueTemplate`, `stage`, `isMultiRoute`.
- `MainActivity.kt` meneruskan parameter tersebut ke `AlarmDeliveryService.ACTION_TEST_SPEECH` sehingga dispatcher dapat langsung mendengarkan hasil racikan template di perangkat asli.

### D. Cockpit MFD UI & Chip Variabel (`lib/ui/configuration.dart`)
- Menambahkan kartu pengaturan suara TTS di tab `DISPATCH ALARM`:
  - **Dropdown Preset:**
    1. *Ringkas (Rekomendasi):* `"{rute} unit {unit}, {detik} detik lagi."` / `"{rute} unit {unit}, saatnya berangkat."`
    2. *Super Singkat (Pos Pantau Cepat):* `"{rute} {unit}, {detik} detik."` / `"{rute} {unit}, jalan!"`
    3. *Standar Formal:* `"{rute} unit {unit}, segera bersiap..."`
    4. *Kustom:* Otomatis terpilih jika user mengedit teks bebas.
  - **Tombol Chip Cepat:** Chip interaktif (`+ {rute}`, `+ {unit}`, `+ {detik}`, `+ {jam}`, `+ {ritase}`) yang menyisipkan tag tepat di posisi kursor teks.
  - **Tombol Uji Suara:** Memainkan pratinjau audio TTS secara langsung.
  - **Banner Info:** Memberitahu bahwa `{rute}` otomatis hening jika rute aktif hanya 1.
