import 'package:mysql1/mysql1.dart';

class MariaDbTableSnapshot {
  MariaDbTableSnapshot({
    required this.resolvedName,
    required this.columns,
    required this.rows,
  });

  final String resolvedName;
  final List<String> columns;
  final List<List<Object?>> rows;

  int get rowCount => rows.length;
}

class MariaDbTableReader {
  MariaDbTableReader(this._conn);

  final MySqlConnection _conn;

  Future<List<String>> listTables() async {
    final result = await _conn.query('''
      SELECT TABLE_NAME
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_TYPE = 'BASE TABLE'
      ORDER BY TABLE_NAME
      ''');
    return result.map((r) => r[0] as String).toList();
  }

  Future<String?> resolveTableName(String logicalName) async {
    final result = await _conn.query(
      '''
      SELECT TABLE_NAME
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
        AND LOWER(TABLE_NAME) = LOWER(?)
      LIMIT 1
      ''',
      [logicalName],
    );
    if (result.isEmpty) return null;
    return result.first[0] as String;
  }

  Future<MariaDbTableSnapshot?> readTable(String logicalName) async {
    final resolved = await resolveTableName(logicalName);
    if (resolved == null) return null;

    final desc = await _conn.query('SHOW COLUMNS FROM `$resolved`');
    final columns = desc.map((r) => r[0] as String).toList();
    if (columns.isEmpty) {
      return MariaDbTableSnapshot(
        resolvedName: resolved,
        columns: const [],
        rows: const [],
      );
    }

    final data = await _conn.query('SELECT * FROM `$resolved`');
    final rows = <List<Object?>>[];
    for (final row in data) {
      rows.add(List<Object?>.generate(columns.length, (i) => row[i]));
    }
    return MariaDbTableSnapshot(
      resolvedName: resolved,
      columns: columns,
      rows: rows,
    );
  }
}
