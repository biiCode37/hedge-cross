# Perbaikan & Solusi Kode: Halaman 02 Armada

## 1. Arsitektur Solusi & Pemisahan Tanggung Jawab
Solusi diimplementasikan secara berlapis dan mematuhi prinsip *clean architecture* serta *separation of concerns*:
- **Domain Layer (`lib/domain/models.dart`):** Menambahkan fungsi murni `splitUnitNumber` dan tipe data `ParsedUnitNumber` untuk memisahkan prefix non-angka (kode operator) dan angka nomor body secara aman dan deterministik.
- **Application Layer (`lib/application/workspace_controller.dart`):** Memodifikasi `setUnitsActive` dan `deleteUnits` agar menerima `Iterable<String>` serta menempatkan armada yang baru diaktifkan ke posisi paling awal pada `route.order` sesuai urutan seleksi dispatcher.
- **UI Presentation Layer (`lib/ui/app.dart`):**
  - Mengubah tipe state `selectedFleetIds` dari `Set<String>` menjadi `List<String>`.
  - Mengganti icon checklist menjadi container cyber glow dengan angka auto-increment dinamis `[1, 2, 3...]`.
  - Menghapus prefix kata "Unit".
  - Menampilkan kode operator di posisi baris atas dengan micro-font tactical, dan nomor body di bawahnya dengan font monospaced tebal 17sp.

## 2. Detail Kode Utama

### A. Parser Helper `splitUnitNumber` (`lib/domain/models.dart`)
```dart
typedef ParsedUnitNumber = ({String operator, String number});

ParsedUnitNumber splitUnitNumber(String raw) {
  final trimmed = raw.trim();
  final match = RegExp(r'^([^\d]+)[\s\-_./]*(.*)$').firstMatch(trimmed);
  if (match != null && match.group(2)!.isNotEmpty) {
    return (
      operator: match.group(1)!.replaceAll(RegExp(r'[\s\-_./]+$'), '').toUpperCase(),
      number: match.group(2)!.trim(),
    );
  }
  return (operator: '', number: trimmed);
}
```

### B. Urutan Seleksi pada `setUnitsActive` (`lib/application/workspace_controller.dart`)
```dart
  Future<bool> setUnitsActive(HedgeRoute route, Iterable<String> unitIds, bool active) {
    final unitIdSet = unitIds.toSet();
    final orderedSelection = unitIds.toList();
    final order = active
        ? [
            ...orderedSelection,
            ...route.order.where((id) => !unitIdSet.contains(id)),
          ]
        : route.order.where((id) => !unitIdSet.contains(id)).toList();
    return updateRoute(
      route.copyWith(
        units: route.units
            .map((u) => unitIdSet.contains(u.id) ? u.copyWith(active: active) : u)
            .toList(),
        order: order,
      ),
    );
  }
```

### C. Komponen Manifest Card UI (`lib/ui/app.dart`)
```dart
leading: Container(
  width: 38,
  height: 38,
  decoration: BoxDecoration(
    color: isSelected
        ? cyan.withValues(alpha: 0.25)
        : (isDark ? const Color(0xFF070B12) : p.raised),
    borderRadius: BorderRadius.circular(6),
    border: Border.all(
      color: isSelected
          ? cyan
          : (unit.active
              ? cyan.withValues(alpha: isDark ? 0.6 : 0.8)
              : amber.withValues(alpha: isDark ? 0.4 : 0.6)),
      width: isSelected ? 1.6 : 1.2,
    ),
  ),
  alignment: Alignment.center,
  child: isSelected
      ? Text(
          '${selectionIndex + 1}',
          style: TextStyle(
            fontFamily: HedgeTokens.cyberFont,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: cyan,
          ),
        )
      : Icon(
          Icons.directions_bus,
          size: 20,
          color: unit.active ? cyan : amber,
        ),
),
title: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    if (parsed.operator.isNotEmpty)
      Text(
        parsed.operator,
        style: TextStyle(
          fontFamily: HedgeTokens.cyberFont,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDark ? const Color(0xFF94A3B8) : p.muted,
        ),
      ),
    Text(
      parsed.number,
      style: TextStyle(
        fontFamily: HedgeTokens.cyberFont,
        fontWeight: FontWeight.w800,
        fontSize: 17,
        letterSpacing: 0.5,
        color: isDark ? Colors.white : p.text,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  ],
),
```
