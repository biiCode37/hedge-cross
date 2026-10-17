# Kustomisasi TTS Template Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Memberikan kendali bagi dispatcher untuk mengonfigurasi template kalimat suara Text-To-Speech (TTS) alarm keberangkatan, mengotomasi penghilangan penyebutan rute pada pos 1 rute (auto-context), mengekstrak 4 digit terakhir nomor bodi unit, serta menyediakan UI preset cepat dan tombol chip penyisip variabel di menu Pengaturan.

**Architecture:** Model `AlarmPreferences` dan `AlarmEvent` di Dart diperluas dengan properti `prepTemplate`, `dueTemplate`, dan flag `isMultiRoute`. Nilai ini disinkronkan ke Android native melalui Platform Channel. Mesin `AlarmSpeechText.kt` di Kotlin Android mengekstrak token `{rute}`, `{unit}`, `{detik}`, `{jam}`, `{ritase}`, melakukan normalisasi pelafalan dan pembersihan spasi/tanda baca yatim. Antarmuka `configuration.dart` menyediakan dropdown preset gaya bicara, kolom kustom, quick-insert chips, dan tombol uji suara langsung.

**Tech Stack:** Flutter / Dart (Riverpod, Flutter Test), Android Native Kotlin (TextToSpeech, AudioFocus, JUnit4, SharedPreferences).

## Global Constraints
- Branch Git wajib selalu `devmode`. Dilarang menyentuh atau commit ke branch `main`.
- Dilarang menjalankan build APK (`flutter build apk` / gradle assemble) tanpa perintah eksplisit user.
- Package manager wajib menggunakan `pnpm`.
- Mendukung kontras penuh untuk Dark Mode (`#070B12`, `#FF9800`, `#00E5FF`) dan Light Mode (`#F8FAFC`).
- Ukuran touch target tombol chip minimal 44–48px untuk akses satu jempol di lapangan.

---

### Task 1: Domain Models & Alarm Plan Data Layer (Dart)

**Files:**
- Modify: `lib/domain/models.dart:245-273`
- Modify: `lib/domain/alarm_plan.dart:1-95`
- Test: `test/alarm_test.dart`

**Interfaces:**
- Consumes: `AlarmPreferences`, `HedgeRoute`, `Workspace`
- Produces: `AlarmPreferences.prepTemplate`, `AlarmPreferences.dueTemplate`, `AlarmEvent.prepTemplate`, `AlarmEvent.dueTemplate`, `AlarmEvent.isMultiRoute`

- [ ] **Step 1: Tulis unit test yang memvalidasi template TTS dan flag isMultiRoute**

Buka `test/alarm_test.dart` dan tambahkan test case baru:

```dart
test('AlarmPreferences serialization and multi-route context flag in alarm plan', () {
  const prefs = AlarmPreferences(
    prepTemplate: '{rute} unit {unit}, {detik} detik lagi.',
    dueTemplate: '{rute} unit {unit}, saatnya berangkat.',
  );
  final json = prefs.toJson();
  expect(json['prepTemplate'], '{rute} unit {unit}, {detik} detik lagi.');
  expect(json['dueTemplate'], '{rute} unit {unit}, saatnya berangkat.');

  final restored = AlarmPreferences.fromJson(json);
  expect(restored.prepTemplate, prefs.prepTemplate);
  expect(restored.dueTemplate, prefs.dueTemplate);

  // Single route workspace -> isMultiRoute must be false
  final singleRouteWorkspace = sampleWorkspace(DateTime.utc(2026, 10, 5));
  final singlePlan = buildAlarmPlan(
    singleRouteWorkspace,
    singleRouteWorkspace.activeRoute!.schedule!.departures.first.minute > 0
        ? plannedInstant(singleRouteWorkspace.date, 0)
        : DateTime.utc(2026, 10, 5, 4, 50),
  );
  expect(singlePlan.first.toJson()['isMultiRoute'], false);

  // Multi route workspace -> isMultiRoute must be true
  final secondRoute = singleRouteWorkspace.routes.first.copyWith(
    id: 'route-2',
    name: 'JAK.76',
  );
  final multiRouteWorkspace = singleRouteWorkspace.copyWith(
    routes: [singleRouteWorkspace.routes.first, secondRoute],
  );
  final multiPlan = buildAlarmPlan(
    multiRouteWorkspace,
    DateTime.utc(2026, 10, 5, 4, 50),
  );
  expect(multiPlan.first.toJson()['isMultiRoute'], true);
  expect(multiPlan.first.toJson()['prepTemplate'], isNotEmpty);
  expect(multiPlan.first.toJson()['dueTemplate'], isNotEmpty);
});
```

