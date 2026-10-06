import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../domain/models.dart';

class ExportService {
  static String text(
    HedgeRoute route, {
    String shift = '1 (Pagi)',
    int firstRound = 1,
  }) {
    final revision = route.schedule;
    if (revision == null) throw StateError('Buat jadwal terlebih dahulu.');
    final lines = [
      'HEDGE · Headway Generator',
      'By Mikrotrans Utara',
      '${route.name} · ${revision.date} · Shift $shift',
      'Revisi ${revision.id} · ${revision.engineVersion}',
      'Jam ${revision.config.start}–${revision.config.end}',
      if (route.dirty)
        'Pengaturan belum diterapkan; ekspor menggunakan jadwal tersimpan.',
      '',
    ];
    for (final d in revision.departures) {
      lines.add(
        '${formatMinute(d.minute)} | Unit ${d.unitNumber} | R${d.round + firstRound - 1}${d.peak ? ' · PEAK' : ''} | ${d.nextGap == null ? 'Selesai' : '${d.nextGap} menit'}',
      );
    }
    return lines.join('\n');
  }

  static Future<void> copy(
    HedgeRoute route, {
    String shift = '1 (Pagi)',
    int firstRound = 1,
  }) => Clipboard.setData(
    ClipboardData(
      text: text(route, shift: shift, firstRound: firstRound),
    ),
  );
  static Future<void> shareText(
    HedgeRoute route, {
    String shift = '1 (Pagi)',
    int firstRound = 1,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text(route, shift: shift, firstRound: firstRound),
        title: 'Jadwal ${route.name}',
      ),
    );
  }

  static Uint8List backup(Workspace workspace) => Uint8List.fromList(
    utf8.encode(const JsonEncoder.withIndent('  ').convert(workspace.toJson())),
  );
  static Uint8List xlsx(
    List<HedgeRoute> routes, {
    String shift = '1 (Pagi)',
    int firstRound = 1,
  }) {
    final book = Excel.createExcel();
    final used = <String>{'sheet1'};
    for (final route in routes.where((r) => r.schedule != null)) {
      final base = route.name.replaceAll(RegExp(r'[\\/?*\[\]:]'), '_').trim();
      final short = base.isEmpty
          ? 'Rute'
          : base.substring(0, base.length > 24 ? 24 : base.length);
      var name = short;
      var suffix = 1;
      while (!used.add(name.toLowerCase())) {
        name = '${short}_${++suffix}';
      }
      final sheet = book[name];
      final revision = route.schedule!;
      sheet.appendRow([TextCellValue('HEDGE — By Mikrotrans Utara')]);
      sheet.appendRow([
        TextCellValue('${route.name} | ${revision.date} | Shift $shift'),
      ]);
      sheet.appendRow([
        TextCellValue('Revisi ${revision.id} | ${revision.engineVersion}'),
      ]);
      sheet.appendRow([
        TextCellValue('No'),
        TextCellValue('Ritase'),
        TextCellValue('Unit'),
        TextCellValue('Jam'),
        TextCellValue('Headway (menit)'),
        TextCellValue('Peak'),
      ]);
      for (final d in revision.departures) {
        sheet.appendRow([
          IntCellValue(d.ordinal),
          IntCellValue(d.round + firstRound - 1),
          TextCellValue(d.unitNumber),
          TextCellValue(formatMinute(d.minute)),
          d.nextGap == null ? TextCellValue('') : IntCellValue(d.nextGap!),
          TextCellValue(d.peak ? 'Ya' : ''),
        ]);
      }
    }
    if (used.isEmpty) throw StateError('Tidak ada jadwal tersimpan.');
    book.delete('Sheet1');
    book.setDefaultSheet(book.tables.keys.first);
    return Uint8List.fromList(book.encode()!);
  }

  static Future<Uint8List> pdf(
    HedgeRoute route, {
    String shift = '1 (Pagi)',
    int firstRound = 1,
  }) async {
    final revision = route.schedule;
    if (revision == null) throw StateError('Buat jadwal terlebih dahulu.');
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-bold.ttf'),
    );
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: bold),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 1000,
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'HEDGE | Headway Generator',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'By Mikrotrans Utara | ${route.name} | ${revision.date} | Shift $shift',
            ),
            pw.Text(
              'Revisi ${revision.id} | ${revision.engineVersion}',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${context.pageNumber}/${context.pagesCount}'),
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: ['No', 'Ritase', 'Unit', 'Jam', 'Headway', 'Peak'],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9),
            data: revision.departures
                .map(
                  (d) => [
                    '${d.ordinal}',
                    '${d.round + firstRound - 1}',
                    d.unitNumber,
                    formatMinute(d.minute),
                    d.nextGap == null ? '-' : '${d.nextGap} m',
                    d.peak ? 'YA' : '',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return document.save();
  }

  static Future<String?> save(
    Uint8List bytes,
    String name,
    String extension,
  ) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan $name',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: bytes,
    );
    if (path == null) return null;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return path;
  }

  static Future<void> shareBytes(
    Uint8List bytes,
    String name,
    String mime,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mime)],
        title: name,
      ),
    );
  }
}
