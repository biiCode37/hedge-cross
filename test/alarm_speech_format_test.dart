import 'package:flutter_test/flutter_test.dart';

String formatSpeech(String template, {required String unit, required String driver, required String seconds}) {
  var result = template
      .replaceAll('{unit}', unit)
      .replaceAll('{pramudi}', driver)
      .replaceAll('{detik}', seconds);
  
  result = result
      .replaceAll(RegExp(r'\s*,\s*'), ', ')
      .replaceAll(RegExp(r'\s*\.\s*'), '. ')
      .replaceAll(RegExp(r'^([,\s.-]+)'), '')
      .replaceAll(RegExp(r',\s*(,\s*)+'), ', ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return result;
}

void main() {
  test('formatSpeech with driver substitutes properly', () {
    final text = formatSpeech(
      'Unit {unit}, {pramudi}, saatnya berangkat.',
      unit: '540',
      driver: 'Bambang',
      seconds: '10',
    );
    expect(text, 'Unit 540, Bambang, saatnya berangkat.');
  });

  test('formatSpeech without driver cleans duplicate commas cleanly', () {
    final text = formatSpeech(
      'Unit {unit}, {pramudi}, saatnya berangkat.',
      unit: '540',
      driver: '',
      seconds: '10',
    );
    expect(text, 'Unit 540, saatnya berangkat.');
  });
}
