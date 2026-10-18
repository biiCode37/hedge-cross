import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/workspace_controller.dart';
import '../domain/models.dart';
import 'cockpit_components.dart';
import 'components/searchable_unit_picker.dart';
import 'design_system.dart';

class DriverMasterSheet extends ConsumerStatefulWidget {
  final HedgeRoute route;
  const DriverMasterSheet({super.key, required this.route});

  @override
  ConsumerState<DriverMasterSheet> createState() => _DriverMasterSheetState();
}

class _DriverMasterSheetState extends ConsumerState<DriverMasterSheet> {
  String _filter = 'semua'; // 'semua', 'tetap', 'cadangan'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).extension<HedgePalette>() ??
        (isDark ? HedgePalette.dark : HedgePalette.light);
    final cyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;
    final amber = isDark ? const Color(0xFFFF9800) : p.amberInk;

    // Ambil rute terbaru dari workspace provider jika ada
    final workspace = ref.watch(workspaceProvider).workspace;
    final currentRoute = workspace.routes.firstWhere(
      (r) => r.id == widget.route.id,
      orElse: () => widget.route,
    );

    final filteredDrivers = currentRoute.drivers.where((d) {
      if (_filter == 'tetap' && d.status != DriverStatus.tetap) return false;
      if (_filter == 'cadangan' && d.status != DriverStatus.cadangan) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return d.fullName.toLowerCase().contains(q) || d.callName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1017) : p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: cyan.withValues(alpha: isDark ? 0.3 : 0.4),
          width: 1.2,
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CockpitStatusBadge(
                            label: 'MASTER PRAMUDI',
                            isAmber: false,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              currentRoute.code,
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: cyan,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentRoute.drivers.length} pramudi terdaftar (${currentRoute.drivers.where((d) => d.status == DriverStatus.tetap).length} tetap, ${currentRoute.drivers.where((d) => d.status == DriverStatus.cadangan).length} cadangan)',
                        style: TextStyle(
                          fontFamily: HedgeTokens.cyberFont,
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: cyan.withValues(alpha: isDark ? 0.2 : 0.15),
                    foregroundColor: cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: cyan.withValues(alpha: 0.5)),
                    ),
                  ),
                  tooltip: 'Tambah Pramudi',
                  onPressed: () => _openDriverForm(currentRoute),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                ),
              ],
            ),
          ),
          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontSize: 13,
                    color: isDark ? Colors.white : p.text,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 18, color: cyan),
                    hintText: 'Cari nama supir...',
                    hintStyle: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 12,
                      color: isDark ? const Color(0xFF64748B) : p.muted,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF070B12) : p.raised,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: cyan.withValues(alpha: isDark ? 0.25 : 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: cyan, width: 1.2),
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'semua', label: Text('Semua', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'tetap', label: Text('Tetap', style: TextStyle(fontSize: 11))),
                      ButtonSegment(value: 'cadangan', label: Text('Cadangan', style: TextStyle(fontSize: 11))),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) => setState(() => _filter = s.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 12),
          // Driver List
          Expanded(
            child: filteredDrivers.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_outlined, size: 40, color: isDark ? const Color(0xFF475569) : p.muted),
                          const SizedBox(height: 10),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada supir dengan kata kunci "$_searchQuery"'
                                : 'Belum ada data pramudi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 12.5,
                              color: isDark ? const Color(0xFF94A3B8) : p.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cyan,
                              side: BorderSide(color: cyan.withValues(alpha: 0.5)),
                            ),
                            onPressed: () => _openDriverForm(currentRoute),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Tambah Pramudi Pertama', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    itemCount: filteredDrivers.length,
                    itemBuilder: (ctx, i) {
                      final driver = filteredDrivers[i];
                      final isTetap = driver.status == DriverStatus.tetap;
                      return CockpitManifestCard(
                        key: ValueKey('driver-card-${driver.id}'),
                        isAmber: !isTetap,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isTetap
                                ? cyan.withValues(alpha: 0.15)
                                : amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isTetap
                                  ? cyan.withValues(alpha: isDark ? 0.6 : 0.8)
                                  : amber.withValues(alpha: isDark ? 0.6 : 0.8),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            driver.callName.isNotEmpty ? driver.callName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isTetap ? cyan : amber,
                            ),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  driver.callName,
                                  style: TextStyle(
                                    fontFamily: HedgeTokens.cyberFont,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : p.text,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isTetap
                                        ? cyan.withValues(alpha: 0.15)
                                        : amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isTetap
                                          ? cyan.withValues(alpha: 0.4)
                                          : amber.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isTetap ? 'TETAP' : 'CADANGAN',
                                    style: TextStyle(
                                      fontFamily: HedgeTokens.cyberFont,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 9.5,
                                      letterSpacing: 0.5,
                                      color: isTetap ? cyan : amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              driver.fullName,
                              style: TextStyle(
                                fontFamily: HedgeTokens.cyberFont,
                                fontSize: 12,
                                color: isDark ? const Color(0xFFCBD5E1) : p.text,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            driver.defaultUnitNumber != null
                                ? 'Unit Default: ${driver.defaultUnitNumber} · Shift ${driver.defaultShift ?? 1}'
                                : 'Siap ditugaskan fleksibel',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : p.muted,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit pramudi',
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: isDark ? const Color(0xFF94A3B8) : p.muted,
                              ),
                              onPressed: () => _openDriverForm(currentRoute, existing: driver),
                            ),
                            IconButton(
                              tooltip: 'Hapus pramudi',
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Hapus Pramudi ${driver.callName}?'),
                                    content: Text('Pramudi "${driver.fullName}" akan dihapus dari rute ini.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await ref.read(workspaceProvider.notifier).deleteDriver(currentRoute, driver.id);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDriverForm(HedgeRoute route, {Driver? existing}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).extension<HedgePalette>() ??
        (isDark ? HedgePalette.dark : HedgePalette.light);
    final cyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;

    final nameController = TextEditingController(text: existing?.fullName ?? '');
    final callController = TextEditingController(text: existing?.callName ?? '');
    String? selectedUnit = existing?.defaultUnitNumber;
    var status = existing?.status ?? DriverStatus.tetap;
    var shift = existing?.defaultShift ?? 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0C1017) : p.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cyan.withValues(alpha: 0.5)),
              ),
              title: Text(
                existing == null ? 'Tambah Pramudi Baru' : 'Edit Pramudi',
                style: TextStyle(
                  fontFamily: HedgeTokens.cyberFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDark ? Colors.white : p.text,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap (KTP/ID)',
                        hintText: 'Contoh: Bambang Hariyanto',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: callController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Panggilan (Dilafalkan TTS)',
                        hintText: 'Contoh: Bambang',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Status:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Tetap'),
                          selected: status == DriverStatus.tetap,
                          onSelected: (_) => setDialogState(() => status = DriverStatus.tetap),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Cadangan'),
                          selected: status == DriverStatus.cadangan,
                          onSelected: (_) => setDialogState(() => status = DriverStatus.cadangan),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SearchableUnitPicker(
                      selectedUnitNumber: selectedUnit,
                      availableUnits: route.units,
                      onUnitSelected: (val) => setDialogState(() => selectedUnit = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Shift Default:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('☀️ Pagi'),
                          selected: shift == 1,
                          onSelected: (_) => setDialogState(() => shift = 1),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('🌙 Siang'),
                          selected: shift == 2,
                          onSelected: (_) => setDialogState(() => shift = 2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: const Color(0xFF070B12),
                  ),
                  onPressed: () {
                    final callName = callController.text.trim();
                    if (callName.isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final callName = callController.text.trim();
      final fullName = nameController.text.trim().isNotEmpty ? nameController.text.trim() : callName;
      final unitNum = selectedUnit != null && selectedUnit!.trim().isNotEmpty
          ? selectedUnit!.trim()
          : null;

      final controller = ref.read(workspaceProvider.notifier);
      if (existing == null) {
        final newDriver = Driver(
          id: 'driver-${DateTime.now().millisecondsSinceEpoch}',
          routeId: route.id,
          fullName: fullName,
          callName: callName,
          status: status,
          defaultUnitNumber: unitNum,
          defaultShift: shift,
          active: true,
        );
        await controller.addDriver(route, newDriver);
      } else {
        final updated = existing.copyWith(
          fullName: fullName,
          callName: callName,
          status: status,
          defaultUnitNumber: unitNum,
          defaultShift: shift,
        );
        await controller.updateDriver(route, updated);
      }
    }
  }
}
