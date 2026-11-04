import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../../core/constants/fixed_schemas.dart';
import '../../core/constants/import_tables.dart';
import '../../core/error/exceptions.dart';
import '../../core/utils/path_helpers.dart';
import '../../core/utils/safe_log.dart';
import '../../core/utils/value_converter.dart';

class SqliteColumnInfo {
  SqliteColumnInfo({
    required this.name,
    required this.type,
    required this.pk,
    this.notNull = false,
  });

  final String name;
  final String type;
  final int pk;
  final bool notNull;
}

class SqliteDestinationDatasource {
  SqliteDestinationDatasource({ValueConverter? valueConverter})
    : _converter = valueConverter ?? const ValueConverter();

  final ValueConverter _converter;
  Database? _db;
  String? _workingPath;

  String get workingPath => _workingPath ?? '';

  /// User tables eligible for import (excludes sqlite_* and SQLite-only seed tables).
  List<String> listImportableTables() {
    _ensureOpen();
    final rows = _db!.select("""
      SELECT name FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name COLLATE NOCASE
      """);
    return rows
        .map((r) => r['name'] as String)
        .where((name) => !ImportTables.isSqliteOnly(name))
        .toList();
  }

  Future<void> openWorkingCopy({
    required String seedTemplatePath,
    required String workingDbPath,
  }) async {
    final seed = File(seedTemplatePath);
    if (!await seed.exists()) {
      throw DestinationDbException(
        'Seed template not found: $seedTemplatePath',
      );
    }
    await ensureParentDir(workingDbPath);
    if (await File(workingDbPath).exists()) {
      await File(workingDbPath).delete();
    }
    await seed.copy(workingDbPath);
    _workingPath = workingDbPath;
    _db = sqlite3.open(workingDbPath);
    _db!.execute('PRAGMA foreign_keys = OFF');
    _db!.execute('PRAGMA journal_mode = WAL');
  }

  List<SqliteColumnInfo> tableInfo(String tableName) {
    _ensureOpen();
    final rows = _db!.select('PRAGMA table_info("$tableName")');
    return rows
        .map(
          (r) => SqliteColumnInfo(
            name: r['name'] as String,
            type: (r['type'] as String?) ?? '',
            pk: r['pk'] as int? ?? 0,
            notNull: (r['notnull'] as int? ?? 0) != 0,
          ),
        )
        .toList();
  }

  bool tableExists(String tableName) {
    _ensureOpen();
    final rows = _db!.select(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name=? COLLATE NOCASE LIMIT 1",
      [tableName],
    );
    return rows.isNotEmpty;
  }

