import 'package:camaleon_db_port/core/utils/mariadb_identifiers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanitizes hyphenated folder names', () {
    expect(sanitizeMariaDbSchemaName('demoperu-sami'), 'demoperu_sami');
    expect(sanitizeMariaDbSchemaName('demo peru'), 'demo_peru');
    expect(sanitizeMariaDbSchemaName('demoperu'), 'demoperu');
  });

  test('handles empty and leading digits', () {
    expect(sanitizeMariaDbSchemaName(''), 'camaleon_import');
    expect(sanitizeMariaDbSchemaName('---'), 'camaleon_import');
    expect(sanitizeMariaDbSchemaName('9store'), 'db_9store');
  });

  test('quotes identifiers', () {
    expect(quoteMariaDbIdentifier('demoperu_sami'), '`demoperu_sami`');
    expect(quoteMariaDbIdentifier('a`b'), '`a``b`');
  });
}
