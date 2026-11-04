import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/import_progress.dart';
import '../../domain/entities/import_report.dart';
import '../../domain/entities/import_request.dart';
import '../../domain/repositories/database_import_repository.dart';
import '../../domain/usecases/import_camaleon_database.dart';

part 'import_state.dart';

class ImportCubit extends Cubit<ImportState> {
  ImportCubit(this._importDatabase) : super(const ImportState());

  final ImportCamaleonDatabase _importDatabase;
  StreamSubscription<dynamic>? _sub;

  void setSourceFolder(String path) {
    emit(
      state.copyWith(sourceFolder: path, clearError: true, clearReport: true),
    );
  }

  void setOutputFolder(String path) {
    emit(
      state.copyWith(outputFolder: path, clearError: true, clearReport: true),
    );
  }

  void setMariaDbBinDir(String? path) {
    emit(state.copyWith(mariaDbBinDir: path ?? '', clearError: true));
  }

  void setLocaleCode(String code) {
    emit(state.copyWith(localeCode: code));
  }

  Future<void> startImport() async {
    if (state.isRunning) return;
    final source = state.sourceFolder.trim();
    final output = state.outputFolder.trim();
    if (source.isEmpty || output.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'missing_paths',
          phase: ImportPhase.failed,
        ),
      );
      return;
    }

    await _sub?.cancel();
    emit(
      state.copyWith(
        isRunning: true,
        clearError: true,
        clearReport: true,
        progress: const ImportProgress(
          phase: ImportPhase.validating,
          message: 'starting',
        ),
        logLines: const [],
      ),
    );

    final request = ImportRequest(
      sourceFolderPath: source,
      outputFolderPath: output,
      mariaDbBinDir: state.mariaDbBinDir.trim().isEmpty
          ? null
          : state.mariaDbBinDir.trim(),
    );

    _sub = _importDatabase(request).listen(
      (either) {
        either.fold(
          (failure) {
            emit(
              state.copyWith(
                isRunning: false,
                errorMessage: failure.message,
                phase: ImportPhase.failed,
                progress: ImportProgress(
                  phase: ImportPhase.failed,
                  message: failure.message,
                ),
              ),
            );
          },
          (value) {
            if (isImportProgress(value)) {
              final progress = value as ImportProgress;
              final logs = List<String>.from(state.logLines);
              if (progress.detail != null &&
                  progress.detail!.isNotEmpty &&
                  (logs.isEmpty || logs.last != progress.detail)) {
                logs.add(progress.detail!);
                if (logs.length > 400) {
                  logs.removeRange(0, logs.length - 400);
                }
              }
              emit(
                state.copyWith(
                  progress: progress,
                  phase: progress.phase,
                  logLines: logs,
                ),
              );
            } else if (isImportReport(value)) {
              final report = value as ImportReport;
              emit(
                state.copyWith(
                  isRunning: false,
                  report: report,
                  phase: ImportPhase.done,
                  progress: const ImportProgress(
                    phase: ImportPhase.done,
                    message: 'done',
                  ),
                  logLines: report.logLines,
                ),
              );
            }
          },
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            isRunning: false,
            errorMessage: e.toString(),
            phase: ImportPhase.failed,
          ),
        );
      },
      onDone: () {
        if (state.isRunning) {
          emit(state.copyWith(isRunning: false));
        }
      },
    );
  }

  void clearResult() {
    emit(
      state.copyWith(
        clearError: true,
        clearReport: true,
        clearProgress: true,
        phase: ImportPhase.idle,
        logLines: const [],
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
