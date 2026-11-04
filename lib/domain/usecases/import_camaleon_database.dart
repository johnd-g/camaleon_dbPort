import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../entities/import_request.dart';
import '../repositories/database_import_repository.dart';

class ImportCamaleonDatabase {
  ImportCamaleonDatabase(this._repository);

  final DatabaseImportRepository _repository;

  Stream<Either<Failure, Object>> call(ImportRequest request) {
    if (request.sourceFolderPath.trim().isEmpty) {
      return Stream.value(
        Left(ValidationFailure('Source folder is required.')),
      );
    }
    if (request.outputFolderPath.trim().isEmpty) {
      return Stream.value(
        Left(ValidationFailure('Output folder is required.')),
      );
    }
    return _repository.importDatabase(request);
  }
}