- [ ] **Step 2: Jalankan test untuk memverifikasi kegagalan (failing test)**

Command:
```bash
flutter test test/alarm_test.dart --no-pub
```
Expected: FAIL karena properti `prepTemplate`, `dueTemplate`, dan `isMultiRoute` belum ada pada `AlarmPreferences` dan `AlarmEvent`.

- [ ] **Step 3: Implementasikan properti pada AlarmPreferences dan AlarmEvent**

Di `lib/domain/models.dart`:
```dart
class AlarmPreferences {
  const AlarmPreferences({
    this.banner = true,
    this.fullScreen = true,
    this.preparation = true,
    this.departure = true,
    this.sound = true,
    this.vibration = true,
    this.prepTemplate = '{rute} unit {unit}, {detik} detik lagi.',
    this.dueTemplate = '{rute} unit {unit}, saatnya berangkat.',
  });
  final bool banner, fullScreen, preparation, departure, sound, vibration;
  final String prepTemplate, dueTemplate;

  Map<String, dynamic> toJson() => {
    'banner': banner,
    'fullScreen': fullScreen,
    'preparation': preparation,
    'departure': departure,
    'sound': sound,
    'vibration': vibration,
    'prepTemplate': prepTemplate,
    'dueTemplate': dueTemplate,
  };

  factory AlarmPreferences.fromJson(Map<String, dynamic> json) =>
      AlarmPreferences(
        banner: json['banner'] as bool? ?? true,
        fullScreen: json['fullScreen'] as bool? ?? true,
        preparation: json['preparation'] as bool? ?? true,
        departure: json['departure'] as bool? ?? true,
        sound: json['sound'] as bool? ?? true,
        vibration: json['vibration'] as bool? ?? true,
        prepTemplate: json['prepTemplate'] as String? ?? '{rute} unit {unit}, {detik} detik lagi.',
        dueTemplate: json['dueTemplate'] as String? ?? '{rute} unit {unit}, saatnya berangkat.',
      );

  AlarmPreferences copyWith({
    bool? banner,
    bool? fullScreen,
    bool? preparation,
    bool? departure,
    bool? sound,
    bool? vibration,
    String? prepTemplate,
    String? dueTemplate,
  }) => AlarmPreferences(
    banner: banner ?? this.banner,
    fullScreen: fullScreen ?? this.fullScreen,
    preparation: preparation ?? this.preparation,
    departure: departure ?? this.departure,
    sound: sound ?? this.sound,
    vibration: vibration ?? this.vibration,
    prepTemplate: prepTemplate ?? this.prepTemplate,
    dueTemplate: dueTemplate ?? this.dueTemplate,
  );
}
```

