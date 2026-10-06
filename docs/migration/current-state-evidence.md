# HEDGE — Bukti current state: state, UI, dispatch, alarm, export, dan migrasi

Tanggal analisis: **5 Oktober 2026 (Asia/Jakarta)**. Checkout yang dibaca: **`devmode`**. Dokumen ini adalah appendix discovery untuk blueprint HEDGE v2; tidak mengubah production source atau membuat implementasi Flutter.

**Penanda:** **Fakta** berarti langsung terlihat pada source; **Inference** berarti konsekuensi dari alur kode, belum klaim hasil uji device; **Rekomendasi** berarti rancangan target, bukan perilaku existing.

## 1. Cakupan dan entry point

Seluruh `app.js` (3.111 baris) dan `index.html` (2.244 baris) dibaca, termasuk constructor, persistence, mutasi, rendering, scheduler call sites, recalculation, board, countdown, alarm, export, dan initialization. Backend/PWA dan rincian oracle scheduler dibahas dalam appendix lain/blueprint utama. Audit ini tidak menyatakan sudah menjalankan uji browser, screen reader, atau OS background alarm.

| Entry point | Fakta dan hubungan kode |
| --- | --- |
| HTML document | `index.html:1–29`: bahasa Indonesia, manifest, icon, Google Fonts, lima vendor globals dari CDN. `index.html:2233`: memuat `app.js` setelah DOM. |
| App closure | `app.js:1–200`: satu IIFE, helper DOM `$`, constructor/defaults, `loadState()`, mutable `state`. Tidak ada module boundary untuk state/domain/infrastructure. |
| Bootstrap UI | `app.js:3081–3111`: header height → route bar → hydrate input → unit list → summary → order list → restore committed schedule, atau auto-generate rute aktif yang belum mempunyai jadwal. |
| Master timer | `app.js:2655–2669`: `masterTick()` dipanggil langsung dan melalui `setInterval(..., 1000)`; memperbarui clock, board jika terbuka, cockpit, lalu alarm. |
| PWA registration | `index.html:2235–2241`: service worker didaftarkan pada `load`, hanya HTTPS atau hostname `localhost`; kegagalan ditelan. |

Vendor UI dan export tidak berasal dari runtime `pnpm` import: `XLSX` 0.18.5, `Sortable` 1.15.2, `html2canvas` 1.4.1, `jsPDF` 2.5.1, dan `SweetAlert2` 11.10.5 muncul sebagai scripts di `index.html:25–29`. Mereka dapat memengaruhi availability offline dan error paths; PWA assessment utama menjelaskan cache.

## 2. Source of truth dan bentuk state aktual

### 2.1 Root state

**Fakta:** `STORAGE_KEY = 'jadwalApp_multi_v5'`; legacy key `'jadwalApp_v4'` (`app.js:4–5`). Schema version tersirat pada nama key, bukan field versi dalam payload. Persisted root menyimpan:

```text
RootState
  activeRouteId
  routes[]
  papanMode = 'active' (stored, tetapi tidak dipakai controller board)
```

`defaultState()` (`app.js:88–114`) membuat dua rute:

- JAK.115: 39 unit, 05:00–22:00, target ritase 8, peak nonaktif, amber.
- JAK.88: 12 unit, 05:30–21:30, ritase 6, peak 06:00–08:30 setiap 4 menit dan 16:30–19:00 setiap 5 menit, blue.

Default departure order mengikuti urutan hard-coded roster (`app.js:8–9`, `44–55`). Bootstrap hanya auto-generate rute yang aktif (`app.js:3101–3107`), bukan semua default routes.

### 2.2 Route aggregate yang sebenarnya

| Field | Peran aktual | Sifat |
| --- | --- | --- |
| `id`, `name`, `color` | Identitas route, display label, pembeda visual | Persisted; ID tidak divalidasi unik lintas route. |
| `jamMulai`, `jamSelesai` | Jam lokal `HH:mm` satu hari | Editable configuration; tidak mempunyai tanggal, offset hari, timezone. |
| `ritase` | Target jumlah departure per eligible unit | Editable configuration; input UI membatasi 1–30. |
| `groupOrder` | Mengelompokkan interval pendek/panjang di setiap zona | `fast-first` / `slow-first`; bukan urutan unit. |
| `peakEnabled`, `peak1Start/End/Interval`, `peak2Start/End/Interval` | Dua peak configs | Editable configuration; interval UI 1–60 menit. |
| `masterUnits[]` | Roster milik route | Objek `{id, number: string, active: bool}`; bukan entity fleet global. |
| `departureOrder[]` | Ordered unit IDs untuk round-robin | Persisted input scheduler, harus selaras active roster. |
| `committedSchedule` | Snapshot jadwal terakhir yang diterima | Persisted operational plan, terus dipakai ketika konfigurasi dirty. |
| `scheduleDirty` | Ada perubahan input setelah snapshot mempunyai rows | Persisted boolean; tidak menghitung semantic difference. |
| `alarmEnabled`, `alarmDuration`, `alarmPrepSeconds` | Preferences alarm route | Persisted; change tidak menandai dirty. Durasi UI 1–30 detik; persiapan 0–60 detik. |
| `activeInSchedule` | Keikutsertaan pada jadwal/monitor/alarms/export | Bukan semata visibility. False menghilangkan route dari semua jalur operasional itu. |
| `lastShift`, `lastRitaseFrom` | Preferensi export | Shift tidak mengubah scheduler; offset ritase hanya label output. |

Constructor `createRouteObject()` berada di `app.js:11–86`. Unknown route name yang tidak mempunyai `masterUnits` mewarisi default roster JAK.115. Route duplication mempunyai new unit IDs dan mereset order ke active roster, tidak mempertahankan custom departure order (`app.js:690–718`, `798–824`). Dua jalur duplicate tidak identik: tombol di active strip menyalin alarm preferences, tombol route manager tidak (`707–710` versus `804–817`).

### 2.3 Committed schedule dan projection

`generateScheduleForRoute()` (`app.js:1728–1748`) memanggil scheduler lalu menyimpan:

```text
CommittedSchedule
  rows[] = {no, ritase, unit, jam, interval, isPeak,
            routeId, routeName, routeColor}
  N, R
  startLabel, endLabel
  peakEnabled, segmentsInfo[]
  recalcBoundaryIndex? , lastRecalcLabel?
```

