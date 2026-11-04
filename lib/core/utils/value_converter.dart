import 'dart:typed_data';

import 'package:mysql1/mysql1.dart' as mysql;

/// Converts a MariaDB cell to the affinity already declared on the SQLite column.
class ValueConverter {
  const ValueConverter();

  Object? convert(Object? value, String sqliteType) {
    if (value == null) return null;

    final affinity = sqliteAffinity(sqliteType);
    switch (affinity) {
      case SqliteAffinity.integer:
        return _asInteger(value);
      case SqliteAffinity.real:
        return _asReal(value);
      case SqliteAffinity.numeric:
        return _asNumeric(value);
      case SqliteAffinity.blob:
        return _asBlob(value);
      case SqliteAffinity.text:
        return _asText(value);
    }
  }

  SqliteAffinity sqliteAffinity(String declaredType) {
    final t = declaredType.trim().toUpperCase();
    if (t.contains('INT')) return SqliteAffinity.integer;
    if (t.contains('CHAR') ||
        t.contains('CLOB') ||
        t.contains('TEXT') ||
        t.isEmpty) {
      return SqliteAffinity.text;
    }
    if (t.contains('BLOB')) return SqliteAffinity.blob;
    if (t.contains('REAL') || t.contains('FLOA') || t.contains('DOUB')) {
      return SqliteAffinity.real;
    }
    // NUMERIC / DECIMAL / BOOLEAN / DATE / DATETIME fall here.
    if (t.contains('NUM') ||
        t.contains('DEC') ||
        t.contains('BOOL') ||
        t.contains('DATE') ||
        t.contains('TIME')) {
      return SqliteAffinity.numeric;
    }
    return SqliteAffinity.numeric;
  }

  int? _asInteger(Object value) {
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is double) return value.truncate();
    if (value is DateTime) return value.millisecondsSinceEpoch;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(text);
    return asDouble?.truncate();
  }

  double? _asReal(Object value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is BigInt) return value.toDouble();
    if (value is bool) return value ? 1.0 : 0.0;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Object? _asNumeric(Object value) {
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    if (value is BigInt) return value.toInt();
    if (value is double) {
      if (value == value.truncateToDouble()) return value.toInt();
      return value;
    }
    if (value is DateTime) return _formatDateTime(value);
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final asInt = int.tryParse(text);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(text);
    if (asDouble == null) return text;
    if (asDouble == asDouble.truncateToDouble()) return asDouble.toInt();
    return asDouble;
  }

  Object? _asBlob(Object value) {
    if (value is Uint8List) return value;
    if (value is List<int>) return Uint8List.fromList(value);
    if (value is mysql.Blob) return Uint8List.fromList(value.toBytes());
    // Never stringify blobs for storage when unexpected type appears.
    if (value is String) return Uint8List.fromList(value.codeUnits);
    return null;
  }

  String _asText(Object value) {
    if (value is DateTime) return _formatDateTime(value);
    if (value is bool) return value ? '1' : '0';
    if (value is Uint8List || value is List<int> || value is mysql.Blob) {
      // Spec: do not print blobs; also do not coerce them into TEXT columns.
      return '';
    }
    if (value is double) return _formatNumber(value);
    if (value is int || value is BigInt || value is String) {
      return value.toString();
    }
    return value.toString();
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year.toString().padLeft(4, '0')}-'
        '${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  String _formatNumber(num value) {
    if (value is int) return value.toString();
    final d = value.toDouble();
    if (d == d.truncateToDouble()) return d.toInt().toString();
    // Keep a stable decimal text without forcing fixed scale.
    var text = d.toString();
    if (text.contains('e') || text.contains('E')) {
      text = d.toStringAsFixed(10).replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return text;
  }
}

enum SqliteAffinity { integer, real, numeric, text, blob }