Di `lib/domain/alarm_plan.dart`:
```dart
class AlarmEvent {
  const AlarmEvent({
    required this.key,
    required this.routeId,
    required this.revisionId,
    required this.departureId,
    required this.routeName,
    required this.unitNumber,
    required this.stage,
    required this.at,
    required this.departureAt,
    required this.round,
    required this.durationSeconds,
    required this.preferences,
    required this.theme,
    required this.isMultiRoute,
  });
  final String key,
      routeId,
      revisionId,
      departureId,
      routeName,
      unitNumber,
      stage,
      theme;
  final DateTime at, departureAt;
  final int round, durationSeconds;
  final AlarmPreferences preferences;
  final bool isMultiRoute;

  Map<String, dynamic> toJson() => {
    'key': key,
    'routeId': routeId,
    'revisionId': revisionId,
    'departureId': departureId,
    'routeName': routeName,
    'unitNumber': unitNumber,
    'stage': stage,
    'at': at.millisecondsSinceEpoch,
    'departureAt': departureAt.millisecondsSinceEpoch,
    'round': round,
    'durationSeconds': durationSeconds,
    'theme': theme,
    'isMultiRoute': isMultiRoute,
    'prepTemplate': preferences.prepTemplate,
    'dueTemplate': preferences.dueTemplate,
    ...preferences.toJson(),
  };
}
```

Dalam fungsi `buildAlarmPlan` di `lib/domain/alarm_plan.dart`:
Hitung jumlah rute aktif berpartisipasi:
```dart
final participatingRoutesCount = workspace.routes
    .where((r) => r.participates && r.alarmEnabled && r.schedule != null)
    .length;
final isMultiRoute = participatingRoutesCount > 1;
```
Teruskan `isMultiRoute: isMultiRoute` saat instansiasi `AlarmEvent`.

- [ ] **Step 4: Jalankan test dan pastikan PASS**

Command:
```bash
flutter test test/alarm_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit perubahan Task 1**

Command:
```bash
git add lib/domain/models.dart lib/domain/alarm_plan.dart test/alarm_test.dart
git commit -m "feat(domain): tambahkan prepTemplate dueTemplate dan isMultiRoute pada AlarmPreferences dan AlarmEvent"
```

---

### Task 2: Android Native Dynamic Template Parsing Engine (Kotlin)

**Files:**
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt:18-35`
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt:1-57`
- Test: `android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechTextTest.kt`

**Interfaces:**
- Consumes: `AlarmSpec(..., prepTemplate, dueTemplate, isMultiRoute)`
- Produces: `AlarmSpeechText.unitLast4(unit: String): String`, `AlarmSpeechText.routeCode(route: String): String`, `AlarmSpeechText.message(event: AlarmSpec, now: Long): String?`

- [ ] **Step 1: Tulis unit test Kotlin untuk pengujian template dinamis dan auto-context**

Buka `android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechTextTest.kt` dan tambahkan pengujian:

```kotlin
    @Test fun customTemplateParsingAndPlaceholders() {
        val eventMulti = AlarmSpec("k", "r", "rev", "d", "JAK.115 — Tanjung Priok", "MJU-01865",
            "due", 0, 10000, 2, 20, true, true, true, true, "dark",
            prepTemplate = "{rute} unit {unit}, {detik} detik lagi.",
            dueTemplate = "{rute} unit {unit}, saatnya berangkat.",
            isMultiRoute = true)
        
        // Multi-route: includes route code
        assertEquals("JAK 115 unit delapan belas enam lima, saatnya berangkat.",
            AlarmSpeechText.message(eventMulti, 10000))

        // Single-route: omits route cleanly without leading comma/spaces
        val eventSingle = eventMulti.copy(
            isMultiRoute = false,
            dueTemplate = "{rute}, unit {unit}, jalan!"
        )
        assertEquals("Unit delapan belas enam lima, jalan!",
            AlarmSpeechText.message(eventSingle, 10000))
    }

    @Test fun unitLast4DigitExtraction() {
        assertEquals("delapan belas enam lima", AlarmSpeechText.unitLast4("1865"))
        assertEquals("delapan belas enam lima", AlarmSpeechText.unitLast4("01865"))
        assertEquals("delapan belas enam lima", AlarmSpeechText.unitLast4("MJU-01865"))
        assertEquals("dua dua tiga belas", AlarmSpeechText.unitLast4("TS-002213"))
        assertEquals("tujuh enam", AlarmSpeechText.unitLast4("76"))
        assertEquals("CAD", AlarmSpeechText.unitLast4("CAD"))
    }

    @Test fun routeCodeCleaning() {
        assertEquals("JAK 115", AlarmSpeechText.routeCode("JAK.115 — Tanjung Priok - Pegangsaan"))
        assertEquals("JAK tujuh enam", AlarmSpeechText.routeCode("JAK.76 — ASMI - Semper"))
        assertEquals("JAK lima belas", AlarmSpeechText.routeCode("JAK.15"))
    }

    @Test fun prepRemainingSecondsCalculation() {
        val eventPrep = AlarmSpec("k", "r", "rev", "d", "JAK.115", "1865",
            "prep", 0, 10000, 1, 20, true, true, true, true, "dark",
            prepTemplate = "{rute} unit {unit}, {detik} detik.",
            isMultiRoute = true)
        assertEquals("JAK 115 unit delapan belas enam lima, 7 detik.",
            AlarmSpeechText.message(eventPrep, 3001))
    }

    @Test fun emptyTemplateFallback() {
        val eventBlank = AlarmSpec("k", "r", "rev", "d", "JAK.115", "1865",
            "due", 0, 10000, 1, 20, true, true, true, true, "dark",
            dueTemplate = "   ", isMultiRoute = false)
        // Must fallback to default ringkas without crashing
        assertEquals("Unit delapan belas enam lima, saatnya berangkat.",
            AlarmSpeechText.message(eventBlank, 10000))
    }