**Fakta:** departure tidak punya stable ID, `unitId`, tanggal operasi, createdAt, acceptedAt, revision ID, actor, actual departure time, status, atau policy/algorithm version. `unit` menyimpan nomor tampilan. Label route didenormalisasi di rows, lalu board gabungan/alarm menimpa label/color menggunakan metadata route saat ini (`app.js:2090–2096`, `2642–2647`).

`reconstructDisplaySchedule()` (`app.js:1750–1765`) membuat projection `totalDep = rows.length` dan `totalMinutes = endLabel - startLabel`; ia tidak menghitung ulang engine. `lastSchedule` (`app.js:1670`) adalah cache projection dalam memory, bukan source of truth kedua yang independen.

`buildCombinedSchedule()` (`app.js:2082–2116`) melakukan clone rows dari setiap participating route dengan committed rows, sort menurut menit jam dan `routeName.localeCompare`, lalu memberikan `combinedNo`. Ia tidak mengubah jadwal route, tidak menghitung headway terminal, tidak melakukan resource/collision arbitration, dan tidak menyinkronkan antar device.

### 2.4 Ephemeral UI state

`selectedUnitIds`, `unitFilter`, `unitSearchQuery`, `sortableInstance`, `papanMode`, `lastPapanNextIdx`, `lastDismissedIdx`, `firedRowKeys`, `activeAlarmRows`, timers, `audioCtx`, dan `wakeLockSentinel` hanya memory (`app.js:1061–1063`, `1423–1424`, `2126–2129`, `2294`, `2337`, `2401–2404`). Root persisted `papanMode` tidak dibaca untuk initialize runtime `papanMode`; runtime selalu mulai `'active'` (`app.js:113`, `130`, `2126`). Tidak ada listener `storage` untuk mengatasi dua tab menulis state yang sama.

## 3. Trace alur end-to-end

### 3.1 Startup dan restore

```text
index.html memuat vendor globals + DOM + app.js
  → loadState()
      → parse v5 routes → normalize constructor
      → jika tidak ada v5 valid, parse v4 → normalize legacy
      → fallback defaults jika parse/normalization throw
  → state in memory
  → renderRouteBar/getActiveRoute
  → hydrateInputs/renderUnitList/updateActiveSummary
  → renderOrderList (memperbaiki order DAN saveState)
  → restore committed snapshot, atau generate active route
  → setiap detik projection clock/countdown/alarm
```

**Fakta:** restore bukan read-only. `renderOrderList()` menulis normalized order dan whole root ke storage (`app.js:1438–1445`). **Inference:** jika payload rusak jatuh ke default, bootstrap dapat menimpa v5 asli dengan default tanpa menyimpan backup, meskipun `loadState()` hanya mengeluarkan console warning.

### 3.2 Edit config/roster/order → dirty → commit

1. Time/peak input change, ritase, group order, activation/add/delete unit, order movement langsung mutasi route object dan `saveState()`.
2. `markDirtyIfCommitted()` hanya menandai dirty bila snapshot memiliki nonempty rows (`app.js:250–257`); ia tidak meregenerate.
3. UI header/pills menunjukkan configuration terbaru, sedangkan rows, alarm, export, dan board masih menggunakan committed snapshot.
4. Generate rute meminta confirmation bila ada snapshot, menghitung full day dari editable configuration, mengganti snapshot dan menghapus dirty (`app.js:1849–1875`). Tidak ada archival revision; dialog menyebut menghapus histori hari ini.
5. Generate semua loop participating routes dan commit masing-masing berhasil secara terpisah (`app.js:1877–1909`). Gagal salah satu route tidak rollback routes lain. Error toast menyebut nama, tidak failure detail dari engine.

**Rekomendasi:** v2 perlu memisahkan `DraftHeadwayConfig` dan immutable accepted `ScheduleRevision`, dengan explicit acceptance transaction dan visible diff. `dirty` sebaiknya derived dari draft version/fingerprint dibanding accepted config, bukan flag manual yang bisa clear padahal sebagian input belum diterapkan.

### 3.3 Route participation dan navigation

`removeRouteFromSchedule()` (`app.js:378–398`) menjaga minimal satu participating route, mengubah false, menyimpan, dan memilih route lain bila current route dihilangkan. Route tetap tersimpan. Permanent delete hanya pada route manager, dengan confirmation, selama total route > 1 (`app.js:826–839`).

`getActiveRoute()` (`app.js:202–218`) memilih hanya route `activeInSchedule !== false`, lalu fallback ke first participating route. Jika semua tersembunyi, ia mengaktifkan `routes[0]` otomatis. **Inference:** tombol “Buka” pada hidden route (`app.js:780–782`) tidak dapat mengedit hidden route melalui selection saja, karena `switchActiveRoute()` memanggil `getActiveRoute()` yang memilih route lain. Aktifkan hidden route terlebih dahulu.

**Rekomendasi:** pisahkan `selectedRouteId` (navigation), `route.isArchived`, dan `servicePlan.includedRouteIds`. Jangan menjadikan perubahan tab/visibility sebagai perubahan alarm eligibility tanpa status operasional yang jelas.

### 3.4 Roster dan departure order

- `addUnit()` (`app.js:1401–1417`) menolak number yang sama secara exact string setelah trim dalam route, membuat ID Date/random, active true, append ke roster dan order.
- Individual activation menggunakan dual lookup ID atau number, append saat aktif, remove saat inactive (`app.js:1205–1228`). Delete individual menghapus semua match ID **atau** number (`1243–1275`).
- Bulk activate/deactivate/delete menggunakan selected IDs dan menyimpan sekali per tindakan (`1278–1355`). Search/filter/select-all bekerja pada filtered roster, selection lain dapat tetap tersimpan (`1065–1082`, `1362–1376`).
- `renderOrderList()` menghapus missing/inactive IDs dan append missing active units; ia tidak menghapus duplicate order IDs (`1438–1445`).
- Arrow reorder swap adjacent, save, dirty, rerender (`1470–1501`). Sortable multi-drag mengambil order dari DOM; `onEnd` memperbarui nomor urut, tetapi tidak rebind `data-idx` arrow buttons yang dibuat sebelumnya (`1516–1523`). **Inference:** segera setelah drag, arrow buttons dapat memakai index sebelum drag sampai list dirender ulang.

**Rekomendasi:** domain command `SetDepartureOrder` menerima unique permutation seluruh eligible assignments dan menolak missing/duplicate references. Rendering harus pure; reconciliation harus explicit application command/migration stage.

### 3.5 Recalculate remaining

