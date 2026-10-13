import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/data/catalog_importer.dart';

void main() {
  group('CatalogImporter', () {
    test('builds Workspace with 18 routes and 586 units from routes_catalog.json', () {
      final file = File('assets/data/routes_catalog.json');
      expect(file.existsSync(), isTrue);

      final jsonString = file.readAsStringSync();
      final now = DateTime(2026, 10, 13, 8, 0);
      final workspace = catalogToWorkspace(jsonString, now);

      expect(workspace.routes.length, 18);
      
      final totalUnits = workspace.routes.fold<int>(0, (sum, r) => sum + r.units.length);
      expect(totalUnits, 586);

      expect(workspace.activeRouteId, isNotNull);
      expect(workspace.activeRoute, isNotNull);
      expect(workspace.activeRoute!.schedule, isNotNull);
      expect(workspace.activeRoute!.schedule!.departures.isNotEmpty, isTrue);
    });
  });
}
