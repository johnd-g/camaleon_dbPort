import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql1/mysql1.dart' as mysql;

/// Converts a MariaDB cell to the affinity already declared on the SQLite column.
///
/// mysql1 often returns TEXT/VARCHAR (and sometimes numeric text) as [mysql.Blob]
/// or [Uint8List]. Those bytes are decoded as UTF-8 before affinity conversion.
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
    if (value is Duration) return value.inSeconds;

    final text = _asDecodableText(value);
    if (text == null || _isBlankNumericText(text)) return 0;
    final asTime = _tryParseTimeToSeconds(text);
    if (asTime != null) return asTime;
    // Non-blank garbage stays null so import reports null data loss.
    return _numericTextToInt(text);
  }

  double? _asReal(Object value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is BigInt) return value.toDouble();
    if (value is bool) return value ? 1.0 : 0.0;
    if (value is Duration) return value.inSeconds.toDouble();

    final text = _asDecodableText(value);
    if (text == null || _isBlankNumericText(text)) return 0.0;
    return _numericTextToDouble(text);
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
    if (value is Duration) return value.inSeconds;

    final text = _asDecodableText(value);
    if (text == null || _isBlankNumericText(text)) return 0;

    final dt = _tryParseDateTime(text);
    if (dt != null) return _formatDateTime(dt);

    // TIME-only values (HH:MM:SS) → seconds.
    final asTime = _tryParseTimeToSeconds(text);
    if (asTime != null) return asTime;

    final asInt = _numericTextToInt(text);
    if (asInt != null &&
        RegExp(r'^[+-]?\d+$').hasMatch(text.trim())) {
      return asInt;
    }
    final asDouble = _numericTextToDouble(text);
    if (asDouble == null) return text;
    if (asDouble == asDouble.truncateToDouble()) return asDouble.toInt();
    return asDouble;
  }

  /// Empty / placeholder text that MariaDB often stores instead of SQL NULL.
  bool _isBlankNumericText(String value) {
    final t = value.trim();
    if (t.isEmpty) return true;
    final lower = t.toLowerCase();
    return lower == 'null' ||
        lower == 'nil' ||
        lower == 'none' ||
        lower == '-' ||
        lower == 'n/a' ||
        lower == 'na';
  }

  int? _tryParseTimeToSeconds(String raw) {
    final m = RegExp(
      r'^(\d{1,3}):([0-5]?\d):([0-5]?\d)$',
    ).firstMatch(raw.trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final sec = int.parse(m.group(3)!);
    return h * 3600 + min * 60 + sec;
  }

  Object? _asBlob(Object value) {
    final bytes = _asBytes(value);
    if (bytes != null) return bytes;
    if (value is String) return Uint8List.fromList(utf8.encode(value));
    return null;
  }

  String? _asText(Object value) {
    if (value is DateTime) return _formatDateTime(value);
    if (value is bool) return value ? '1' : '0';
    if (value is double) return _formatNumber(value);
    if (value is int || value is BigInt) return value.toString();

    final decoded = _asDecodableText(value);
    if (decoded != null) return decoded;

    if (value is String) return _repairUtf8Mojibake(value);
    return value.toString();
  }

  /// UTF-8 text payload from mysql1 Blob / raw bytes / plain String.
  String? _asDecodableText(Object value) {
    final bytes = _asBytes(value);
    if (bytes != null) {
      if (bytes.isEmpty) return '';
      try {
        return _repairUtf8Mojibake(utf8.decode(bytes));
      } catch (_) {
        try {
          return _repairUtf8Mojibake(latin1.decode(bytes));
        } catch (_) {
          return null;
        }
      }
    }
    if (value is String) {
      final trimmedSense = value.trim();
      if (trimmedSense.isEmpty) return '';
      final lower = trimmedSense.toLowerCase();
      if (lower == 'null' || lower == 'invalid date') return null;
      return _repairUtf8Mojibake(value);
    }
    // Avoid "Instance of 'Blob'" style toString for unknown wrappers.
    if (value is mysql.Blob) return null;
    final text = value.toString();
    if (text.trim().isEmpty) return null;
    return text;
  }

  Uint8List? _asBytes(Object value) {
    if (value is Uint8List) return value;
    if (value is mysql.Blob) return Uint8List.fromList(value.toBytes());
    if (value is List<int>) return Uint8List.fromList(value);
    return null;
  }

  /// UTF-8 text that was misread as Latin-1 (`JerÃ³nimo` → `Jerónimo`).
  String _repairUtf8Mojibake(String value) {
    if (value.isEmpty || value.codeUnits.every((unit) => unit < 0x80)) {
      return value;
    }
    try {
      final repaired = utf8.decode(latin1.encode(value));
      if (repaired != value && !repaired.contains('\uFFFD')) {
        return repaired;
      }
    } catch (_) {}
    return value;
  }

  int? _numericTextToInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final direct = int.tryParse(trimmed);
    if (direct != null) return direct;

    // DECIMAL text like "48.0" must not become 480.
    if (RegExp(r'^[+-]?\d+\.\d+(?:[eE][+-]?\d+)?$').hasMatch(trimmed)) {
      return double.tryParse(trimmed)?.truncate();
    }

    final sanitized = trimmed.replaceAll(RegExp(r'[^\d\-]'), '');
    return int.tryParse(sanitized);
  }

  double? _numericTextToDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final sanitized =
        trimmed.replaceAll(',', '.').replaceAll(RegExp(r'[^\d.\-eE+]'), '');
    return double.tryParse(sanitized.trim());
  }

  DateTime? _tryParseDateTime(String raw) {
    var dateString = raw.trim();
    if (dateString.isEmpty) return null;
    final lower = dateString.toLowerCase();
    if (lower == 'null' || lower == 'invalid date') return null;

    final direct = DateTime.tryParse(dateString);
    if (direct != null) return direct;

    if (dateString.contains(' ') && !dateString.contains('T')) {
      final mysqlPattern = RegExp(
        r'^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}(?:\.\d+)?)(.*)$',
      );
      final match = mysqlPattern.firstMatch(dateString);
      if (match != null) {
        final iso = '${match.group(1)}T${match.group(2)}${match.group(3) ?? ''}';
        final parsed = DateTime.tryParse(iso);
        if (parsed != null) return parsed;
      }
      final normalized = dateString.replaceFirst(' ', 'T');
      final parsed = DateTime.tryParse(normalized);
      if (parsed != null) return parsed;
    }
    return null;
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
    var text = d.toString();
    if (text.contains('e') || text.contains('E')) {
      text = d.toStringAsFixed(10).replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return text;
  }
}

enum SqliteAffinity { integer, real, numeric, text, blob }