Alur `recalcRemaining()` (`app.js:1914–2015`):

1. Require nonempty committed rows.
2. Ambil wall clock device, minute precision; reject sebelum/sama `cs.startLabel` atau sesudah/sama `cs.endLabel`.
3. `history = rows.filter(jam <= nowMin)`; **ini time-past planned rows, bukan bukti unit sudah berangkat**.
4. Hitung completedCount berdasarkan **unit number**.
5. Gunakan **committed `cs.R`**, bukan draft `route.ritase`; end tetap **committed `cs.endLabel`**, bukan draft end.
6. Eligible units/order terbaru dari route → remaining `max(0, cs.R - countedHistory)` → round-robin queue starting next per-unit ritase.
7. Jika queue kosong, simpan history saja, mark boundary, clear dirty, reset all alarm tracking.
8. Jika queue ada, `buildTimeline(nowMin, oldEndMin, queue.length, latestPeak, latestGroupOrder)` → future rows mulai pada **nowMin**.
9. Mutasi snapshot menjadi `history.concat(futureRows)`, update boundary/lastRecalc/N; clear dirty; persist; reset alarm tracking; render.

Konsekuensi yang harus didokumentasikan sebelum business decision:

- Draft ritase dan jam selesai bisa tampil baru tetapi recalc tetap old R/end, lalu dirty clear (`1931`, `1978`, `2004`). Draft jam mulai juga tidak diterapkan.
- Historical rows dianggap completed walau alarm belum dismissed, route offline, atau unit terlambat/tidak jalan.
- Rows pada minute sekarang masuk history; future pertama juga minute sekarang, sehingga bisa ada dua departure pada same minute dan historical alarm dapat refire setelah reset.
- Historical last `interval` masih menunjuk old future row; tidak diperbaiki menjadi gap menuju new future (`2000`).
- `segmentsInfo`, committed `peakEnabled`, `startLabel/endLabel`, dan committed R tidak diganti dengan hasil recalc; render dapat menampilkan summary pattern lama (`2000–2005`).
- Unit yang dinonaktifkan/dihapus tetap pada history; new unit mendapatkan full old R. Number reuse/duplicate data dapat membuat completedCount milik unit lain.
- Snapshot dimutasi in place; revision sebelumnya hilang. Label “histori” bukan audit trail.

**Rekomendasi:** remaining scheduler menjadi pure function menerima accepted revision, explicit actual dispatch ledger (atau legacy elapsed inference mode), candidate configuration, eligible assignments, cutoff instant, freeze policy, dan deterministic clock input. Output adalah candidate revision + diff + warnings; application menerima atomic revision. Policy terhadap target ritase/end-day yang diedit dan row tepat cutoff harus diputuskan, bukan disalin diam-diam.

### 3.6 Dispatch board dan countdown

`openPapanModal()` (`app.js:2374–2386`) require rows, show overlay, render, request screen Wake Lock, mencoba fullscreen. `closePapanMode()` melepas lock, beep timer, fullscreen (`2388–2397`). Visibility handler hanya mencoba reacquire wake lock jika board visible (`2348–2352`); tidak catch-up alarms atau dispatch events.

Board single route reconstruct snapshot; combined board rebuild projection (`2149–2155`). UI route subtitle pada single mode memakai draft start/end/R, walaupun rows berasal accepted snapshot (`2177`). Board date adalah tanggal device saat render, bukan date jadwal (`2162`).

`updatePapanHighlight()` (`app.js:2296–2329`) memilih next row dengan prioritas:

```text
activeAlarmRows ada       → minimum _idx
lastDismissedIdx >= 0     → lastDismissedIdx + 1
lainnya                  → first row.jam >= current minute
```

Semua row sebelum index dianggap “done”; semua rows done jika tidak ada next. Setiap tick men-toggle class seluruh rendered rows dan mencoba scroll center. Setelah ada dismissed pointer, pemilihan next tidak lagi mencari clock; missed alarm dapat menyebabkan board tertahan pada departure yang sudah lewat.

`updatePapanCountdown()` (`2247–2292`) membuat Date dari **today + row HH:mm + seconds0**, membulatkan delta detik, clamp0, menampilkan `SEDANG BERANGKAT` saat delta <= 0. Red state memakai selected route `alarmPrepSeconds`; positive delta <= prep menyalakan double beep tiap dua detik dan vibrate. Seluruh waktu di luar threshold ditampilkan yellow-alert, tidak hanya one-minute warning.

`updateCockpitHud()` (`app.js:2969–3055`) menggunakan rule berbeda: row masih next sampai **30 detik setelah jamnya** (`3014`); “SIAP JALAN” hardcoded <=60 detik (`3041`). Cockpit tidak memakai lastDismissedIdx. Ia terus memperbarui seluruh table DOM, juga saat tab jadwal tidak aktif. Saat semua selesai, `departed` class justru tidak dipasang karena syarat `nextIdx !== -1` (`3052`).

**Rekomendasi:** satu pure `DispatchProjection(now, acceptedPlan, actualEvents)` dengan stable departure IDs dipakai mobile HUD/desktop board. Tick hanya mengganti visible countdown; list status berubah berdasarkan row identity. Sediakan suspend/resume catch-up dan time-quality state.

### 3.7 Alarm

`checkAlarmTriggers(now)` (`app.js:2629–2653`) iterasi semua participating, alarm-enabled routes yang mempunyai snapshot; row due hanya bila `row.jam === current HH:mm`. Memory dedupe key adalah `routeId|row.no|row.jam|row.unit`. Alarm bekerja meskipun board tertutup dan meskipun route dirty.

`addRowsToAlarm()` (`2598–2611`) menggabungkan simultaneous due rows, dedupe active overlay menggunakan `routeId+unit+jam`, sort jam/no, show overlay, chime setiap 900ms, Indonesian speech, vibration, auto-stop. `ensureAudioCtx()` membuat/resume Web Audio pada pointerdown (`2415–2422`). Beep memakai oscillator/gain (`2424–2437`). Speech number formatter (`2452–2557`) memakai penyebutan nomor, bukan angka matematika biasa; contohnya teens/puluhan diperlakukan khusus.

`dismissAlarm()` (`2613–2627`) digunakan baik tombol **“OK, Sudah Berangkat”** maupun auto-stop (`2595`, `index.html:2229`). Ia menghentikan chime, menyembunyikan overlay, mengambil max `_idx` sebagai global `lastDismissedIdx`, clear active rows, refresh board. **Tidak ada persistence, actual time, actor, status departed, ataupun audit event.** `window.speechSynthesis.cancel()` hanya ada saat announcement baru; dismiss/reset tidak menghentikan utterance yang sudah berbicara (`2562`, `2613–2624`).

