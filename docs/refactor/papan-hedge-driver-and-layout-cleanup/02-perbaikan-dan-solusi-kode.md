# Perbaikan dan Solusi Kode: Rekayasa Layout Papan HEDGE & Integrasi Nama Pramudi

## 1. Arsitektur Perbaikan

Untuk menyelesaikan permasalahan visual dan menyajikan informasi pramudi yang ergonomis, diterapkan restrukturisasi menyeluruh pada tiga komponen inti:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   KEBERANGKATAN BERIKUTNYA (HERO)                      │
│                           KWK 222171                                   │
│                  [ 👤 Syarifudin ]  ◄── (Badge Baru Pramudi)          │
│                      ( 03:32:48 )                                      │
├────────────────────────────────────────────────────────────────────────┤
│ WAKTU        ARMADA · PRAMUDI                            HITUNG MUNDUR │
│              (Spasi lega 44px)                           (Lega 80px)   │
├────────────────────────────────────────────────────────────────────────┤
│ 13:30  (●)   [ • AKTIF · Syarifudin ]  R1  PEAK               03:32:48 │
│ JAK.115      KWK 222171                                  HITUNG MUNDUR │
│                                                                        │
│ 13:38   ○    [ 👤 Munif ]  R1                                 03:40:48 │
│ JAK.115      KWK 222181                                  HITUNG MUNDUR │
│                                                                        │
│ 13:46   ○    [ 👤 Dede ]  R1                                  03:48:48 │
│ JAK.115      KWK 222156                                  HITUNG MUNDUR │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Rincian Modifikasi File

### A. Komponen Panel Fokus Keberangkatan: [`lib/ui/dispatch_components.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/dispatch_components.dart)
Menambahkan badge nama pramudi bercahaya tepat di bawah nomor kode unit dan di atas lingkaran *countdown*:
```dart
if (widget.focus.departure.driverName != null &&
    widget.focus.departure.driverName!.trim().isNotEmpty) ...[
  const SizedBox(height: 6),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0F172A) : p.focusSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: accent.withValues(alpha: isDark ? 0.45 : 0.55),
        width: 1.2,
      ),
      boxShadow: isDark
          ? [BoxShadow(color: accent.withValues(alpha: 0.25 * pulse), blurRadius: 8)]
          : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_rounded, size: widget.large ? 16 : 14, color: accent),
        const SizedBox(width: 6),
        Text(
          widget.focus.departure.driverName!.trim(),
          key: const ValueKey('focus-driver-name'),
          style: TextStyle(
            fontFamily: HedgeTokens.cyberFont,
            fontSize: widget.large ? 15 : 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isDark ? Colors.white : p.text,
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 8),
],
```

### B. Linimasa Papan HEDGE: [`lib/ui/board.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/board.dart)
1. **Penggantian Label "STANDBY" dengan Nama Pramudi:**
   ```dart
   final hasDriver = departure.driverName != null && departure.driverName!.trim().isNotEmpty;
   final driverDisplayName = hasDriver ? departure.driverName!.trim() : null;
   final statusText = due
       ? 'BOARDING'
       : (imminent
           ? 'BERSIAP'
           : (isFocused
               ? (driverDisplayName != null ? 'AKTIF · $driverDisplayName' : 'AKTIF')
               : (driverDisplayName ?? 'STANDBY')));
   ```
2. **Eliminasi Tumpang Tindih Kolom Kanan:**
   Menghapus `Row` yang menempatkan badge pramudi di samping kanan nomor unit raksasa. Nomor unit kini berdiri sendiri di baris bawahnya dengan `FittedBox` terisolasi, mengeliminasi overflow dan tumpang tindih ke kolom hitung mundur secara tuntas.
3. **Pelebaran & Penyelarasan Kolom Grid:**
   - Kolom Waktu diperlebar ke `width: 60` dengan spasi vertikal proporsional.
   - Kolom Hitung Mundur diperlebar dari `width: 68` menjadi `width: 80` dengan `SizedBox(width: 6)` pemisah.
   - Header daftar diperbarui dari `ARMADA · STATUS` menjadi `ARMADA · PRAMUDI` dan sejajar presisi dengan baris item di bawahnya.

### C. Visual Presisi Rel Linimasa: [`lib/ui/schedule_timeline.dart`](file:///d:/MINE/HEDGE-FLUTTER/lib/ui/schedule_timeline.dart)
Memperbaiki `TransitRailPainter`:
- Membatasi blur aura glow pendaran dari 6px menjadi 3px dan node radius disesuaikan ke 6.5px (fokus) dan 4.5px (biasa). Cahaya kini terkunci tajam di dalam kolom rel tanpa tumpah (*bleeding*) ke teks jam maupun teks armada.
