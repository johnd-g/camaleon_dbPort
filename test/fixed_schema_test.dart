import 'dart:io';

import 'package:camaleon_db_port/core/constants/fixed_schemas.dart';
import 'package:camaleon_db_port/data/datasources/sqlite_destination_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'seed template matches fixed it_tkey and it_tstorelist schemas',
    () async {
      final root = Directory.current.path;
      final seed = p.join(root, 'assets', 'demo', 'camaleon_sqlite_database');
      expect(File(seed).existsSync(), isTrue);

      final work = p.join(
        Directory.systemTemp.path,
        'schema_check_${DateTime.now().millisecondsSinceEpoch}.db',
      );
      final ds = SqliteDestinationDatasource();
      await ds.openWorkingCopy(seedTemplatePath: seed, workingDbPath: work);
      try {
        ds.verifyFixedSchemas();
        expect(ds.tableInfo('it_tkey').length, FixedSchemas.itTkey.length);
        expect(
          ds.tableInfo('it_tstorelist').length,
          FixedSchemas.itTstorelist.length,
        );
        expect(
          ds.tableInfo('it_tstorelist').last.name.toLowerCase(),
          'company_logo',
        );
      } finally {
        await ds.discardWorkingCopy();
      }
    },
  );

  test('column intersection ignores MariaDB-only columns', () async {
    final root = Directory.current.path;
    final seed = p.join(root, 'assets', 'demo', 'camaleon_sqlite_database');
    final work = p.join(
      Directory.systemTemp.path,
      'intersect_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    final ds = SqliteDestinationDatasource();
    await ds.openWorkingCopy(seedTemplatePath: seed, workingDbPath: work);
    try {
      final ignored = ds.replaceTable(
        tableName: 'it_tkey',
        sourceColumns: const [
          'KEY_ID',
          'Key_Name',
          'Key_Code',
          'Key_Item_ID',
          'job_done',
          'Hr_wage',
        ],
        rows: const [
          [1, 'A', '001', '10', 1, 9.5],
        ],
      );
      expect(ignored, containsAll(['job_done', 'Hr_wage']));
      expect(ds.countRows('it_tkey'), 1);
      ds.verifyFixedSchemas();
    } finally {
      await ds.discardWorkingCopy();
    }
  });

  test('importable tables exclude sqlite-only seed tables', () async {
    final root = Directory.current.path;
    final seed = p.join(root, 'assets', 'demo', 'camaleon_sqlite_database');
    final work = p.join(
      Directory.systemTemp.path,
      'tables_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    final ds = SqliteDestinationDatasource();
    await ds.openWorkingCopy(seedTemplatePath: seed, workingDbPath: work);
    try {
      final tables = ds.listImportableTables();
      expect(tables, isNotEmpty);
      expect(
        tables.map((t) => t.toLowerCase()),
        isNot(contains('country_city')),
      );
      expect(tables.map((t) => t.toLowerCase()), isNot(contains('kdsconfig')));
      expect(tables.map((t) => t.toLowerCase()), contains('it_tcuenta'));
    } finally {
      await ds.discardWorkingCopy();
    }
  });
}