Alarm operational limits/bugs yang terlihat pada source:

| Temuan | Bukti | Dampak/klasifikasi |
| --- | --- | --- |
| Foreground page timer, tidak OS scheduler | `2655–2669`; tidak Notification API/background alarm di app | Inference: tab/app suspended atau terminated dapat miss entire due minute; screen Wake Lock bukan background execution guarantee. |
| Date tidak ada pada jadwal maupun dedupe | `2630`, `2639` | Fakta: schedule reused lintas hari. Memory key tidak reset harian; session panjang suppress same rows next day, reload dapat alarm ulang pada same minute. |
| Missed minute tidak catch-up | `2638`; visibility handler `2348–2352` | Inference: resume setelah due minute tidak melaporkan alarm terlewat. |
| Combined index salah | `_idx: idx` per route `2647`, lalu board memakai `_idx` `2304–2312` | Fakta: route-local index dibaca sebagai combined index. Global pointer juga terbawa saat switching routes/modes. |
| Settings selected route dipakai route lain | `2274–2275`, `2594` | Fakta: combined countdown prep dan semua alarm duration berasal route yang dipilih, bukan route due row. |
| Prep sound mengabaikan alarmEnabled | `2281–2286` versus due check `2635` | Fakta: alarm dimatikan tetap bisa prep beep/vibrate saat board terbuka. |
| Auto-dismiss tampak seperti actual dispatch | same `dismissAlarm` for auto timer/button | Fakta: timeout dan operator acknowledgement identik secara UI pointer, tanpa actual event. |
| Reset seluruh routes | `resetAlarmTracking:2406–2413`; dipanggil generate/recalc | Fakta: mengganti satu route menghapus fired memory seluruh routes, memungkinkan same-minute refire unrelated route. |
| Zero prep stepper | `1032`, `1040` memakai `parseInt(value) || 10` | Fakta: plus dari0 jadi11, minus dari0 jadi9, walau0 valid. |
| Same unit/same minute overlay collapse | `2601`; rows/no dipakai fired key `2639` | Fakta: duplicate same-number departures di route pada same minute jadi satu overlay item. |

**Rekomendasi:** native alarm adapter wajib menjelaskan guarantee per platform. Simpan scheduled/observed/acknowledged alarm delivery sebagai identity berbasis serviceDay+revision+departureId+alarmType. Bedakan `AcknowledgedAlert` dari `RecordedDispatch`; auto-stop tidak boleh menjadi bukti departure. Implementasikan missed alarm policy dan app lifecycle reconciliation. Pilih satu perangkat audio leader pada terminal apabila semua devices realtime akan menerima event, agar tidak semua berbicara bersamaan.

### 3.8 Export dan share

- Clipboard WhatsApp-format text (`app.js:2017–2067`) mengambil `lastSchedule` accepted projection, menambah tanggal **today**, route label current, rows full. Ini clipboard; tidak mengirim WhatsApp, tidak menggunakan OS share sheet.
- `openExportMenu()` (`2682–2718`) require current route mempunyai snapshot sebelum menawarkan export all. All route export dapat tertutup walaupun route lain mempunyai jadwal.
- Single form (`2720–2772`) memilih shift1/2/3, ritase mulai, format. Offset ritase adalah relabel `data.ritaseFrom + (row.ritase -1)`; bukan filter rentang/jadwal atau actual shift (`2774–2795`). `ritaseFrom` HTML min1 tidak diperiksa secara programmatic pada `preConfirm`; nilai negatif bisa diterima (`2760–2765`).
- TXT dan XLSX mengekspor full rows/interval/peak dengan metadata (`2797–2848`). Tidak ada JSON backup/import/round-trip data.
- All XLSX menambahkan Master Gabungan lalu tiap route (`2851–2919`). Master interval tetap interval **route** dari row, bukan terminal combined headway. Route sheet header `r.ritase` dan `r.peakEnabled` dapat berasal dirty draft sedangkan rows committed (`2894–2898`).
- Sheet name menghapus sebagian karakter dan truncate30, tetapi tidak menghapus `:` atau memastikan unique names (`2844`, `2913`). Rename dan duplicate dapat menghasilkan nama sama; duplicate sheets/error tidak ditangani.
- PDF (`2921–2955`) custom row-loop fixed columns, add page pada y>280; header tabel tidak diulang di pages berikutnya, long unit/route text tidak wrapped, Unicode brand font behavior perlu device/render validation.
- PNG (`2957–2965`) `html2canvas(boardBody)` dengan background hardcoded dark. `rows`, `sched`, dan export metadata tidak dipakai: screenshot dapat mengandung labels asli, highlight/history opacity, tanpa shift/relabel/header, berbeda dari export form. Export seluruh long DOM juga berpotensi high-memory.
- File naming memakai route display text dan current date; sanitization path filename tidak ada (`2815`, `2846`, `2953`, `2961`). Browser menormalisasi download name, tetapi v2 harus validate native filesystem name.

**Rekomendasi:** canonical `ScheduleExportSnapshot` mengambil serviceDay, accepted revision, included routes, label preferences, rows, dan provenance; semua format memakai snapshot identik. TXT/PDF/XLSX/share core dipertahankan. PNG defer sampai user need/output schema jelas; jika tetap disediakan, render export layout tersendiri, bukan screenshot live widget/DOM. Sheet names/path names dinormalisasi dengan deterministic dedupe.

## 4. Feature inventory dan disposition

`Wajib` menunjukkan capability/business intent yang harus dipertahankan; tidak mewajibkan mekanisme browser lama. Kritis: **C0** correctness/dispatch, **C1** operasional/data, **C2** convenience. Disposition per capability utama; REDESIGN dapat sekaligus wajib.

