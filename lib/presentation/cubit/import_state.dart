part of 'import_cubit.dart';

class ImportState extends Equatable {
  const ImportState({
    this.sourceFolder = '',
    this.workspaceRoot = '',
    this.mariaDbBinDir = '',
    this.localeCode = 'en',
    this.isRunning = false,
    this.phase = ImportPhase.idle,
    this.progress,
    this.report,
    this.errorMessage,
    this.logLines = const [],
  });

  final String sourceFolder;
  final String workspaceRoot;
  final String mariaDbBinDir;
  final String localeCode;
  final bool isRunning;
  final ImportPhase phase;
  final ImportProgress? progress;
  final ImportReport? report;
  final String? errorMessage;
  final List<String> logLines;

  bool get hasSuccess => report?.succeeded == true;
  bool get hasFailure => errorMessage != null && errorMessage!.isNotEmpty;

  ImportState copyWith({
    String? sourceFolder,
    String? workspaceRoot,
    String? mariaDbBinDir,
    String? localeCode,
    bool? isRunning,
    ImportPhase? phase,
    ImportProgress? progress,
    ImportReport? report,
    String? errorMessage,
    List<String>? logLines,
    bool clearError = false,
    bool clearReport = false,
    bool clearProgress = false,
  }) {
    return ImportState(
      sourceFolder: sourceFolder ?? this.sourceFolder,
      workspaceRoot: workspaceRoot ?? this.workspaceRoot,
      mariaDbBinDir: mariaDbBinDir ?? this.mariaDbBinDir,
      localeCode: localeCode ?? this.localeCode,
      isRunning: isRunning ?? this.isRunning,
      phase: phase ?? this.phase,
      progress: clearProgress ? null : (progress ?? this.progress),
      report: clearReport ? null : (report ?? this.report),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      logLines: logLines ?? this.logLines,
    );
  }

  @override
  List<Object?> get props => [
    sourceFolder,
    workspaceRoot,
    mariaDbBinDir,
    localeCode,
    isRunning,
    phase,
    progress,
    report,
    errorMessage,
    logLines,
  ];
}
