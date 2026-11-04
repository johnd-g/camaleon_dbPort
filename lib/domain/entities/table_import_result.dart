import 'package:equatable/equatable.dart';

enum TableImportStatus { imported, missingInSource, skippedError }

class TableImportResult extends Equatable {
  const TableImportResult({
    required this.tableName,
    required this.status,
    required this.rowsRead,
    required this.rowsWritten,
    required this.ignoredSourceColumns,
    this.warning,
    this.errorMessage,
  });

  final String tableName;
  final TableImportStatus status;
  final int rowsRead;
  final int rowsWritten;
  final List<String> ignoredSourceColumns;
  final String? warning;
  final String? errorMessage;

  @override
  List<Object?> get props => [
    tableName,
    status,
    rowsRead,
    rowsWritten,
    ignoredSourceColumns,
    warning,
    errorMessage,
  ];
}
