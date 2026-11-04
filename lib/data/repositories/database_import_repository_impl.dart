import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/import_tables.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/import_progress.dart';
import '../../domain/entities/import_report.dart';
import '../../domain/entities/import_request.dart';
import '../../domain/entities/table_import_result.dart';
import '../../domain/repositories/database_import_repository.dart';
import '../datasources/mariadb_table_reader.dart';
import '../datasources/mariadb_temp_server.dart';
import '../datasources/sqlite_destination_datasource.dart';

class DatabaseImportRepositoryImpl implements DatabaseImportRepository {
  DatabaseImportRepositoryImpl({
    required MariaDbTempServer mariaDbTempServer,
    required SqliteDestinationDatasource sqliteDestination,
  }) : _maria = mariaDbTempServer,
       _sqlite = sqliteDestination;

  final MariaDbTempServer _maria;
  final SqliteDestinationDatasource _sqlite;

  @override
  Stream<Either<Failure, Object>> importDatabase(ImportRequest request) {
    late final StreamController<Either<Failure, Object>> controller;
    controller = StreamController<Either<Failure, Object>>(
      onListen: () async {
        final logs = <String>[];
        var currentPhase = ImportPhase.validating;

        void emitProgress({
          required ImportPhase phase,
          required String message,
          String? currentTable,
          int? completedTables,
          int? totalTables,
          String? detail,
          bool appendLog = false,
        }) {
          currentPhase = phase;
          if (appendLog && detail != null && detail.trim().isNotEmpty) {
            logs.add(detail);
          }
          if (!controller.isClosed) {
            controller.add(
              Right(
                ImportProgress(
                  phase: phase,
                  message: message,
                  currentTable: currentTable,
                  completedTables: completedTables ?? 0,
                  totalTables: totalTables ?? 0,
                  detail: detail,
                ),
              ),
            );
          }
        }

        void log(String line, {ImportPhase? phase}) {
          emitProgress(
            phase: phase ?? currentPhase,
            message: line,
            detail: line,
            appendLog: true,
          );
        }

        try {
          await _runImport(
            request: request,
            logs: logs,
            emitProgress: emitProgress,
            log: log,
            controller: controller,
          );
        } catch (e, st) {
          final message = e is AppException ? e.message : e.toString();
          logs.add('ERROR: $message');
          logs.add('$st');
          emitProgress(
            phase: ImportPhase.failed,
            message: message,
            detail: message,
            appendLog: false,
          );
          if (!controller.isClosed) {
            controller.add(Left(_mapFailure(e)));
          }
        } finally {
          await _maria.stop(
            onLog: (line) {
              if (line.trim().isNotEmpty) logs.add(line);
            },
          );
          await _sqlite.discardWorkingCopy();
          if (!controller.isClosed) {
            await controller.close();
          }
        }
      },
    );
    return controller.stream;
  }