```

- [ ] **Step 2: Jalankan test untuk memverifikasi kegagalan (failing test)**

Command:
```bash
./android/gradlew.bat -p android :app:testDebugUnitTest --tests id.mikrotrans.hedge.hedge_flutter.AlarmSpeechTextTest --console=plain
```
Expected: FAIL karena `prepTemplate`, `dueTemplate`, `isMultiRoute`, `unitLast4`, dan `routeCode` belum ada.

- [ ] **Step 3: Perbarui AlarmSpec di AlarmEngine.kt dan AlarmSpeechText.kt**

Di `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt`:
Perbarui data class `AlarmSpec`:
```kotlin
data class AlarmSpec(
    val key: String,
    val routeId: String,
    val revisionId: String,
    val departureId: String,
    val routeName: String,
    val unitNumber: String,
    val stage: String,
    val at: Long,
    val departureAt: Long,
    val round: Int,
    val durationSeconds: Int,
    val banner: Boolean,
    val fullScreen: Boolean,
    val sound: Boolean,
    val vibration: Boolean,
    val theme: String,
    val prepTemplate: String = "{rute} unit {unit}, {detik} detik lagi.",
    val dueTemplate: String = "{rute} unit {unit}, saatnya berangkat.",
    val isMultiRoute: Boolean = false
)
```
Pada fungsi parsing JSON di `AlarmEngine.kt`:
```kotlin
val prepTemplate = optString("prepTemplate", "{rute} unit {unit}, {detik} detik lagi.")
val dueTemplate = optString("dueTemplate", "{rute} unit {unit}, saatnya berangkat.")
val isMultiRoute = optBoolean("isMultiRoute", false)
```

Di `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt`:
```kotlin
package id.mikrotrans.hedge.hedge_flutter

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object AlarmSpeechText {
    private val digits = listOf("nol", "satu", "dua", "tiga", "empat", "lima", "enam", "tujuh", "delapan", "sembilan")
    private fun teen(number: Int) = if (number == 11) "sebelas" else "${digits[number % 10]} belas"

    fun unit(value: String): String = Regex("[0-9]+").replace(value) { match ->
        val number = match.value
        if (number.length == 1) digits[number[0] - '0'] else {
            val words = mutableListOf<String>()
            val prefix = number.dropLast(2)
            var index = 0
            while (index < prefix.length) {
                if (prefix[index] == '1' && index + 1 < prefix.length && prefix[index + 1] in '1'..'9') {
                    words.add(teen(prefix.substring(index, index + 2).toInt())); index += 2
                } else { words.add(digits[prefix[index] - '0']); index++ }
            }
            val tail = number.takeLast(2).toInt()
            when {
                tail == 10 -> words.add("sepuluh")
                tail in 11..19 -> words.add(teen(tail))
                tail in 20..90 && tail % 10 == 0 -> "${digits[tail / 10]} puluh"
                else -> number.takeLast(2).forEach { words.add(digits[it - '0']) }
            }
            words.joinToString(" ")
        }
    }.replace(Regex("[._/-]+"), " ").replace(Regex("\\s+"), " ").trim()

    fun unitLast4(value: String): String {
        val matches = Regex("[0-9]+").findAll(value).map { it.value }.toList()
        if (matches.isEmpty()) return unit(value)
        val allDigits = matches.joinToString("")
        val last4 = if (allDigits.length > 4) allDigits.takeLast(4) else allDigits
        val spokenNumber = unit(last4)
        val nonDigitPrefix = Regex("^[^0-9]+").find(value)?.value?.trim().orEmpty()
        return if (nonDigitPrefix.isNotEmpty() && !value.startsWith("0")) "$nonDigitPrefix $spokenNumber".trim() else spokenNumber
    }

    fun route(value: String): String {
        val pattern = Regex("""(?i)\bJAK[.\s](\d{2})(?!\w)""")
        val replaced = pattern.replace(value) { match ->
            val numStr = match.groupValues[1]
            val num = numStr.toInt()
            val spoken = when {
                num == 10 -> "sepuluh"
                num in 11..19 -> teen(num)
                num in 20..90 && num % 10 == 0 -> "${digits[num / 10]} puluh"
                else -> "${digits[numStr[0] - '0']} ${digits[numStr[1] - '0']}"
            }
            "JAK $spoken"
        }
        return replaced.replace('.', ' ').replace(Regex("\\s+"), " ").trim()
    }

    fun routeCode(value: String): String {
        val clean = value.split(Regex("""\s*[—–-]\s*""")).firstOrNull()?.trim() ?: value
        return route(clean)
    }

    fun format(template: String, event: AlarmSpec, now: Long): String {
        val defaultTmpl = if (event.stage == "prep") "{rute} unit {unit}, {detik} detik lagi." else "{rute} unit {unit}, saatnya berangkat."
        val chosenTmpl = if (template.isBlank()) defaultTmpl else template

        val routeSpoken = if (event.isMultiRoute) routeCode(event.routeName) else ""
        val unitSpoken = unitLast4(event.unitNumber)
        val remainingSec = ((event.departureAt - now + 999) / 1000).coerceAtLeast(1)
        val secondsSpoken = "$remainingSec"

        val timeFormatter = SimpleDateFormat("HH:mm", Locale("id", "ID"))
        val timeFormatted = try { timeFormatter.format(Date(event.departureAt)) } catch (_: Throwable) { "" }
        val ritaseSpoken = "ritase ${if (event.round in 1..9) digits[event.round] else event.round.toString()}"

        var result = chosenTmpl
            .replace("{rute}", routeSpoken, ignoreCase = true)
            .replace("{unit}", unitSpoken, ignoreCase = true)
            .replace("{detik}", secondsSpoken, ignoreCase = true)
            .replace("{jam}", timeFormatted, ignoreCase = true)
            .replace("{ritase}", ritaseSpoken, ignoreCase = true)
            .replace(Regex("""\{[^{}]*\}"""), "")

        // Clean punctuation and whitespace
        result = result
            .replace(Regex("""\s*,\s*"""), ", ")
            .replace(Regex("""\s*\.\s*"""), ". ")
            .replace(Regex("""^[,\s.-]+"""), "")
            .replace(Regex("""\s+"""), " ")
            .trim()

        if (result.isNotEmpty()) {
            result = result[0].uppercaseChar() + result.substring(1)
        }
        return result
    }

    fun message(event: AlarmSpec, now: Long): String? {
        if (event.stage == "prep" && now >= event.departureAt) return null
        val rawTemplate = if (event.stage == "prep") event.prepTemplate else event.dueTemplate
        return format(rawTemplate, event, now)
    }

    fun next(active: List<ActiveAlarm>, spoken: Set<String>, now: Long): ActiveAlarm? = active
        .filter { it.event.sound && it.expiresAt > now && it.event.key !in spoken && message(it.event, now) != null }
        .sortedWith(compareBy<ActiveAlarm> { if (it.event.stage == "due") 0 else 1 }.thenBy { it.event.at }.thenBy { it.event.key })
        .firstOrNull()
}
```

- [ ] **Step 4: Jalankan test dan pastikan PASS**

Command:
```bash
./android/gradlew.bat -p android :app:testDebugUnitTest --tests id.mikrotrans.hedge.hedge_flutter.AlarmSpeechTextTest --console=plain
```
Expected: PASS (Semua tes pelafalan, ekstraksi 4 digit unit, sanitasi single route, dan fallback lulus).

- [ ] **Step 5: Commit perubahan Task 2**

Command:
```bash
git add android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmEngine.kt android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechText.kt android/app/src/test/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSpeechTextTest.kt
git commit -m "feat(audio): implementasikan dynamic template parser dan auto-context route pada AlarmSpeechText"
```

---

### Task 3: Platform Channel Live Audio Preview Bridge

**Files:**
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt:35-42`
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt:55-63`
- Modify: `lib/application/notification_service.dart:160-175`

**Interfaces:**
- Consumes: Flutter `NotificationService.testSpeech({String? template, String? stage, bool isMultiRoute})`
- Produces: Native Android audio playback of custom preview template.

- [ ] **Step 1: Update testSpeech di lib/application/notification_service.dart**

```dart
  Future<void> testSpeech({
    String? prepTemplate,
    String? dueTemplate,
    String? stage,
    bool isMultiRoute = false,
  }) async {
    if (!isAndroid) return;
    try {
      await channel.invokeMethod<void>('testSpeech', {
        'prepTemplate': prepTemplate,
        'dueTemplate': dueTemplate,
        'stage': stage ?? 'due',
        'isMultiRoute': isMultiRoute,
      });
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 750));
        await refreshStatus();
      }
    } catch (error) {
      status.value = 'Uji suara belum tersedia: $error';
    }
  }
