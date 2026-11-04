import 'package:equatable/equatable.dart';

import 'table_import_result.dart';

class ImportReport extends Equatable {
  const ImportReport({
    required this.databaseName,
    required this.destinationPath,
    required this.tableResults,
    required this.ezwayOrderCount,
    required this.webStoreCount,
    required this.logLines,
    required this.succeeded,
  });

  final String databaseName;
  final String destinationPath;
  final List<TableImportResult> tableResults;
  final int ezwayOrderCount;
  final int webStoreCount;
  final List<String> logLines;
  final bool succeeded;

  int get importedCount =>
      tableResults.where((t) => t.status == TableImportStatus.imported).length;

  int get missingCount => tableResults
      .where((t) => t.status == TableImportStatus.missingInSource)
      .length;

  @override
  List<Object?> get props => [
    databaseName,
    destinationPath,
    tableResults,
    ezwayOrderCount,
    webStoreCount,
    logLines,
    succeeded,
  ];
}
