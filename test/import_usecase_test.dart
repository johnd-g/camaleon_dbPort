import 'package:camaleon_db_port/core/error/failures.dart';
import 'package:camaleon_db_port/domain/entities/import_request.dart';
import 'package:camaleon_db_port/domain/repositories/database_import_repository.dart';
import 'package:camaleon_db_port/domain/usecases/import_camaleon_database.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements DatabaseImportRepository {
  @override
  Stream<Either<Failure, Object>> importDatabase(ImportRequest request) {
    return Stream.value(const Right('ok'));
  }
}

void main() {
  test('rejects empty source folder', () async {
    final useCase = ImportCamaleonDatabase(_FakeRepo());
    final event = await useCase(
      const ImportRequest(
        sourceFolderPath: '',
        outputFolderPath: r'C:\out',
      ),
    ).first;
    expect(event.isLeft(), isTrue);
    event.fold(
      (f) => expect(f, isA<ValidationFailure>()),
      (_) => fail('expected validation failure'),
    );
  });

  test('rejects empty output folder', () async {
    final useCase = ImportCamaleonDatabase(_FakeRepo());
    final event = await useCase(
      const ImportRequest(
        sourceFolderPath: r'C:\db',
        outputFolderPath: '',
      ),
    ).first;
    expect(event.isLeft(), isTrue);
  });

  test('forwards valid request to repository', () async {
    final useCase = ImportCamaleonDatabase(_FakeRepo());
    final event = await useCase(
      const ImportRequest(
        sourceFolderPath: r'C:\db\demoperu2sami',
        outputFolderPath: r'C:\out',
      ),
    ).first;
    expect(event, const Right('ok'));
  });
}