  Future<void> _runImport({
    required ImportRequest request,
    required List<String> logs,
    required void Function({
      required ImportPhase phase,
      required String message,
      String? currentTable,
      int? completedTables,
      int? totalTables,
      String? detail,
      bool appendLog,
    })
    emitProgress,
    required void Function(String line, {ImportPhase? phase}) log,
    required StreamController<Either<Failure, Object>> controller,
  }) async {
    final sourceDir = Directory(request.sourceFolderPath);
    if (!await sourceDir.exists()) {
      throw SourceException(
        'Source folder does not exist: ${request.sourceFolderPath}',
      );
    }

    final seedPath = request.seedTemplatePath;
    if (!await File(seedPath).exists()) {
      throw DestinationDbException('Seed template missing: $seedPath');
    }

    emitProgress(
      phase: ImportPhase.validating,
      message: 'Validating source folder…',
      appendLog: true,
      detail: 'Validating source folder…',
    );
    log('Database name: ${request.databaseName}');
    log('Destination: ${request.destinationDbPath}');

    final workDb = p.join(
      Directory.systemTemp.path,
      'camaleon_seed_${request.databaseName}_${DateTime.now().millisecondsSinceEpoch}.db',
    );

    emitProgress(
      phase: ImportPhase.preparingSeed,
      message: 'Preparing SQLite working copy from seed…',
      appendLog: true,
      detail: 'Preparing SQLite working copy from seed…',
    );
    await _sqlite.openWorkingCopy(
      seedTemplatePath: seedPath,
      workingDbPath: workDb,
    );
    log('Working SQLite: $workDb', phase: ImportPhase.preparingSeed);

    emitProgress(
      phase: ImportPhase.copyingSource,
      message: 'Copying MyISAM source to temp and starting MariaDB…',
      appendLog: true,
      detail: 'Copying MyISAM source to temp and starting MariaDB…',
    );
    await _maria.start(
      sourceFolderPath: request.sourceFolderPath,
      mariaDbBinDir: request.mariaDbBinDir,
      onLog: (line) {
        if (line.trim().isEmpty || line.length > 180) return;
        logs.add(line);
      },
    );

    emitProgress(
      phase: ImportPhase.startingMariaDb,
      message: 'Connected to temporary MariaDB.',
      appendLog: true,
      detail: 'Connected to temporary MariaDB.',
    );

    final conn = await _maria.connect();
    final reader = MariaDbTableReader(conn);
    final results = <TableImportResult>[];

    final sqliteTables = _sqlite.listImportableTables();
    final mariaTables = await reader.listTables();
    final mariaByLower = <String, String>{
      for (final t in mariaTables) t.toLowerCase(): t,
    };

    final tables = <String>[];
    for (final sqliteName in sqliteTables) {
      if (mariaByLower.containsKey(sqliteName.toLowerCase())) {
        tables.add(sqliteName);
      }
    }

    final mariaOnly = mariaTables
        .where(
          (t) =>
              _sqlite.resolveTableName(t) == null &&
              !ImportTables.isSqliteOnly(t),
        )
        .toList();
    log(
      'Shared tables to copy: ${tables.length}. '
      'SQLite-only left untouched: ${ImportTables.sqliteOnlyTables.length}. '
      'MariaDB-only ignored: ${mariaOnly.length}.',
      phase: ImportPhase.importingTables,
    );
    if (mariaOnly.isNotEmpty) {
      log(
        'MariaDB-only tables (not invented in SQLite): ${mariaOnly.join(', ')}',
        phase: ImportPhase.importingTables,
      );
    }

    try {
      for (var i = 0; i < tables.length; i++) {
        final table = tables[i];
        emitProgress(
          phase: ImportPhase.importingTables,
          message: 'Importing $table…',
          currentTable: table,
          completedTables: i,
          totalTables: tables.length,
        );

        final snapshot = await reader.readTable(table);
        if (snapshot == null) {
          final msg = 'Table "$table" not found in source — skipped.';
          log(msg, phase: ImportPhase.importingTables);
          results.add(
            TableImportResult(
              tableName: table,
              status: TableImportStatus.missingInSource,
              rowsRead: 0,
              rowsWritten: 0,
              ignoredSourceColumns: const [],
              warning: msg,
            ),
          );
          continue;
        }

        final sqliteName = _sqlite.resolveTableName(table) ?? table;
        final destBefore = _sqlite.countRows(sqliteName);
        final sourceCount = snapshot.rowCount;
        log(
          '$table: source rows=$sourceCount, destination rows before=$destBefore',
          phase: ImportPhase.importingTables,
        );
        if (destBefore > 0 && sourceCount == 0) {
          log(
            'WARNING: $table source is empty but destination had $destBefore rows. Replacing with empty.',
            phase: ImportPhase.importingTables,
          );
        }

        try {
          final ignored = _sqlite.replaceTable(
            tableName: sqliteName,
            sourceColumns: snapshot.columns,
            rows: snapshot.rows,
          );
          final written = _sqlite.countRows(sqliteName);
          log(
            '$table: wrote $written rows. Ignored source columns: '
            '${ignored.isEmpty ? '(none)' : ignored.join(', ')}',
            phase: ImportPhase.importingTables,
          );
          results.add(
            TableImportResult(
              tableName: table,
              status: TableImportStatus.imported,
              rowsRead: sourceCount,
              rowsWritten: written,
              ignoredSourceColumns: ignored,
              warning: destBefore > 0 && sourceCount == 0
                  ? 'Source empty; destination cleared.'
                  : null,
            ),
          );
        } catch (e) {
          throw AppException('Failed importing "$table": $e');
        }
      }
    } finally {
      await conn.close();
    }

    emitProgress(
      phase: ImportPhase.verifying,
      message: 'Verifying fixed schemas…',
      completedTables: tables.length,
      totalTables: tables.length,
      appendLog: true,
      detail: 'Verifying fixed schemas…',
    );
    _sqlite.verifyFixedSchemas();
    log('PRAGMA table_info(it_tkey) OK (4 columns).');
    log('PRAGMA table_info(it_tstorelist) OK (14 columns, Company_Logo last).');

    final ezway = _sqlite.countEzwayOrders();
    final webStores = _sqlite.countWebStores();
    log('it_tcuenta with EZway_order != 0: $ezway');
    log('it_tstorelist with web_store = 1: $webStores');

    emitProgress(
      phase: ImportPhase.finalizing,
      message: 'Publishing destination database…',
      appendLog: true,
      detail: 'Publishing destination database…',
    );
    await _sqlite.publishAtomically(request.destinationDbPath);
    log('Published: ${request.destinationDbPath}');

    emitProgress(
      phase: ImportPhase.cleaningUp,
      message: 'Cleaning up temporary resources…',
      appendLog: true,
      detail: 'Cleaning up temporary resources…',
    );

    final report = ImportReport(
      databaseName: request.databaseName,
      destinationPath: request.destinationDbPath,
      tableResults: results,
      ezwayOrderCount: ezway,
      webStoreCount: webStores,
      logLines: List.unmodifiable(List<String>.from(logs)),
      succeeded: true,
    );

    emitProgress(
      phase: ImportPhase.done,
      message: 'Import completed successfully.',
      appendLog: true,
      detail: 'Import completed successfully.',
    );
    if (!controller.isClosed) {
      controller.add(Right(report));
    }
  }

  Failure _mapFailure(Object e) {
    if (e is Failure) return e;
    if (e is SourceException) return SourceFailure(e.message);
    if (e is MariaDbException) return MariaDbFailure(e.message);
    if (e is DestinationDbException) return SqliteFailure(e.message);
    if (e is SchemaException) return SchemaFailure(e.message);
    if (e is AppException) return ImportFailure(e.message);
    return ImportFailure(e.toString());
  }
}
