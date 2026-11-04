import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

class ImportRequest extends Equatable {
  const ImportRequest({
    required this.sourceFolderPath,
    required this.workspaceRoot,
    this.mariaDbBinDir,
  });

  /// Folder of MyISAM tables (.frm / .MYD / .MYI). Name = database name.
  final String sourceFolderPath;

  /// Project root that contains assets/demo and assets/seed.
  final String workspaceRoot;

  /// Optional override for MariaDB/MySQL bin directory.
  final String? mariaDbBinDir;

  String get databaseName => p.basename(sourceFolderPath);

  String get destinationDbPath =>
      p.join(workspaceRoot, 'assets', 'seed', '$databaseName.db');

  String get seedTemplatePath =>
      p.join(workspaceRoot, 'assets', 'demo', 'camaleon_sqlite_database');

  @override
  List<Object?> get props => [sourceFolderPath, workspaceRoot, mariaDbBinDir];
}