| Fitur | Lokasi kode | Kritis | Wajib | Redesign | Kandidat dihapus | Disposition dan alasan |
| --- | --- | --- | --- | --- | --- | --- |
| Brand HEDGE/Headway Generator/By Mikrotrans Utara | `index.html:1784–1787` | C1 | Ya | Adapt tokens | Tidak | MUST KEEP: operator identity jelas. |
| Route-specific params/roster/order | `app.js:11–86,1672–1726` | C0 | Ya | Typed config | Tidak | MUST KEEP: business independence route. |
| Route create/name edit | `599–688,642–658` | C1 | Ya | Validate duplicate/name | Tidak | REDESIGN: names bukan identities; beberapa fallback tidak duplicate-check. |
| Route duplicate | `690–718,798–824` | C2 | Tidak untuk rilis awal | Satu consistent clone command | Tidak | DEFER: dua jalur beda preferences/order. |
| Include/exclude route dari terminal | `378–473,783–796` | C0 | Ya | Explicit service-plan membership | Tidak | REDESIGN: current visibility juga menghentikan alarm. |
| Permanent route deletion | `826–839` | C1 | Ya, archive first | Audit/soft archive | Tidak | REDESIGN: operational history tidak boleh hilang. |
| Roster add/active/off/delete | `1205–1275,1401–1417` | C0 | Ya | Stable identity/eligibility | Tidak | REDESIGN: number/ID dual lookup bisa ambigu. |
| Roster search/filters | `1065–1082,1374–1376` | C1 | Ya | Accessible adaptive list | Tidak | MUST KEEP: cepat mencari unit di lapangan. |
| Bulk roster actions/select-all | `1278–1372` | C1 | Ya | Preview scope/undo | Tidak | REDESIGN: banyak perubahan operasional perlu scope clear. |
| Ordered round-robin roster | `1438–1527,1673–1676` | C0 | Ya | Validate permutation | Tidak | MUST KEEP: arrival/departure queue operational input. |
| Adjacent up/down reorder | `1470–1501` | C1 | Ya | Touch/keyboard focus | Tidak | MUST KEEP: fallback cepat tanpa gesture precision. |
| Multi-drag order selection | `1425–1426,1505–1525` | C2 | Tidak | Jika evidence demand | Ya untuk initial UI | DEFER: plugin/gesture complexity; preserve single reorder. |
| Operational hours/ritase controls | `890–928`, HTML `1880–1900` | C0 | Ya | Validated service day/time | Tidak | REDESIGN: no midnight/date; current UI bounds saja. |
| Nonpeak integer headway | `1539–1558` | C0 | Ya | Pure engine | Tidak | MUST KEEP subject characterization/invariants. |
| Short/long headway block direction | `957–976,1547–1549,1624–1626` | C0 | Ya | Name policy explicit | Tidak | MUST KEEP: bukan cosmetic switch, output beda. |
| Two peak periods/headway | `945–954,1560–1629` | C0 | Ya | Feasibility/boundary specification | Tidak | REDESIGN: semantic pitfalls detailed scheduler audit. |
| Single-route generation/accept | `1728–1748,1849–1875` | C0 | Ya | Candidate/accept revision | Tidak | REDESIGN: immutable revision/history. |
| All participating-route generation | `1877–1909` | C1 | Ya | Batch result/atomic policy | Tidak | REDESIGN: current partial success per route. |
| Committed schedule persistence | `1734–1746` | C0 | Ya | Revision aggregate | Tidak | MUST KEEP: config edit tidak diam-diam mengganti live plan. |
| Dirty-state warning | `250–262`, HTML `1986–1989` | C0 | Ya | Always visible, semantic diff | Tidak | REDESIGN: currently nested collapsed drawer. |
| Remaining recalc/freeze history | `1914–2015` | C0 | Ya | Explicit cutoff/actual dispatch | Tidak | REDESIGN: preserve user intent, decide known ambiguities. |
| Departure list and pattern/stats | `1767–1847` | C1 | Ya | Lazy list/provenance | Tidak | MUST KEEP: monitor generated pattern. |
| Live cockpit/countdown | `2969–3055`, HTML `1811–1855` | C0 | Ya | Unified projection | Tidak | REDESIGN: clock/dismiss semantics differ from board. |
| Fullscreen route board | `2157–2232,2354–2397` | C1 | Ya | Platform display mode | Tidak | REDESIGN: workstation/read-only board. |
| Combined terminal monitor | `2082–2116,2171–2213` | C0 | Ya | Stable tie order/departure IDs | Tidak | REDESIGN: presentation merge saja, no arbitration. |
| Auto-center next departure | `2219–2232,2328` | C1 | Ya | Follow/pause-follow mode | Tidak | REDESIGN: user scroll shouldn't always be overridden. |
| Screen Wake Lock | `2337–2352` | C1 | Ya where supported | Capability adapter | Tidak | REDESIGN: status visible, release on lifecycle. |
| Due alarm grouping/chime | `2424–2449,2598–2653` | C0 | Ya | OS adapter + delivery ledger | Tidak | REDESIGN: foreground-only minute matching insufficient. |
| Indonesian TTS number pronunciation | `2452–2573` | C1 | Ya if terminal uses audio | Voice/locale contract | Tidak | REDESIGN: preserve number naming goldens, allow mute/device leader. |
| Prep warning/red/bi-beep/vibrate | `2234–2292` | C0 | Ya | Per-row route settings | Tidak | REDESIGN: ignores disabled alarm, wrong active route settings. |
| Alarm OK/dismiss and auto-stop | `2592–2595,2613–2627` | C0 | Ya | Separate alert ack/actual dispatch | Hapus conflation | REDESIGN: timeout bukan departure proof. |
| Clipboard WhatsApp text | `2017–2067` | C1 | Ya | Clipboard+native share adapter | Tidak | MUST KEEP: operational sharing, no auto messaging. |
| Shift selection/export ritase labels | `2720–2795` | C1 | Ya | Export prefs, validation | Tidak | REDESIGN: Shift is metadata only in actual source. |
| Single TXT | `2797–2817` | C1 | Ya | Canonical export snapshot | Tidak | MUST KEEP: portable/offline output. |
| Single PDF | `2921–2955` | C1 | Ya | Pagination/fonts | Tidak | REDESIGN: human document reliability. |
| XLSX route + multi-sheet master | `2819–2919` | C1 | Ya | Sanitized unique sheets/provenance | Tidak | REDESIGN: existing meaningful dispatch output. |
| PNG live-board screenshot | `2957–2965` | C2 | Tidak initial | Separate export rendering | Ya current method | DEFER: mismatched metadata/memory, validate demand. |
| Bottom tabs/thumb action dock | `327–365,3057–3079`; HTML `2043–2061,2152–2181` | C1 | Ya concept | Platform-adaptive navigation | Tidak | REDESIGN: action label currently misleading. |
| Press-and-hold tooltips | `264–320` | C2 | Tidak | Standard semantics/tooltips | Ya bespoke system | REMOVE old implementation: touch targets/info remain accessible. |
| Hidden top tabs/action duplicates | HTML `1800–1806,1999–2005` | C2 | Tidak | Clean presentation commands | Ya | REMOVE: retained JS bindings only; no native value. |
| Automatic initial generation | `3101–3107` | C1 | Tidak | First-run setup/accept | Ya automatic commit | REDESIGN: avoid unnoticed operational plan acceptance. |
| Browser whole-root localStorage | `117–200` | C0 | Ya persistence intent | Transactional local DB | Ya implementation | REDESIGN: writes/errors/migrations need reliability. |
| v4 import fallback | `135–185` | C1 | Ya import path | Versioned parser/report | Tidak | REDESIGN: preserve customer data, no silent defaults. |
| Stored-but-unused papanMode | `113,130,2126` | C2 | Tidak | Device UI preference if needed | Ya field | REMOVE unused legacy field from domain. |
| Dark brand palette | HTML `32–67` | C1 | Ya | Dark/light/high contrast | Tidak | REDESIGN: **existing does not implement light theme**. |
| Reduced motion support | HTML `1772–1774` | C1 | Ya | Flutter accessibility setting | Tidak | MUST KEEP: operational readability/accessibility. |

