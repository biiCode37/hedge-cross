import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';

void main() {
  group('Route Tab Sorting & Trajectory Tests', () {
    test('Active participating routes are sorted to the top', () {
      final routes = [
        HedgeRoute(
          id: 'r1',
          name: 'JAK.01 - TANJUNG PRIOK - PLUMPANG',
          color: 0xFF00E5FF,
          units: [],
          order: [],
          participates: false,
        ),
        HedgeRoute(
          id: 'r2',
          name: 'JAK.05 - SEMPER - RAWAMANGUN',
          color: 0xFFFF9800,
          units: [],
          order: [],
          participates: true,
        ),
        HedgeRoute(
          id: 'r3',
          name: 'JAK.115 – TERM.TANJUNG PRIOK',
          color: 0xFF00E5FF,
          units: [],
          order: [],
          participates: false,
        ),
        HedgeRoute(
          id: 'r4',
          name: 'JAK.110A - RUSUN MARUNDA',
          color: 0xFF00E5FF,
          units: [],
          order: [],
          participates: true,
        ),
      ];

      final sortedRoutes = [...routes]..sort((a, b) {
          if (a.participates == b.participates) return 0;
          return a.participates ? -1 : 1;
        });

      expect(sortedRoutes.map((r) => r.code).toList(), [
        'JAK.05',
        'JAK.110A',
        'JAK.01',
        'JAK.115',
      ]);
      expect(sortedRoutes[0].participates, isTrue);
      expect(sortedRoutes[1].participates, isTrue);
      expect(sortedRoutes[2].participates, isFalse);
      expect(sortedRoutes[3].participates, isFalse);
    });

    test('Route trajectory formatting separates code and sub-title correctly', () {
      final route = HedgeRoute(
        id: 'r1',
        name: 'JAK.115 – TERM.TANJUNG PRIOK - PEGANGSAAN DUA',
        color: 0xFF00E5FF,
        units: [],
        order: [],
      );

      expect(route.code, 'JAK.115');
      expect(route.trajectory, 'TERM.TANJUNG PRIOK - PEGANGSAAN DUA');
    });
  });
}
