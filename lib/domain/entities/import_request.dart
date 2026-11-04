import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as p;

class ImportRequest extends Equatable {
  const ImportRequest({
    required this.sourceFolderPath,
    required this.outputFolderPath,
    this.mariaDbBinDir,
  });

  /// Folder of MyISAM tables (.frm / .MYD / .MYI). Name = database name.
  final String sourceFolderPath;

  /// Folder where `<databaseName>.db` is written.
  final String outputFolderPath;

  /// Optional override for MariaDB/MySQL bin directory.
  final String? mariaDbBinDir;

  String get databaseName => p.basename(sourceFolderPath);

  String get destinationDbPath =>
      p.join(outputFolderPath, '$databaseName.db');

  @override
  List<Object?> get props => [
        sourceFolderPath,
        outputFolderPath,
        mariaDbBinDir,
      ];
}