```

- [ ] **Step 2: Update MainActivity.kt dan AlarmDeliveryService.kt untuk menerima parameter preview**

Di `MainActivity.kt`:
```kotlin
"testSpeech" -> {
    val args = call.arguments as? Map<*, *>
    val prep = args?.get("prepTemplate") as? String
    val due = args?.get("dueTemplate") as? String
    val stage = args?.get("stage") as? String ?: "due"
    val isMulti = args?.get("isMultiRoute") as? Boolean ?: false
    AlarmEngine.deliveryIssue(this, "")
    AlarmDeliveryService.sync(this, preview = true, prepTemplate = prep, dueTemplate = due, previewStage = stage, isMultiRoute = isMulti)
    result.success(null)
}
```

Di `AlarmDeliveryService.kt`:
Tangkap parameter `prepTemplate`, `dueTemplate`, `previewStage`, dan `isMultiRoute` saat instansiasi preview `AlarmSpec`:
```kotlin
preview = ActiveAlarm(AlarmSpec("preview:$now", "preview", "preview", "preview", "JAK.115", "1865",
    stage, now, now, 1, 20, false, false, true, false, "dark",
    prepTemplate = prepTemplate ?: "{rute} unit {unit}, {detik} detik lagi.",
    dueTemplate = dueTemplate ?: "{rute} unit {unit}, saatnya berangkat.",
    isMultiRoute = isMultiRoute), now)
