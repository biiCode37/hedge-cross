import 'package:flutter/material.dart';
import '../../domain/models.dart';
import '../design_system.dart';

/// Reusable Cyberpunk Searchable Dropdown Picker for selecting Fleet Units.
class SearchableUnitPicker extends StatelessWidget {
  final String? selectedUnitNumber;
  final List<FleetUnit> availableUnits;
  final ValueChanged<String?> onUnitSelected;
  final String labelText;

  const SearchableUnitPicker({
    super.key,
    required this.selectedUnitNumber,
    required this.availableUnits,
    required this.onUnitSelected,
    this.labelText = 'Nomor Unit Bawaan',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Theme.of(context).extension<HedgePalette>() ??
        (isDark ? HedgePalette.dark : HedgePalette.light);
    final cyan = isDark ? const Color(0xFF00E5FF) : p.cyanInk;
    final amber = isDark ? const Color(0xFFFF9800) : p.amberInk;
    final hasSelection = selectedUnitNumber != null && selectedUnitNumber!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
            fontFamily: HedgeTokens.cyberFont,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : p.muted,
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () => _openPicker(context, isDark, p, cyan, amber),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF070B12) : p.raised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasSelection
                    ? cyan.withValues(alpha: isDark ? 0.7 : 0.8)
                    : (isDark ? const Color(0xFF1E293B) : p.border),
                width: hasSelection ? 1.2 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  size: 18,
                  color: hasSelection ? cyan : (isDark ? const Color(0xFF64748B) : p.muted),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasSelection ? 'Unit $selectedUnitNumber' : 'Pilih Nomor Unit (Opsional)',
                    style: TextStyle(
                      fontFamily: HedgeTokens.cyberFont,
                      fontSize: 13,
                      fontWeight: hasSelection ? FontWeight.w800 : FontWeight.w500,
                      color: hasSelection
                          ? (isDark ? Colors.white : p.text)
                          : (isDark ? const Color(0xFF64748B) : p.muted),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasSelection)
                  InkWell(
                    onTap: () => onUnitSelected(null),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : p.muted,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark ? const Color(0xFF64748B) : p.muted,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openPicker(
    BuildContext context,
    bool isDark,
    HedgePalette p,
    Color cyan,
    Color amber,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UnitPickerSheet(
        selectedUnitNumber: selectedUnitNumber,
        availableUnits: availableUnits,
        onUnitSelected: onUnitSelected,
        isDark: isDark,
        p: p,
        cyan: cyan,
        amber: amber,
      ),
    );
  }
}

class _UnitPickerSheet extends StatefulWidget {
  final String? selectedUnitNumber;
  final List<FleetUnit> availableUnits;
  final ValueChanged<String?> onUnitSelected;
  final bool isDark;
  final HedgePalette p;
  final Color cyan;
  final Color amber;

  const _UnitPickerSheet({
    required this.selectedUnitNumber,
    required this.availableUnits,
    required this.onUnitSelected,
    required this.isDark,
    required this.p,
    required this.cyan,
    required this.amber,
  });

  @override
  State<_UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<_UnitPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final p = widget.p;
    final cyan = widget.cyan;

    final filtered = widget.availableUnits.where((u) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return u.number.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1017) : p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: cyan.withValues(alpha: isDark ? 0.4 : 0.5),
          width: 1.2,
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.directions_bus_rounded, size: 18, color: cyan),
                const SizedBox(width: 8),
                Text(
                  'PILIH NOMOR UNIT',
                  style: TextStyle(
                    fontFamily: HedgeTokens.cyberFont,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white : p.text,
                  ),
                ),
                const Spacer(),
                if (widget.selectedUnitNumber != null)
                  TextButton(
                    onPressed: () {
                      widget.onUnitSelected(null);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: widget.amber,
                    ),
                    child: const Text('Kosongkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: TextStyle(
                fontFamily: HedgeTokens.cyberFont,
                fontSize: 13,
                color: isDark ? Colors.white : p.text,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18, color: cyan),
                hintText: 'Cari nomor unit armada...',
                hintStyle: TextStyle(
                  fontFamily: HedgeTokens.cyberFont,
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : p.muted,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF070B12) : p.raised,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: cyan.withValues(alpha: isDark ? 0.3 : 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: cyan, width: 1.2),
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          const Divider(height: 16),
          // Unit List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: isDark ? const Color(0xFF475569) : p.muted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _query.isNotEmpty
                                ? 'Tidak ada unit cocok dengan "$_query"'
                                : 'Belum ada unit terdaftar pada rute ini.',
                            style: TextStyle(
                              fontFamily: HedgeTokens.cyberFont,
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : p.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_query.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                widget.onUnitSelected(_query);
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.add, size: 14),
                              label: Text('Gunakan "$_query"'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cyan,
                                side: BorderSide(color: cyan),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final u = filtered[i];
                      final isSelected = widget.selectedUnitNumber == u.number;
                      final parsed = splitUnitNumber(u.number);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () {
                            widget.onUnitSelected(u.number);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cyan.withValues(alpha: isDark ? 0.18 : 0.15)
                                  : (isDark ? const Color(0xFF070B12) : p.raised),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? cyan
                                    : (isDark ? const Color(0xFF1E293B) : p.border),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0B111A) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? cyan : (isDark ? const Color(0xFF334155) : p.border),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.directions_bus_rounded,
                                    size: 16,
                                    color: isSelected ? cyan : (u.active ? cyan : widget.amber),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unit ${u.number}',
                                        style: TextStyle(
                                          fontFamily: HedgeTokens.cyberFont,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : p.text,
                                        ),
                                      ),
                                      if (parsed.operator.isNotEmpty)
                                        Text(
                                          'Operator: ${parsed.operator}',
                                          style: TextStyle(
                                            fontFamily: HedgeTokens.cyberFont,
                                            fontSize: 10.5,
                                            color: isDark ? const Color(0xFF94A3B8) : p.muted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, size: 18, color: cyan),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
