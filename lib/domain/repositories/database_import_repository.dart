import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/import_progress.dart';
import '../entities/import_report.dart';
import '../entities/import_request.dart';

abstract class DatabaseImportRepository {
  Stream<Either<Failure, Object>> importDatabase(ImportRequest request);
}

/// Progress events and the final report share one stream.
typedef ImportEvent = Either<Failure, Object>;

bool isImportProgress(Object value) => value is ImportProgress;
bool isImportReport(Object value) => value is ImportReport;