**Belum ada fitur:** login/roles, backend schedule API, realtime device synchronization, dispatch ledger, actual departure recording, import/backup JSON, conflict handling, alarm permission/health screen, service-day rollover, remote board session. Ini requirements/candidates v2, bukan capability current source.

## 5. Layer mapping dan isolation boundary

| Target layer | Function/source actual | Refactor boundary (rekomendasi) |
| --- | --- | --- |
| Domain | `toMinutes`, `toHHMM`, `buildTimeline`, `isPeakAtOffset`, scheduler row assignment `buildScheduleForRoute` | Typed TimeOfDay/ServiceDay, validated config, pure generation; ID/clock injected. Current builders tidak perlu DOM, tetapi `buildScheduleForRoute` still accepts mutable UI-shaped route. |
| Domain | Remaining targets + round-robin queue di `recalcRemaining:1927–1970` | Pure `RemainingPlanCalculator` dengan cutoff/ledger/approved policy; tanpa `new Date`, save/toast/render. |
| Domain | Roster/order invariant snippets di constructor/render/mutation | `RouteUnitAssignment` / `DepartureOrder` validation commands; invariant tak boleh tinggal di render. |
| Application | `generateScheduleForRoute`, generate button/all button, `recalcRemaining`, `addUnit`, delete/bulk actions, route commands | Use cases `GenerateCandidate`, `AcceptRevision`, `RecalculateCandidate`, `SetEligibleUnit`, `SetOrder`, `IncludeRoute`, `ArchiveRoute`. Coordinate transaction/result. |
| Application | `buildCombinedSchedule`, next-row selection dalam HUD/board | Projection/query service keyed departure ID; same serviceDay and accepted revisions. |
| Application | `checkAlarmTriggers`, `resetAlarmTracking`, alarm delivery/ack state | Alarm coordinator/lifecycle reconciliation; delivery policy domain input, actual OS scheduling infrastructure. |
| Application | Export labeledRows/meta generation `doExportSingle` | `CreateExportSnapshot` typed request; no Swal/Date/DOM. |
| Presentation | `render*`, `hydrateInputs`, `switchTab`, `update*Bar`, tooltips, SweetAlert forms/toast/error, drawer/dock | UI widgets/state + actions; never persist or fix roster as side-effect of build. |
| Presentation | `updatePapanCountdown`, `updateCockpitHud`, `centerPapanHighlight` | Read one projection; periodic visible countdown; UI controls follow-scroll. |
| Infrastructure | `loadState`, `saveState`, legacy parser, `downloadBlob`, `fallbackCopy`, `navigator.clipboard` | Repository/legacy gateway/file/share ports with structured errors. |
| Infrastructure | `ensureAudioCtx`, `beep`, speech adapter, vibrate, fullscreen, wake lock, timers | Per-platform adapters, capability status, lifecycle/permission integration. |
| Infrastructure | `exportSingleXLSX/PDF/PNG`, TXT bytes | Pure format-specific document renderer + filesystem adapter; independent of live UI. |

Current strong coupling examples: `renderOrderList()` mutates business order and saves; `getActiveRoute()` changes route participation; `recalcRemaining()` mixes clock/domain/commit/storage/UI/alarm reset; `generateScheduleForRoute()` persists accepted result immediately; `exportSinglePNG()` consumes DOM, not export snapshot. These are migration seams, not reasons to drop business features.

## 6. Legacy persistence/migration/security assessment

### 6.1 Load/save behavior

`loadState()` accepts v5 only if parsed routes is nonempty array. It normalizes routes with constructor, fixes missing active route ID, defaults root papanMode; other root fields survive. v5 route object values are merged by `Object.assign` without schema allowlist (`app.js:123–126`, `57–83`). No bounds checks for nested rows/config or audit version.

`saveState()` serializes **whole root** synchronously and catches all errors with empty body (`194–198`). There is no write acknowledgement, transaction, quota warning, checksum, backup, journaling, or revision conflict check. Memory can continue operationally while durable writes fail.

### 6.2 Existing v4 migration

`app.js:135–185`:

- First route name `activeRouteName || lastKodeRute || 'JAK.115'`, hardcoded `r_migrated_1`, amber.
- Carries original config, alarms, roster/order, committed schedule, dirty, lastShift; uses `||` defaults for many values, preserves false alarmEnabled explicitly, preserves zero alarmPrepSeconds via undefined check.
- Legacy route presets with names different case-insensitively from first route become additional routes. Preset `units` converted to `{number, active}`; IDs regenerated, and all these routes receive hardcoded 05:30–21:30/6 ritase rather than per-preset scheduling configs.
- Returns root active first route, papanMode active. v4 key is not removed. Persistence to v5 happens incidentally through later UI startup saves, not a tracked migration commit.

### 6.3 Identity normalization pitfalls

