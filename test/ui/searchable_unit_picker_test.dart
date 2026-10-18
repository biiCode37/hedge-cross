import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/components/searchable_unit_picker.dart';

void main() {
  group('SearchableUnitPicker Tests', () {
    final sampleUnits = [
      const FleetUnit(id: 'u1', number: '540', active: true),
      const FleetUnit(id: 'u2', number: '001', active: true),
      const FleetUnit(id: 'u3', number: 'KLM 1168', active: false),
    ];

    testWidgets('Renders placeholder when no unit is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableUnitPicker(
              selectedUnitNumber: null,
              availableUnits: sampleUnits,
              onUnitSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pilih Nomor Unit (Opsional)'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
    });

    testWidgets('Renders selected unit number and clear button', (tester) async {
      String? selected = '540';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableUnitPicker(
              selectedUnitNumber: selected,
              availableUnits: sampleUnits,
              onUnitSelected: (val) => selected = val,
            ),
          ),
        ),
      );

      expect(find.text('Unit 540'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });

    testWidgets('Opens picker and filters units by search query', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableUnitPicker(
              selectedUnitNumber: selected,
              availableUnits: sampleUnits,
              onUnitSelected: (val) => selected = val,
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Pilih Nomor Unit (Opsional)'));
      await tester.pumpAndSettle();

      expect(find.text('PILIH NOMOR UNIT'), findsOneWidget);
      expect(find.text('Unit 540'), findsOneWidget);
      expect(find.text('Unit 001'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), '1168');
      await tester.pumpAndSettle();

      expect(find.text('Unit 540'), findsNothing);
      expect(find.text('Unit KLM 1168'), findsOneWidget);

      // Select unit
      await tester.tap(find.text('Unit KLM 1168'));
      await tester.pumpAndSettle();

      expect(selected, 'KLM 1168');
    });
  });
}