```

- [ ] **Step 3: Jalankan analisa statis Flutter & Android test**

Command:
```bash
flutter analyze --no-pub
./android/gradlew.bat -p android :app:compileDebugKotlin --console=plain
```
Expected: Tidak ada issue/error kompilasi.

- [ ] **Step 4: Commit perubahan Task 3**

Command:
```bash
git add lib/application/notification_service.dart android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/MainActivity.kt android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmDeliveryService.kt
git commit -m "feat(audio): tambahkan dukungan template kustom pada channel testSpeech"
```

---

### Task 4: Antarmuka Pengaturan Template TTS & Chip Variabel (Flutter UI)

**Files:**
- Modify: `lib/ui/configuration.dart:870-908`
- Test: `test/configuration_tts_ui_test.dart` (buat baru)

**Interfaces:**
- Consumes: `route.alerts.prepTemplate`, `route.alerts.dueTemplate`, `notificationService.testSpeech`
- Produces: UI Preset selector (Ringkas, Super Singkat, Standar Formal, Kustom), TextFields with Quick Insertion Chips, Live preview text, Test speech trigger.

- [ ] **Step 1: Tulis widget test untuk komponen UI pengaturan template TTS**

Buat berkas `test/configuration_tts_ui_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/ui/configuration.dart';
import 'widget_test.dart' show MemoryRepository;

