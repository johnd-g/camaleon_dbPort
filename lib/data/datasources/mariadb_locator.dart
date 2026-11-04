import 'dart:io';

import 'package:path/path.dart' as p;

class MariaDbBinaries {
  const MariaDbBinaries({
    required this.binDir,
    required this.serverExe,
    required this.installDbExe,
    required this.clientExe,
  });

  final String binDir;
  final String serverExe;
  final String installDbExe;
  final String clientExe;
}

class MariaDbLocator {
  /// Resolves MariaDB/MySQL binaries from an optional override or known paths.
  Future<MariaDbBinaries?> locate({String? overrideBinDir}) async {
    final candidates = <String>[
      if (overrideBinDir != null && overrideBinDir.trim().isNotEmpty)
        overrideBinDir.trim(),
      if (Platform.environment['MARIADB_HOME'] != null)
        p.join(Platform.environment['MARIADB_HOME']!, 'bin'),
      if (Platform.environment['MYSQL_HOME'] != null)
        p.join(Platform.environment['MYSQL_HOME']!, 'bin'),
      r'C:\Program Files (x86)\MariaDB 10.3\bin',
      r'C:\Program Files\MariaDB 10.3\bin',
      r'C:\Program Files\MariaDB 10.11\bin',
      r'C:\Program Files\MariaDB 11.4\bin',
      r'C:\xampp\mysql\bin',
      '/usr/local/mysql/bin',
      '/usr/bin',
      '/opt/homebrew/bin',
      '/usr/local/bin',
    ];

    for (final dir in candidates) {
      final found = _fromBinDir(dir);
      if (found != null) return found;
    }
    return null;
  }

  MariaDbBinaries? _fromBinDir(String binDir) {
    final server = _firstExisting(binDir, const [
      'mariadbd.exe',
      'mysqld.exe',
      'mariadbd',
      'mysqld',
    ]);
    final install = _firstExisting(binDir, const [
      'mariadb-install-db.exe',
      'mysql_install_db.exe',
      'mariadb-install-db',
      'mysql_install_db',
    ]);
    final client = _firstExisting(binDir, const [
      'mariadb.exe',
      'mysql.exe',
      'mariadb',
      'mysql',
    ]);
    if (server == null || install == null) return null;
    return MariaDbBinaries(
      binDir: binDir,
      serverExe: server,
      installDbExe: install,
      clientExe: client ?? server,
    );
  }

  String? _firstExisting(String binDir, List<String> names) {
    for (final name in names) {
      final path = p.join(binDir, name);
      if (File(path).existsSync()) return path;
    }
    return null;
  }
}
