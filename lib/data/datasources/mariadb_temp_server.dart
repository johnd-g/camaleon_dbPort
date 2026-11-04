import 'dart:async';
import 'dart:io';

import 'package:mysql1/mysql1.dart';
import 'package:path/path.dart' as p;

import '../../core/error/exceptions.dart';
import '../../core/utils/path_helpers.dart';
import 'mariadb_locator.dart';

class MariaDbTempServer {
  MariaDbTempServer(this._locator);

  final MariaDbLocator _locator;

  Directory? _workRoot;
  Directory? _dataDir;
  Process? _process;
  int? _port;
  String? _databaseName;

  int get port => _port ?? 0;
  String get databaseName => _databaseName ?? '';

  Future<void> start({
    required String sourceFolderPath,
    String? mariaDbBinDir,
    void Function(String line)? onLog,
  }) async {
    final binaries = await _locator.locate(overrideBinDir: mariaDbBinDir);
    if (binaries == null) {
      throw MariaDbException(
        'MariaDB/MySQL binaries not found. Install MariaDB or set the bin folder.',
      );
    }
    final dbName = basenamePath(sourceFolderPath);
    _databaseName = dbName;

    final tempRoot = await Directory.systemTemp.createTemp('camaleon_import_');
    _workRoot = tempRoot;
    final sourceCopy = Directory(p.join(tempRoot.path, 'source_copy'));
    await copyDirectory(Directory(sourceFolderPath), sourceCopy);

    _dataDir = Directory(p.join(tempRoot.path, 'datadir'));
    await _dataDir!.create(recursive: true);

    onLog?.call('Initializing temporary MariaDB datadir…');
    await _installDatadir(binaries, _dataDir!.path, onLog: onLog);

    final dbDir = Directory(p.join(_dataDir!.path, dbName));
    await dbDir.create(recursive: true);
    await _copyMyisamFiles(sourceCopy, dbDir);

    _port = await findFreePort();
    onLog?.call('Starting mariadbd on 127.0.0.1:$_port…');
    await _startServer(binaries, _dataDir!.path, _port!, onLog: onLog);
    await _waitUntilReady(binaries, _port!, onLog: onLog);
  }

  Future<MySqlConnection> connect() async {
    if (_port == null || _databaseName == null) {
      throw MariaDbException('MariaDB temporary server is not running.');
    }
    final conn = await MySqlConnection.connect(
      ConnectionSettings(
        host: '127.0.0.1',
        port: _port!,
        user: 'root',
        password: '',
        db: _databaseName,
        timeout: const Duration(seconds: 30),
      ),
    );
    await conn.query('SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci');
    await conn.query('SET character_set_results = utf8mb4');
    return conn;
  }

  Future<void> stop({void Function(String line)? onLog}) async {
    final process = _process;
    _process = null;
    if (process != null) {
      onLog?.call('Stopping temporary MariaDB…');
      try {
        if (Platform.isWindows) {
          process.kill(ProcessSignal.sigterm);
        } else {
          process.kill(ProcessSignal.sigterm);
        }
        await process.exitCode.timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            process.kill(ProcessSignal.sigkill);
            return -1;
          },
        );
      } catch (_) {
        try {
          process.kill(ProcessSignal.sigkill);
        } catch (_) {}
      }
    }

    final root = _workRoot;
    _workRoot = null;
    _dataDir = null;
    if (root != null && await root.exists()) {
      onLog?.call('Removing temporary datadir…');
      try {
        await root.delete(recursive: true);
      } catch (e) {
        onLog?.call('Warning: could not delete temp folder: $e');
      }
    }
  }

  Future<void> _installDatadir(
    MariaDbBinaries binaries,
    String dataDir, {
    void Function(String line)? onLog,
  }) async {
    final args = <String>['--datadir=$dataDir'];
    final installName = p.basename(binaries.installDbExe).toLowerCase();
    // MariaDB 10.3 Windows mysql_install_db rejects --basedir.
    if (!installName.contains('mysql_install_db')) {
      args.addAll([
        '--basedir=${p.dirname(binaries.binDir)}',
        '--auth-root-authentication-method=normal',
      ]);
    }

    final result = await Process.run(
      binaries.installDbExe,
      args,
      workingDirectory: binaries.binDir,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      final err = '${result.stdout}\n${result.stderr}'.trim();
      throw MariaDbException(
        'mariadb-install-db failed (code ${result.exitCode}): $err',
      );
    }
    onLog?.call('Temporary datadir ready.');
  }

  Future<void> _copyMyisamFiles(Directory source, Directory dbDir) async {
    var copied = 0;
    await for (final entity in source.list(recursive: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      final lower = name.toLowerCase();
      if (lower.endsWith('.frm') ||
          lower.endsWith('.myd') ||
          lower.endsWith('.myi') ||
          lower == 'db.opt') {
        await entity.copy(p.join(dbDir.path, name));
        copied++;
      }
    }
    if (copied == 0) {
      throw SourceException(
        'No MyISAM table files (.frm/.MYD/.MYI) found in source folder.',
      );
    }
  }

  Future<void> _startServer(
    MariaDbBinaries binaries,
    String dataDir,
    int port, {
    void Function(String line)? onLog,
  }) async {
    final errLog = p.join(_workRoot!.path, 'mysqld_err.log');
    final args = <String>[
      '--datadir=$dataDir',
      '--port=$port',
      '--bind-address=127.0.0.1',
      '--skip-networking=0',
      '--skip-grant-tables',
      '--skip-name-resolve',
      '--console',
      '--log-error=$errLog',
      '--innodb-buffer-pool-size=32M',
      '--key-buffer-size=32M',
      '--max-connections=20',
    ];
    if (Platform.isWindows) {
      args.add('--basedir=${p.dirname(binaries.binDir)}');
    }

    _process = await Process.start(
      binaries.serverExe,
      args,
      workingDirectory: binaries.binDir,
      runInShell: false,
    );

    _process!.stdout.transform(const SystemEncoding().decoder).listen((line) {
      onLog?.call(line.trimRight());
    });
    _process!.stderr.transform(const SystemEncoding().decoder).listen((line) {
      onLog?.call(line.trimRight());
    });

    // Fail fast if process exits immediately.
    unawaited(
      _process!.exitCode.then((code) {
        if (_process != null) {
          onLog?.call('mariadbd exited early with code $code');
        }
      }),
    );
  }

  Future<void> _waitUntilReady(
    MariaDbBinaries binaries,
    int port, {
    void Function(String line)? onLog,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 45));
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      if (_process == null) {
        throw MariaDbException('mariadbd process is not running.');
      }
      try {
        final conn = await MySqlConnection.connect(
          ConnectionSettings(
            host: '127.0.0.1',
            port: port,
            user: 'root',
            password: '',
            timeout: const Duration(seconds: 2),
          ),
        );
        await conn.query('SELECT 1');
        await conn.close();
        onLog?.call('MariaDB is ready.');
        return;
      } catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    throw MariaDbException(
      'Timed out waiting for temporary MariaDB. Last error: $lastError',
    );
  }
}
