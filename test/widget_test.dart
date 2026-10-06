import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/data/workspace_repository.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/app.dart';

class MemoryRepository implements WorkspaceRepository {
  Workspace? value;
  @override
  Future<Workspace?> load() async => value;
  @override
  Future<void> save(Workspace workspace) async {
    value = workspace;
  }

  @override
  Future<void> close() async {}
}

void main() {
  var previewFontsLoaded = false;
  for (final width in [360.0, 1200.0]) {
    for (final theme in ['dark', 'light']) {
      testWidgets(
        'Dispatcher $width $theme: fleet edits preserve committed schedule',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          if (Platform.environment['HEDGE_CAPTURE'] == '1' &&
              !previewFontsLoaded) {
            final font = FontLoader('HedgeRoboto')
              ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))
              ..addFont(rootBundle.load('assets/fonts/roboto-bold.ttf'));
            await font.load();
            final icons = FontLoader('MaterialIcons')
              ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
            await icons.load();
            previewFontsLoaded = true;
          }
          final repository = MemoryRepository();
          final workspace = sampleWorkspace(
            DateTime.utc(2026, 10, 5, 0),
          ).copyWith(theme: theme);
          final previewKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: previewKey,
              child: ProviderScope(
                overrides: [
                  repositoryProvider.overrideWithValue(repository),
                  initialWorkspaceProvider.overrideWithValue(workspace),
                  clockProvider.overrideWith(
                    (ref) =>
                        Stream.value(DateTime.utc(2026, 10, 4, 23, 58, 20)),
                  ),
                ],
                child: const HedgeApp(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (Platform.environment['HEDGE_CAPTURE'] == '1') {
            await tester.runAsync(
              () => precacheImage(
                const AssetImage('assets/hedge-logo.jpg'),
                tester.element(find.byType(HedgeApp)),
              ),
            );
            await tester.pump();
          }
          expect(find.text('HEDGE'), findsOneWidget);
          expect(find.text('312 keberangkatan'), findsOneWidget);
          expect(tester.takeException(), isNull);
          if (Platform.environment['HEDGE_CAPTURE'] == '1') {
            await tester.runAsync(() async {
              final boundary =
                  previewKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final folder = Directory('docs/screenshots');
              await folder.create(recursive: true);
              await File(
                '${folder.path}/dispatcher-${width.toInt()}-$theme.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.tap(find.text('Armada'));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(Switch).first);
          await tester.pumpAndSettle();
          expect(repository.value!.activeRoute!.activeUnits.length, 38);
          expect(
            repository.value!.activeRoute!.schedule!.departures.length,
            312,
          );
          expect(repository.value!.activeRoute!.dirty, isTrue);
          await tester.tap(find.text('Jadwal'));
          await tester.pumpAndSettle();
          expect(
            find.text('Pengaturan berubah. Jadwal tersimpan belum diperbarui.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
