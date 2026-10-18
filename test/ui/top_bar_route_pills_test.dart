import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';

void main() {
  group('Top Bar Route Pills Filtering & Code-Only Logic', () {
    test('Filtering active routes includes only participating routes', () {
      final routes = [
        HedgeRoute(
          id: 'r1',
          name: 'JAK.01 - TANJUNG PRIOK - PLUMPANG',
          color: 0xFF00E5FF,
          units: [],
          order: [],
          participates: true,
        ),
        HedgeRoute(
          id: 'r2',
          name: 'JAK.05 - SEMPER - RAWAMANGUN',
          color: 0xFFFF9800,
          units: [],
          order: [],
          participates: false,
        ),
        HedgeRoute(
          id: 'r3',
          name: 'JAK.115 – TERM.TANJUNG PRIOK',
          color: 0xFF00E5FF,
          units: [],
          order: [],
          participates: true,
        ),
      ];

      final activeRoutes = routes.where((r) => r.participates).toList();

      expect(activeRoutes.length, 2);
      expect(activeRoutes.map((r) => r.code).toList(), ['JAK.01', 'JAK.115']);
      expect(activeRoutes.map((r) => r.name).contains('JAK.05 - SEMPER - RAWAMANGUN'), isFalse);
    });

    test('Route code extraction handles dirty marker accurately', () {
      final route = HedgeRoute(
        id: 'r1',
        name: 'JAK.110A - RUSUN MARUNDA',
        color: 0xFF00E5FF,
        units: [],
        order: [],
      );

      final labelClean = '${route.code}${route.dirty ? ' •' : ''}';
      expect(labelClean, 'JAK.110A');
    });
  });
}
