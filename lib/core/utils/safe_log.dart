import 'dart:typed_data';

import 'package:mysql1/mysql1.dart' as mysql;

import '../constants/import_tables.dart';

/// Redacts passwords and never stringifies blobs for console/UI logs.
String safeValuePreview(String columnName, Object? value) {
  if (ImportTables.isSensitiveColumn(columnName)) {
    return '<redacted>';
  }
  if (value == null) return 'null';
  if (value is mysql.Blob) {
    return '<blob ${value.toBytes().length} bytes>';
  }
  if (value is Uint8List) return '<blob ${value.length} bytes>';
  if (value is List<int>) return '<blob ${value.length} bytes>';
  final text = value.toString();
  if (text.length > 80) return '${text.substring(0, 77)}...';
  return text;
}

bool shouldSkipLoggingColumn(String columnName) {
  return ImportTables.isSensitiveColumn(columnName);
}