- Unit ID is preserved only if nonempty/non-`undefined`/non-`null` and not already seen **within route**; otherwise generated random ID (`11–38`). Same migration run is nondeterministic for repaired IDs.
- Unit number falls back `number`, then `num`, then index+1, and is stringified. Duplicate numbers are not repaired/flagged.
- Departure order entry lookup accepts ID **or number**, uses first match (`44–49`). Duplicates in order remain; active units absent from order appended. Constructor can initially retain inactive references, `renderOrderList` later drops them.
- If same old ID repeats across units, order ref maps first unit and newly repaired second unit gets appended; meaning cannot be recovered confidently without diagnostic.
- Route ID uniqueness and names are not checked. `getActiveRoute` picks first ID match. Modern create checks case-insensitive name uniqueness in some paths; rename/clone paths do not.
- Committed rows have only unit number, so no reliable automatic mapping to original unit when numbers duplicate/reused. Treat rows as immutable imported snapshots and annotate uncertain identity.

### 6.4 Invalid data and recovery

Malformed JSON or constructor errors fall back **entire root** to defaults (`188–191`). A structurally bad but parseable `committedSchedule` can survive constructor and crash later UI; for example route list reads `r.committedSchedule.rows.length` if object truthy (`745–746`). Empty/malformed time strings can propagate `NaN` via `toMinutes` or throw if nonstring (`1530`); route constructor does not reject them. Invalid array types in nested source can cause constructor `.map` errors.

**Rekomendasi:** import separates parse → version adapter → validation → normalized staging → preview/report → atomic commit; preserve raw envelope before any normalization. Never replace whole user data silently. Salvage valid routes, quarantine invalid routes/rows with reasons. Roll back transaction on failed durability. Migration identifiers derived deterministically from import fingerprint + legacy IDs + collision ordinal, with mapping report.

### 6.5 Browser-to-native handoff

**Fakta:** only state keys above exist for business persistence; no import/backup endpoint or JSON export. Operational TXT/XLSX/PDF/PNG are lossy and not schema backups.

**Rekomendasi:** later authorized compatibility release of PWA adds user-initiated **full JSON export** (not part of this analysis change). Envelope:

```text
migrationFormatVersion
sourceApp / sourceOrigin / sourceVersion-or-commit
exportedAtUtc / sourceDeviceTimezone
rawKeys: {jadwalApp_multi_v5?, jadwalApp_v4?}
sha256 / immutablePayload
```

Native app cannot assume it can read installed PWA/browser localStorage. Origin, browser profile, private mode, and desktop/mobile storage differ. Import file or deliberate user-mediated signed migration transfer is necessary. Preserve old raw export for recovery; validate size, arrays, IDs, name lengths, time values, numeric bounds, row order/count/gap, optional unknown fields; report all repairs before activation.

Import committed schedules as **legacy accepted snapshots** with algorithm version `legacy-v5-unknown`, source provenance, and unknown serviceDay. Do not automatically mark them today's active dispatch plan. Ask user to choose operation date when activating historical/undated plan, or infer only into preview with explicit confirmation. Do not regenerate during import; changed scheduler rules would erase evidence. Existing “history” remains planned elapsed inference, never manufactured actual dispatch events.

### 6.6 Security facts

- No app authentication/roles/token handling in `app.js`; local browser/profile possession controls access.
- `escapeHtml()` protects many visible unit/name strings (`238–240`, renderers), but route IDs/colors/time fields are concatenated into HTML attributes/style/text without consistent validation (`421`, `494–502`, `535`, `753–775`, `1459`, `1838–1839`, `2582–2586`). **Inference:** malicious/tampered imported storage is unsafe input; don't assume escaped label alone makes all payload safe.
- CDN scripts execute in origin with access to business localStorage; no script integrity attributes in HTML (`25–29`). No secrets should be kept in that origin storage if future authentication added.
- Export today/date/live config mismatch and lack of actor/revision trail are integrity risks beyond confidentiality.

**Rekomendasi:** v2 minimum scoped authenticated API, authorization per terminal/route/action, durable audit for accepted revision/actual dispatch, server validation, TLS, OS secure token storage. Local operational rows may remain ordinary SQLite with OS app sandbox unless organizational/device threat model requires encryption; token secure store separate. Local accepted writes need attribution and integrity; full enterprise device management is later, not a prerequisite for domain extraction.

## 7. UX/theme/adaptive findings

**Fakta:** brand tokens match orange/cyan/obsidian direction (`index.html:32–67`), but there is only dark `:root`; no light token set, theme preference switch, or `prefers-color-scheme`. Therefore dual-theme support is an AGENTS requirement to meet in target, not verified current capability.

Mobile direction already exists: next departure cockpit, drawer, fixed bottom nav, thumb dock, horizontal route strip, safe-area variables. Yet current implementation has significant ergonomics debt:

- Main max width520px on every device (`660–665`); no viewport breakpoint except reduced-motion query (`1772`). Desktop is mobile column enlarged around empty space, not workstation layout.
- 16px tooltip/route close; 28px order arrows; 32px icon/delete/monitor/bulk; 38px stepper/add controls; 44x26 div switch (`119–120`, `143–144`, `165–166`, `768–769`, `1378–1379`, `1325–1326`). Touch target requirement44–48 is not consistently met.
- Switches are clickable `div`, not keyboard-focusable button/switch semantics (`index.html:1927`, `1963`; generated `app.js:1156`). Link-like `a` without href (`1917`, `2124`) has similar keyboard issue.
- Zoom disabled in viewport (`index.html:5`), dense 8.5–11px secondary text across UI, color/opacity dominate state; text-scale/high-contrast accessibility needs explicit redesign.
- Dirty banner inside collapsed drawer (`index.html:1874`, `1986`); summary says only unit/order changed though time/ritase/peak/group changes also dirty.
- Dock label “Recalc” calls full regenerate if banner class not show (`app.js:3073–3076`); confirmation may delete today's snapshot despite misleading action label.
- Combined-mode CSS first column width74 exists (`index.html:1648–1651`) but controller never applies `combined-mode` class; combined rows remain first column38 (`app.js:2126–2397`). Long route names/unit strings need test.
- Board auto-centers every tick, not just index change (`2326–2328`); deliberate user scroll to history can be overridden.
- Alarm button says already departed; auto-stop uses same state transition. This semantic ambiguity is operational, not cosmetic.

**Rekomendasi:** mobile home prioritizes accepted-plan route, due/next departures, clearly visible pending draft, offline/sync/clock/alarm health, and deliberate “Catat berangkat”. Targets min48dp, text-scale tests, buttons with semantics. Configuration/editing can be separate shallow screens; no critical warning buried. Desktop uses route rail, combined terminal board, detail/editor column, keyboard commands and follow-scroll toggle. Same domain queries/policies; separate layouts by available width/input mode. Light/dark palettes and high contrast need independent QA.

