import 'package:equatable/equatable.dart';

enum ImportPhase {
  idle,
  validating,
  preparingSeed,
  copyingSource,
  startingMariaDb,
  importingTables,
  verifying,
  finalizing,
  cleaningUp,
  done,
  failed,
}

class ImportProgress extends Equatable {
  const ImportProgress({
    required this.phase,
    required this.message,
    this.currentTable,
    this.completedTables = 0,
    this.totalTables = 0,
    this.detail,
  });

  final ImportPhase phase;
  final String message;
  final String? currentTable;
  final int completedTables;
  final int totalTables;
  final String? detail;

  double get fraction {
    if (totalTables <= 0) return 0;
    return (completedTables / totalTables).clamp(0.0, 1.0);
  }

  ImportProgress copyWith({
    ImportPhase? phase,
    String? message,
    String? currentTable,
    int? completedTables,
    int? totalTables,
    String? detail,
  }) {
    return ImportProgress(
      phase: phase ?? this.phase,
      message: message ?? this.message,
      currentTable: currentTable ?? this.currentTable,
      completedTables: completedTables ?? this.completedTables,
      totalTables: totalTables ?? this.totalTables,
      detail: detail ?? this.detail,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    message,
    currentTable,
    completedTables,
    totalTables,
    detail,
  ];
}