  String? resolveTableName(String logicalName) {
    _ensureOpen();
    final rows = _db!.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=? COLLATE NOCASE LIMIT 1",
      [logicalName],
    );
    if (rows.isEmpty) return null;
    return rows.first['name'] as String;
  }

  int countRows(String tableName) {
    _ensureOpen();
    final rows = _db!.select('SELECT COUNT(*) AS c FROM "$tableName"');
    return rows.first['c'] as int;
  }

  void clearTable(String tableName) {
    _ensureOpen();
    _db!.execute('DELETE FROM "$tableName"');
  }

  /// Inserts rows using case-insensitive column intersection.
  /// Returns ignored MariaDB column names.
  ///
  /// Throws [DestinationDbException] if a non-null source value converts to
  /// null, or a NOT NULL SQLite column would receive null.
  List<String> replaceTable({
    required String tableName,
    required List<String> sourceColumns,
    required List<List<Object?>> rows,
  }) {
    _ensureOpen();
    final sqliteCols = tableInfo(tableName);
    if (sqliteCols.isEmpty) {
      throw DestinationDbException('SQLite table "$tableName" has no columns.');
    }

    final sqliteByLower = <String, String>{
      for (final c in sqliteCols) c.name.toLowerCase(): c.name,
    };
    final matched = <String>[];
    final ignored = <String>[];
    for (final src in sourceColumns) {
      final dest = sqliteByLower[src.toLowerCase()];
      if (dest == null) {
        ignored.add(src);
      } else {
        matched.add(dest);
      }
    }
    if (matched.isEmpty) {
      throw DestinationDbException(
        'No overlapping columns between MariaDB and SQLite for "$tableName".',
      );
    }

    final srcIndexByLower = <String, int>{
      for (var i = 0; i < sourceColumns.length; i++)
        sourceColumns[i].toLowerCase(): i,
    };
    final typeByLower = <String, String>{
      for (final c in sqliteCols) c.name.toLowerCase(): c.type,
    };
    final notNullByLower = <String, bool>{
      for (final c in sqliteCols) c.name.toLowerCase(): c.notNull || c.pk > 0,
    };

    // Convert first so null-loss fails before clearing the destination table.
    final prepared = <List<Object?>>[];
    final nullProblems = <String>[];
    const maxProblems = 25;

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final values = <Object?>[];
      for (final col in matched) {
        final key = col.toLowerCase();
        final idx = srcIndexByLower[key]!;
        final raw = row[idx];
        final destType = typeByLower[key] ?? 'TEXT';
        final converted = _converter.convert(raw, destType);
        if (converted == null &&
            raw != null &&
            !_isBlankSourceValue(raw)) {
          if (nullProblems.length < maxProblems) {
            nullProblems.add(
              _nullLossDetail(
                column: col,
                rowIndex: rowIndex,
                sqliteType: destType,
                mariaValue: raw,
                sqliteValue: converted,
              ),
            );
          }
        } else if (converted == null && (notNullByLower[key] ?? false)) {
          if (nullProblems.length < maxProblems) {
            nullProblems.add(
              _nullLossDetail(
                column: col,
                rowIndex: rowIndex,
                sqliteType: destType,
                mariaValue: raw,
                sqliteValue: converted,
                notNullViolation: true,
              ),
            );
          }
        }
        values.add(converted);
      }
      prepared.add(values);
    }

    if (nullProblems.isNotEmpty) {
      final more = nullProblems.length >= maxProblems
          ? ' (showing first $maxProblems)'
          : '';
      throw DestinationDbException(
        'Null data loss in "$tableName"$more — '
        'MariaDB value could not be inserted into SQLite: '
        '${nullProblems.join('; ')}',
      );
    }

    clearTable(tableName);

    final placeholders = List.filled(matched.length, '?').join(',');
    final colList = matched.map((c) => '"$c"').join(',');
    final sql = 'INSERT INTO "$tableName" ($colList) VALUES ($placeholders)';
    final stmt = _db!.prepare(sql);
    try {
      for (final values in prepared) {
        stmt.execute(values);
      }
    } finally {
      stmt.close();
    }

    _updateSqliteSequence(tableName, sqliteCols);
    return ignored;
  }

  String _nullLossDetail({
    required String column,
    required int rowIndex,
    required String sqliteType,
    required Object? mariaValue,
    required Object? sqliteValue,
    bool notNullViolation = false,
  }) {
    final mariaPreview = safeValuePreview(column, mariaValue);
    final mariaType = mariaValue?.runtimeType ?? 'null';
    final sqlitePreview = safeValuePreview(column, sqliteValue);
    final reason = notNullViolation ? 'NOT NULL/PK' : 'convert→null';
    return '$column row $rowIndex [$reason] '
        'MariaDB($mariaType)=$mariaPreview → '
        'SQLite($sqliteType)=$sqlitePreview';
  }

  /// True when MariaDB sent a non-SQL-null placeholder ("" / "null") that may
  /// legitimately become null or a numeric default.
  bool _isBlankSourceValue(Object raw) {
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return true;
      final lower = t.toLowerCase();
      return lower == 'null' ||
          lower == 'nil' ||
          lower == 'none' ||
          lower == '-' ||
          lower == 'n/a' ||
          lower == 'na';
    }
    if (raw is List<int> && raw.isEmpty) return true;
    return false;
  }

  void _updateSqliteSequence(String tableName, List<SqliteColumnInfo> columns) {
    final pkCols = columns.where((c) => c.pk > 0).toList()
      ..sort((a, b) => a.pk.compareTo(b.pk));
    if (pkCols.length != 1) return;
    final pk = pkCols.first;
    if (!pk.type.toUpperCase().contains('INT')) return;

    final maxRows = _db!.select(
      'SELECT MAX("${pk.name}") AS m FROM "$tableName"',
    );
    final maxVal = maxRows.first['m'];
    if (maxVal == null) return;
    final maxInt = maxVal is int ? maxVal : int.tryParse('$maxVal');
    if (maxInt == null) return;

    _db!.execute('DELETE FROM sqlite_sequence WHERE name = ?', [tableName]);
    _db!.execute('INSERT INTO sqlite_sequence(name, seq) VALUES (?, ?)', [
      tableName,
      maxInt,
    ]);
  }

  void verifyFixedSchemas() {
    _ensureOpen();
    _assertSchema('it_tkey', FixedSchemas.itTkey);
    _assertSchema('it_tstorelist', FixedSchemas.itTstorelist);
  }

  void _assertSchema(String table, List<FixedColumn> expected) {
    final actual = tableInfo(table);
    if (actual.length != expected.length) {
      throw SchemaException(
        '$table schema mismatch: expected ${expected.length} columns, '
        'found ${actual.length}.',
      );
    }
    for (var i = 0; i < expected.length; i++) {
      final a = actual[i];
      final e = expected[i];
      if (a.name.toLowerCase() != e.name.toLowerCase()) {
        throw SchemaException(
          '$table column order/name mismatch at index $i: '
          'expected ${e.name}, found ${a.name}.',
        );
      }
      final aType = a.type.toUpperCase();
      final eType = e.type.toUpperCase();
      if (!_typesCompatible(aType, eType)) {
        throw SchemaException(
          '$table column ${e.name} type mismatch: expected $eType, found $aType.',
        );
      }
    }
    if (table.toLowerCase() == 'it_tstorelist') {
      final last = actual.last.name.toLowerCase();
      if (last != 'company_logo') {
        throw SchemaException(
          'it_tstorelist must end with Company_Logo, found ${actual.last.name}.',
        );
      }
    }
  }

  bool _typesCompatible(String actual, String expected) {
    if (actual == expected) return true;
    if (expected == 'INTEGER' &&
        (actual.contains('INT') || actual == 'NUMERIC')) {
      return true;
    }
    if (expected == 'TEXT' &&
        (actual.contains('CHAR') ||
            actual.contains('CLOB') ||
            actual == 'TEXT' ||
            actual.isEmpty)) {
      return true;
    }
    if (expected == 'BLOB' && (actual.contains('BLOB') || actual.isEmpty)) {
      return true;
    }
    if (expected == 'REAL' &&
        (actual.contains('REAL') ||
            actual.contains('FLOA') ||
            actual.contains('DOUB'))) {
      return true;
    }
    return false;
  }

  int countEzwayOrders() {
    _ensureOpen();
    final rows = _db!.select(
      'SELECT COUNT(*) AS c FROM it_tcuenta WHERE EZway_order IS NOT NULL AND EZway_order != 0',
    );
    return rows.first['c'] as int;
  }

  int countWebStores() {
    _ensureOpen();
    final rows = _db!.select(
      'SELECT COUNT(*) AS c FROM it_tstorelist WHERE web_store IS NOT NULL AND web_store != 0',
    );
    return rows.first['c'] as int;
  }

  Future<void> publishAtomically(String destinationPath) async {
    _ensureOpen();
    _db!.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    _db!.close();
    _db = null;

    final working = _workingPath!;
    await ensureParentDir(destinationPath);
    final dest = File(destinationPath);
    final backupPath = '$destinationPath.bak_import';
    if (await dest.exists()) {
      final bak = File(backupPath);
      if (await bak.exists()) await bak.delete();
      await dest.rename(backupPath);
    }
    try {
      await File(working).copy(destinationPath);
      // Clean sidecars if any
      for (final side in ['-wal', '-shm']) {
        final f = File('$working$side');
        if (await f.exists()) await f.delete();
      }
      if (await File(backupPath).exists()) {
        await File(backupPath).delete();
      }
    } catch (e) {
      if (await File(backupPath).exists() && !await dest.exists()) {
        await File(backupPath).rename(destinationPath);
      }
      throw DestinationDbException('Failed to publish destination DB: $e');
    }
  }

  Future<void> discardWorkingCopy() async {
    if (_db != null) {
      _db!.close();
      _db = null;
    }
    final working = _workingPath;
    _workingPath = null;
    if (working != null) {
      for (final path in [working, '$working-wal', '$working-shm']) {
        final f = File(path);
        if (await f.exists()) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
    }
  }

  void _ensureOpen() {
    if (_db == null) {
      throw DestinationDbException('Working SQLite database is not open.');
    }
  }
}
