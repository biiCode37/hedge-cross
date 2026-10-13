import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes_catalog.json has valid structure and includes default Mikrotrans routes', () {
    final file = File('assets/data/routes_catalog.json');
    expect(file.existsSync(), isTrue, reason: 'Katalog rute wajib ada di assets/data/');

    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;

    expect(json['version'], isNotNull);
    expect(json['routes'], isA<List>());
    final routes = json['routes'] as List;
    expect(routes.isNotEmpty, isTrue);

    final first = routes.first as Map<String, dynamic>;
    expect(first['code'], isNotNull);
    expect(first['name'], isNotNull);
    expect(first['units'], isA<List>());
  });
}
