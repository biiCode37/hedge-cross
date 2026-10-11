# Cyberpunk Telemetry Cockpit Fullscreen Alert Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the fullscreen alert interface into an Edge-to-Edge Cyberpunk Telemetry Cockpit / Flight HUD, eliminating all vertical blank space and ensuring 100% unified aesthetics across Flutter and Android Native, followed by a release APK build.

**Architecture:** Redesign `ForegroundAlarmOverlay` in Flutter and `AlarmSurface.kt` in Kotlin with proportional vertical zoning: Top Status Header, Monolith Unit 72sp, Giant 220dp Chrono-Dial with circular timeout arc, 3-Card Live Telemetry Grid, and Tactical Action Console.

**Tech Stack:** Flutter / Dart, CustomPainter, Android Native Kotlin View / Canvas 2D, Material / Hedge Design Tokens.

## Global Constraints
- Target branch must be `devmode`
- Zero blank space: proportional distribution from top to bottom
- Dual-theme support: high-contrast Obsidian Dark (`#070B12`) and Sleek Light (`#F8FAFC`)
- Every new APK build must be stored in `apks/v<version>/` with exactly 1 APK file per folder
- Follow the 4-file documentation standard in `docs/refactor/cyberpunk-fullscreen-alert/`

---

### Task 1: Re-architect Flutter Cockpit HUD in `lib/ui/alarm_overlay.dart`

**Files:**
- Modify: `lib/ui/alarm_overlay.dart`
- Test: `test/alarm_test.dart`

**Interfaces:**
- Consumes: `workspaceProvider`, `clockProvider`, `buildAlarmPlan`, `HedgeTokens`
- Produces: `ForegroundAlarmOverlay` with 220dp Chrono-Dial, 3 Telemetry Badges, and Monolith Unit

- [ ] **Step 1: Implement Cockpit HUD in `lib/ui/alarm_overlay.dart`**
  - Implement `ChronoDialRadarPainter` or proportional `CustomPaint` for 220dp dial.
  - Insert 3-Card Telemetry Grid (`JADWAL`, `RUTE`, `RITASE`).
  - Set unit font size to 72sp with neon glow.
  - Integrate circular timeout arc around the dial.

- [ ] **Step 2: Run widget tests to verify layout**
  Run: `flutter test test/alarm_test.dart`
  Expected: PASS (10/10 tests passed).

- [ ] **Step 3: Commit Task 1**
  Run: `git commit -am "feat(ui): implement Cyberpunk Telemetry Cockpit in Flutter alarm overlay"`

---

### Task 2: Re-architect Native Android Cockpit HUD in `AlarmSurface.kt`

**Files:**
- Modify: `android/app/src/main/kotlin/id/mikrotrans/hedge/hedge_flutter/AlarmSurface.kt`

**Interfaces:**
- Consumes: `ActiveAlarm`, `AlarmSpec`, `AlarmEngine`
- Produces: `CyberDialGaugeView` (220dp, timeout arc), 3-card telemetry row, Monolith Unit in `AlarmSurface`

- [ ] **Step 1: Update `CyberDialGaugeView` in `AlarmSurface.kt`**
  - Increase size to 220dp.
  - Add circular timeout energy arc using `canvas.drawArc`.
  - Draw large digital countdown (40sp bold).

- [ ] **Step 2: Build 3-Card Telemetry Row in Kotlin**
  - Create horizontal LinearLayout containing 3 equal-weight rounded cards: Jadwal WIB, Rute, Ritase.

- [ ] **Step 3: Commit Task 2**
  Run: `git commit -am "feat(android): implement Cyberpunk Telemetry Cockpit in native AlarmSurface"`

---

### Task 3: Verifikasi Kualitas Kode & Test Suite

**Files:**
- Test: `test/alarm_test.dart`

- [ ] **Step 1: Run static analysis**
  Run: `dart analyze`
  Expected: No issues found.

- [ ] **Step 2: Run all tests**
  Run: `flutter test`
  Expected: All 71 tests passed.

- [ ] **Step 3: Commit Task 3**
  Run: `git commit -am "test: verify Cockpit HUD across Flutter test suite"`

---

### Task 4: Bump Version & Compile Release APK v2.0.9

**Files:**
- Modify: `pubspec.yaml`
- Create: `apks/v2.0.9/hedge-v2.0.9.apk`

- [ ] **Step 1: Bump version in `pubspec.yaml` to `2.0.9+12`**
- [ ] **Step 2: Run `flutter build apk --release`**
- [ ] **Step 3: Place APK in `apks/v2.0.9/hedge-v2.0.9.apk`**
- [ ] **Step 4: Verify exactly 1 APK file in `apks/v2.0.9/`**

---

### Task 5: Dokumentasi Sesi Refactor 4 Berkas

**Files:**
- Modify: `docs/refactor/cyberpunk-fullscreen-alert/01-temuan-bug-dan-permasalahan.md`
- Modify: `docs/refactor/cyberpunk-fullscreen-alert/02-perbaikan-dan-solusi-kode.md`
- Modify: `docs/refactor/cyberpunk-fullscreen-alert/03-verifikasi-dan-hasil-pengujian.md`
- Modify: `docs/refactor/cyberpunk-fullscreen-alert/04-analogi-dan-dampak-non-teknis.md`

- [ ] **Step 1: Update all 4 docs with Cockpit HUD metrics and verification results**
- [ ] **Step 2: Commit documentation**
