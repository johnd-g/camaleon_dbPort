import 'dart:convert';
import 'dart:typed_data';

import 'package:camaleon_db_port/core/utils/value_converter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mysql1/mysql1.dart' as mysql;

void main() {
  const converter = ValueConverter();

  Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

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

  test('mysql Blob TEXT decodes as UTF-8 string', () {
    final blob = mysql.Blob.fromBytes(utf8Bytes('admin'));
    expect(converter.convert(blob, 'TEXT'), 'admin');
  });

  test('Uint8List TEXT decodes and repairs mojibake', () {
    // UTF-8 bytes of "Jerónimo" mis-decoded as Latin-1 then re-encoded path:
    // store correct UTF-8 bytes → decode to proper string.
    expect(converter.convert(utf8Bytes('Jerónimo'), 'TEXT'), 'Jerónimo');

    // Classic mojibake string repair: Latin-1 reading of UTF-8.
    const mojibake = 'JerÃ³nimo';
    expect(converter.convert(mojibake, 'TEXT'), 'Jerónimo');
  });

  test('Blob INTEGER / REAL / NUMERIC from UTF-8 digits', () {
    expect(converter.convert(utf8Bytes('42'), 'INTEGER'), 42);
    expect(converter.convert(mysql.Blob.fromBytes(utf8Bytes('7')), 'INT'), 7);
    expect(converter.convert(utf8Bytes('48.0'), 'INTEGER'), 48);
    expect(converter.convert(utf8Bytes('4.5'), 'REAL'), 4.5);
    expect(converter.convert(utf8Bytes('10.25'), 'NUMERIC'), 10.25);
    expect(converter.convert(utf8Bytes('9'), 'NUMERIC'), 9);
  });

  test('Blob MySQL datetime becomes formatted text for NUMERIC/TEXT', () {
    final bytes = utf8Bytes('2018-05-10 14:30:00');
    expect(
      converter.convert(bytes, 'TEXT'),
      '2018-05-10 14:30:00',
    );
    expect(
      converter.convert(mysql.Blob.fromBytes(bytes), 'DATETIME'),
      '2018-05-10 14:30:00',
    );
  });

  test('BLOB affinity keeps raw bytes', () {
    final bytes = utf8Bytes('raw');
    expect(converter.convert(bytes, 'BLOB'), bytes);
    expect(
      converter.convert(mysql.Blob.fromBytes(bytes), 'BLOB'),
      bytes,
    );
  });

  test('INTEGER blank / null placeholders become 0', () {
    expect(converter.convert('', 'INTEGER'), 0);
    expect(converter.convert('   ', 'INTEGER'), 0);
    expect(converter.convert('null', 'INTEGER'), 0);
    expect(converter.convert('-', 'INTEGER'), 0);
    expect(converter.convert('n/a', 'INT'), 0);
  });

  test('INTEGER accepts HH:MM:SS duration as seconds', () {
    expect(converter.convert('00:05:00', 'INTEGER'), 300);
    expect(converter.convert('1:30:00', 'INTEGER'), 5400);
  });

  test('item_game_duration style empty string does not stay null', () {
    expect(converter.convert('', 'INTEGER'), isNotNull);
    expect(converter.convert('0', 'INTEGER'), 0);
  });
}