void main() {
  testWidgets('TTS Template UI renders presets, chips and updates template text', (tester) async {
    final container = ProviderContainer(
      overrides: [
        workspaceControllerProvider.overrideWith((ref) => WorkspaceController(MemoryRepository())),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ConfigurationScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify section header exists
    expect(find.text('FORMAT KALIMAT SUARA TTS'), findsOneWidget);

    // Verify Preset Dropdown/ChoiceChip
    expect(find.text('Ringkas (Rekomendasi)'), findsWidgets);

    // Verify Chip insertion buttons exist
    expect(find.text('+ {rute}'), findsWidgets);
    expect(find.text('+ {unit}'), findsWidgets);
    expect(find.text('+ {detik}'), findsWidgets);
  });
}
```

- [ ] **Step 2: Jalankan test untuk memverifikasi kegagalan**

Command:
```bash
flutter test test/configuration_tts_ui_test.dart --no-pub
```
Expected: FAIL karena UI `FORMAT KALIMAT SUARA TTS` belum ada di `configuration.dart`.

- [ ] **Step 3: Implementasikan UI Pengaturan TTS di lib/ui/configuration.dart**

Di `lib/ui/configuration.dart`, di dalam kartu alarm tepat di bawah saklar `Suara alarm (TTS Bahasa Indonesia)`:

```dart
// Buat controller teks untuk prepTemplate dan dueTemplate di state
// Sediakan pilihan Preset:
// 1. Ringkas (Default):
//    prep: '{rute} unit {unit}, {detik} detik lagi.'
//    due: '{rute} unit {unit}, saatnya berangkat.'
// 2. Super Singkat:
//    prep: '{rute} {unit}, {detik} detik.'
//    due: '{rute} {unit}, jalan!'
// 3. Standar Formal:
//    prep: 'Segera berangkat, {rute} unit {unit}, berangkat dalam {detik} detik.'
//    due: 'Rute {rute}, unit {unit}, saatnya berangkat.'

// Tambahkan kartu UI dengan token Cyberpunk:
Container(
  margin: const EdgeInsets.only(top: 10),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: isDark ? const Color(0xFF070B12) : const Color(0xFFF1F5F9),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'FORMAT KALIMAT SUARA TTS',
        style: TextStyle(
          fontFamily: HedgeTokens.cyberFont,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.1,
          color: isDark ? const Color(0xFF00E5FF) : const Color(0xFF0284C7),
        ),
      ),
      const SizedBox(height: 10),
      // Dropdown preset
      DropdownButtonFormField<String>(
        value: selectedPreset,
        decoration: InputDecoration(
          labelText: 'Gaya Bicara (Preset)',
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        items: const [
          DropdownMenuItem(value: 'ringkas', child: Text('Ringkas (Rekomendasi)')),
          DropdownMenuItem(value: 'super_singkat', child: Text('Super Singkat (Pos Pantau Cepat)')),
          DropdownMenuItem(value: 'standar', child: Text('Standar Formal')),
          DropdownMenuItem(value: 'kustom', child: Text('Kustom (Edit Sendiri)')),
        ],
        onChanged: (val) { ... },
      ),
      const SizedBox(height: 12),
      // Input Prep Template + Chips
      TextFormField(
        controller: prepController,
        decoration: InputDecoration(
          labelText: 'Sebelum Berangkat (Persiapan)',
          hintText: '{rute} unit {unit}, {detik} detik lagi.',
          isDense: true,
        ),
        onChanged: (v) => setState(() => selectedPreset = 'kustom'),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        children: [
          _insertChip('+ {rute}', () => _insertTag(prepController, '{rute}')),
          _insertChip('+ {unit}', () => _insertTag(prepController, '{unit}')),
          _insertChip('+ {detik}', () => _insertTag(prepController, '{detik}')),
          _insertChip('+ {jam}', () => _insertTag(prepController, '{jam}')),
          _insertChip('+ {ritase}', () => _insertTag(prepController, '{ritase}')),
        ],
      ),
      const SizedBox(height: 12),
      // Input Due Template + Chips
      TextFormField(
        controller: dueController,
        decoration: InputDecoration(
          labelText: 'Saatnya Berangkat (Jatuh Tempo)',
          hintText: '{rute} unit {unit}, saatnya berangkat.',
          isDense: true,
        ),
        onChanged: (v) => setState(() => selectedPreset = 'kustom'),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        children: [
          _insertChip('+ {rute}', () => _insertTag(dueController, '{rute}')),
          _insertChip('+ {unit}', () => _insertTag(dueController, '{unit}')),
          _insertChip('+ {jam}', () => _insertTag(dueController, '{jam}')),
          _insertChip('+ {ritase}', () => _insertTag(dueController, '{ritase}')),
        ],
      ),
      const SizedBox(height: 12),
      // Info Auto-Context
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '💡 Otomatis Cerdas: Jika jadwal hanya memiliki 1 rute aktif, tag {rute} otomatis hening agar tidak bertele-tele di pos pantau tunggal.',
          style: TextStyle(fontSize: 11, color: p.muted),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              ref.read(notificationServiceProvider).testSpeech(
                prepTemplate: prepController.text,
                dueTemplate: dueController.text,
                isMultiRoute: false,
              );
            },
            icon: const Icon(Icons.volume_up, size: 16),
            label: const Text('Uji Suara'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _resetToDefault,
            child: const Text('Reset Default'),
          ),
        ],
      ),
    ],
  ),
)
```

- [ ] **Step 4: Jalankan widget test dan pastikan PASS**

Command:
```bash
flutter test test/configuration_tts_ui_test.dart --no-pub
```
Expected: PASS.

- [ ] **Step 5: Commit perubahan Task 4**

Command:
```bash
git add lib/ui/configuration.dart test/configuration_tts_ui_test.dart
git commit -m "feat(ui): tambahkan kartu pengaturan format template TTS dengan chip penyisip variabel dan live test"
```

---

### Task 5: End-to-End Verification & Quality Gates

**Files:**
- Verification: All touched files

- [ ] **Step 1: Jalankan analisis statis Dart**

Command:
```bash
flutter analyze --no-pub
```
Expected: `No issues found!`.

- [ ] **Step 2: Jalankan seluruh pengujian unit/widget Flutter**

Command:
```bash
flutter test --no-pub
```
Expected: Semua test suite (termasuk `alarm_test.dart`, `configuration_tts_ui_test.dart`, dan widget test lainnya) bernilai PASS.

- [ ] **Step 3: Jalankan seluruh pengujian unit Android Kotlin**

Command:
```bash
./android/gradlew.bat -p android :app:testDebugUnitTest --console=plain
```
Expected: 100% tests PASS (tidak ada kegagalan pada `AlarmSpeechTextTest`).

- [ ] **Step 4: Verifikasi status git dan branch devmode**

Command:
```bash
git branch --show-current
git status --short
```
Expected: Branch aktif adalah `devmode` dan working tree bersih. **TIDAK** menjalankan build APK.
