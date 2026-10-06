part of 'app.dart';

extension _DataActions on _HomeState {
  Future<void> _settings(Workspace workspace) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pengaturan & data',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final theme in [
                  ('dark', 'Gelap'),
                  ('light', 'Terang'),
                  ('system', 'Sistem'),
                ])
                  ChoiceChip(
                    label: Text(theme.$2),
                    selected: workspace.theme == theme.$1,
                    onSelected: (_) {
                      controller.setTheme(theme.$1);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Data disimpan di perangkat ini. Sinkronisasi antarperangkat belum diaktifkan.',
            ),
            const SizedBox(height: 12),
            if (widget.notifications != null)
              AlarmPermissionPanel(
                service: widget.notifications!,
                workspace: () => ref.read(workspaceProvider).workspace,
              ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                operation(() async {
                  final path = await ExportService.save(
                    ExportService.backup(ref.read(workspaceProvider).workspace),
                    'hedge-backup-${workspace.date}.json',
                    'json',
                  );
                  if (path != null) toast('Backup disimpan: $path');
                });
              },
              icon: const Icon(Icons.save_alt),
              label: const Text('Backup JSON lengkap dengan histori'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                operation(_importFile);
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Impor backup / data web lama'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _pasteImport();
              },
              icon: const Icon(Icons.paste),
              label: const Text('Tempel JSON data web lama'),
            ),
            const SizedBox(height: 8),
            Text(
              '${workspace.events.where((e) => e.kind == 'departed').length} catatan aktual · Zona waktu Asia/Jakarta',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Selesai'),
            ),
          ],
        ),
      ),
    ),
  );
  Future<void> _importFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (picked == null) return;
    final file = picked.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    await _previewImport(utf8.decode(bytes));
  }

  Future<void> _pasteImport() async {
    final field = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tempel JSON localStorage'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: field,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'jadwalApp_multi_v5 / jadwalApp_v4',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, field.text),
            child: const Text('Pratinjau'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    field.dispose();
    if (raw != null) await operation(() => _previewImport(raw));
  }

  Future<void> _previewImport(String raw) async {
    if (utf8.encode(raw).length > 20 * 1024 * 1024) {
      throw const FormatException('File melebihi 20 MB.');
    }
    final directory = await getApplicationSupportDirectory();
    final imports = Directory('${directory.path}/imports');
    await imports.create(recursive: true);
    await File(
      '${imports.path}/raw-${DateTime.now().microsecondsSinceEpoch}.json',
    ).writeAsString(raw, flush: true);
    final preview = ImportService.preview(
      raw,
      ref.read(workspaceProvider).workspace.date,
    );
    if (!mounted) return;
    final yes = await confirm(
      'Impor ${preview.workspace.routes.length} rute?',
      '${preview.workspace.routes.map((r) => '${r.name}: ${r.units.length} unit').join('\n')}\n\n${preview.warnings.join('\n')}\n\nRute yang sudah ada tidak ditimpa. File mentah disalin ke penyimpanan aplikasi.',
    );
    if (yes && await controller.importWorkspace(preview.workspace)) {
      toast('Impor tersimpan. Periksa rute dan tanggal layanan.');
    }
  }

  Future<void> _export(Workspace workspace, HedgeRoute route) async {
    var shift = '1 (Pagi)';
    var first = 1;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ekspor ${route.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: shift,
                  decoration: const InputDecoration(labelText: 'Shift'),
                  items: [
                    for (final s in ['1 (Pagi)', '2 (Siang)', '3 (Malam)'])
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (s) => update(() => shift = s!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('Label ritase mulai')),
                    IconButton(
                      onPressed: first <= 1
                          ? null
                          : () => update(() => first--),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$first'),
                    IconButton(
                      onPressed: () => update(() => first++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                for (final action in [
                  'Salin teks',
                  'Bagikan teks / WhatsApp',
                  'Simpan TXT',
                  'Simpan XLSX semua rute',
                  'Simpan PDF',
                ])
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      operation(() async {
                        final name = route.name.replaceAll(
                          RegExp(r'[^\w.-]'),
                          '_',
                        );
                        switch (action) {
                          case 'Salin teks':
                            await ExportService.copy(
                              route,
                              shift: shift,
                              firstRound: first,
                            );
                            toast('Teks jadwal disalin.');
                          case 'Bagikan teks / WhatsApp':
                            await ExportService.shareText(
                              route,
                              shift: shift,
                              firstRound: first,
                            );
                          case 'Simpan TXT':
                            await ExportService.save(
                              utf8.encode(
                                ExportService.text(
                                  route,
                                  shift: shift,
                                  firstRound: first,
                                ),
                              ),
                              '$name-${route.schedule!.date}.txt',
                              'txt',
                            );
                          case 'Simpan XLSX semua rute':
                            await ExportService.save(
                              ExportService.xlsx(
                                workspace.routes,
                                shift: shift,
                                firstRound: first,
                              ),
                              'HEDGE-${workspace.date}.xlsx',
                              'xlsx',
                            );
                          case 'Simpan PDF':
                            await ExportService.save(
                              await ExportService.pdf(
                                route,
                                shift: shift,
                                firstRound: first,
                              ),
                              '$name-${route.schedule!.date}.pdf',
                              'pdf',
                            );
                        }
                      });
                    },
                    child: Text(action),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Ekspor menggunakan revisi tersimpan ${route.schedule!.date}. Pengaturan yang belum diterapkan tidak mengubah baris jadwal.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
