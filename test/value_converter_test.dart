import 'package:camaleon_db_port/core/utils/value_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = ValueConverter();

  test('TEXT stores numbers as text, not REAL', () {
    expect(converter.convert(12.5, 'TEXT'), '12.5');
    expect(converter.convert(10, 'TEXT'), '10');
    expect(converter.convert(10.0, 'TEXT'), '10');
  });

  test('INTEGER truncates decimals', () {
    expect(converter.convert(18.9, 'INTEGER'), 18);
    expect(converter.convert('42', 'INTEGER'), 42);
  });

  test('REAL keeps floating values', () {
    expect(converter.convert('4.300', 'REAL'), 4.3);
    expect(converter.convert(1, 'REAL'), 1.0);
  });

  test('NUMERIC prefers int when no fraction', () {
    expect(converter.convert(10.0, 'NUMERIC'), 10);
    expect(converter.convert(10.25, 'NUMERIC'), 10.25);
    expect(converter.convert('7', 'NUMERIC'), 7);
  });

  test('Order_Card_ID style int to TEXT', () {
    expect(converter.convert(98765, 'TEXT'), '98765');
  });

  test('NULL stays NULL', () {
    expect(converter.convert(null, 'TEXT'), isNull);
    expect(converter.convert(null, 'INTEGER'), isNull);
  });

  test('DateTime becomes MySQL-like text', () {
    final dt = DateTime(2018, 5, 10);
    expect(converter.convert(dt, 'TEXT'), '2018-05-10 00:00:00');
  });
}
