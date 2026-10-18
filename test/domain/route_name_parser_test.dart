import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';

void main() {
  group('Route Name Parser Tests', () {
    test('Standard dash delimiter separates code and trajectory', () {
      final parsed = splitRouteName('JAK.01 - TANJUNG PRIOK - PLUMPANG');
      expect(parsed.code, 'JAK.01');
      expect(parsed.trajectory, 'TANJUNG PRIOK - PLUMPANG');
    });

    test('En-dash delimiter separates code and trajectory', () {
      final parsed = splitRouteName('JAK.115 – TERM.TANJUNG PRIOK - PEGANGSAAN DUA');
      expect(parsed.code, 'JAK.115');
      expect(parsed.trajectory, 'TERM.TANJUNG PRIOK - PEGANGSAAN DUA');
    });

    test('Em-dash delimiter separates code and trajectory', () {
      final parsed = splitRouteName('JAK.115 — TERM.TANJUNG PRIOK');
      expect(parsed.code, 'JAK.115');
      expect(parsed.trajectory, 'TERM.TANJUNG PRIOK');
    });

    test('Suffix alphanumeric code (JAK.110A)', () {
      final parsed = splitRouteName('JAK.110A - RUSUN MARUNDA');
      expect(parsed.code, 'JAK.110A');
      expect(parsed.trajectory, 'RUSUN MARUNDA');
    });

    test('Single code without trajectory', () {
      final parsed = splitRouteName('JAK.88');
      expect(parsed.code, 'JAK.88');
      expect(parsed.trajectory, '');
    });

    test('HedgeRoute getters return expected code and trajectory', () {
      final route = HedgeRoute(
        id: 'r1',
        name: 'JAK.05 - SEMPER - RAWAMANGUN',
        color: 0xFF00E5FF,
        units: [],
        order: [],
      );
      expect(route.code, 'JAK.05');
      expect(route.trajectory, 'SEMPER - RAWAMANGUN');
    });
  });
}