## 8. Performance/workload facts dan bottleneck

Default generated JAK.115 is **39×8=312 departures** and JAK.88 **12×6=72**, combined384. Unit addition unbounded; UI ritase max30 yields1.170 rows for same39-unit roster. Arbitrary imported R/roster has no runtime cap.

Current complexity:

- Scheduler/order resolution repeatedly uses linear `masterUnits.find` for each order ref (`1673–1675`, `1440–1444`): O(U²) roster lookup.
- Full route/unit/order/schedule rendering creates nodes/listeners per row on each rerender (`1140+`, `1453+`, `1796+`). No virtualization.
- Each second scans all eligible route rows for alarm; HUD scans selected plan and updates class across all table rows. Combined board rebuilds cloned list/sort on every highlight tick, then all DOM row classes + layout/scroll measurement (`2082–2110`, `2298`, `2319–2328`, `2633–2649`, `3048–3053`).
- Whole-state JSON stringify/localStorage writes happen on UI actions and order render (`194–198`, `1445`); generated schedules duplicate route metadata per row.
- PNG rasterizes entire long DOM; memory scales with height×width×pixel ratio. PDF/XLSX run on main thread.

**Rekomendasi:** performance budgets in blueprint are target SLOs to measure on agreed minimum Android device, not claims from benchmark. Use baseline384 and larger agreed terminal workload (e.g.10 routes×40 units×10 ritase=4.000 rows) as explicit sizing scenarios, not presumed customer maximum. Index entities by ID, cache immutable projections per revision, locate next departure by ordered instant, alarms pre-scheduled/indexed, lazy lists, local transaction batches, visible countdown scoped rebuilds. Export can use isolate/background worker only when measured blocking justifies it.

## 9. Required characterization scenarios dari alur ini

Scheduler arithmetic golden cases live in dedicated appendix/oracle. Tambahkan application/UI/data boundary fixtures:

| Scenario | Expected legacy observation atau target constraint |
| --- | --- |
| Config edit sesudah generation | Snapshot rows unchanged, dirty true, alarms/export still accepted rows; current metadata may show draft. |
| Edit then revert same value | Legacy dirty tetap true; target semantic dirty dapat false with specified policy. |
| Dirty banner while drawer collapsed | Current warning hidden; target critical pending status visible. |
| Recalc exact departure minute | History includes current minute; future begins same minute; capture known duplicate-time behavior. |
| Recalc after changing R/end/start | Legacy cs.R/end preserved, draft latest peak/order applied, dirty cleared. |
| Recalc remove/add/reactivate unit | History retained; remaining counts by number; newly active unit full committed R. |
| Recalc no remaining / one remaining | Capture row count, boundary, labels/segments, interval stale behavior. |
| Duplicate order IDs / unit IDs / unit numbers | Constructor repair/order mapping report; never silently claim unambiguous identity. |
| Invalid v5 + valid v4 / malformed committed object | Legacy default/crash pathways; target backup/quarantine/explicit recoverable error. |
| Save quota/security exception | Legacy swallowed; target write failure visible, no false durable success. |
| Two tabs same root | Legacy last writer wins with no storage listener; target repository version conflict. |
| Hidden route selected/archived | Legacy getActiveRoute fallback; target navigation independent of inclusion. |
| Alarm at due minute seconds0/35/59 | All due matches HH:mm once per memory key, not exact second. |
| Resume after entire due minute | No legacy catch-up; target missed-delivery policy explicit. |
| Same session day rollover / reload at due minute | No daily fired key reset; reload keys clear. |
| Generate/recalc one route at due minute | All route fired keys reset; possible refire elsewhere. |
| Combined alarm for route B local index vs combined index | Legacy wrong highlight; target stable departure identity. |
| Switch route/mode after alarm ack | Legacy global pointer carries; target scoped query identity. |
| Alarm disabled, board prep threshold entered | Legacy preparation still beeps; target respect policy. |
| Different prep/duration per simultaneous routes | Legacy selected-route settings govern; target conflict/aggregation policy explicit. |
| Prep0 plus/minus | Legacy11/9 jump, target integer step1 and clamp0. |
| Auto-stop vs manual OK | Legacy same pointer transition, no actual ledger; target separate acknowledgement/dispatch. |
| Speech after dismissal | Legacy cancellation absent; target audio adapter interruption rules. |
| Clipboard fallback failure | `execCommand` may return false yet success callback called (`2065`); target truthful structured result. |
| Offset export shift/ritase vs PNG | PNG ignores labels/meta; target all renderers equivalent snapshot. |
| Duplicate/sanitized sheet collisions and long names | Target valid unique spreadsheet names and safe filename. |
| Dark/light, text scale200%, screen reader, touch48dp | Current light missing; target platform accessibility gates. |

## 10. Business decisions yang tidak boleh disimpulkan diam-diam

1. Apakah target ritase means dispatch count per vehicle, complete physical round trip, atau istilah wave? Source hanya menghitung jumlah planned rows per unit; tidak tahu trip duration/return feasibility.
2. Pada recalc, apakah perubahan target ritase dan end-of-service berlaku langsung untuk sisa hari, atau accepted target tetap? UI memberi kesan perubahan berlaku, implementation memakai committed values.
3. Apakah “history” cukup elapsed planned rows, atau operasional memerlukan actual dispatch record? V2 rekomendasi actual ledger, tetapi legacy dapat dipertahankan sebagai explicit inference compatibility mode sampai workflow dikonfirmasi.
4. Adakah same physical unit lintas route/terminal dan constraints bay/driver/travel? Code cuma roster route-local; jangan mengasumsikan global scheduling/resource optimization existing.
5. Apakah alarm harus berbunyi saat app background/killed, dan apakah setiap device atau designated terminal speaker? Platform guarantee dan product expectation harus ditulis.
6. Apakah overnight service dan multi-timezone benar dibutuhkan? Existing menolak end<=start dan memakai date device; jangan otomatis memilih midnight interpretation.
7. Siapa boleh accept operational plan/recalc/dispatch antar dispatcher offline? Sync proposal perlu single-writer/authority policy saat shared route, bukan silent last-write-wins.

Keputusan lain yang dapat disimpulkan: accepted plan harus terpisah draft; stable identities/version/provenance diperlukan; local write harus durable/visible; browser-local migration perlu deliberate handoff; per-platform layout/accessibility/alarm behavior perlu test, tanpa production changes pada tahap ini.
