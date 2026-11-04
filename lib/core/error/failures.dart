import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class SourceFailure extends Failure {
  const SourceFailure(super.message);
}

class MariaDbFailure extends Failure {
  const MariaDbFailure(super.message);
}

class SqliteFailure extends Failure {
  const SqliteFailure(super.message);
}

class SchemaFailure extends Failure {
  const SchemaFailure(super.message);
}

class ImportFailure extends Failure {
  const ImportFailure(super.message);
}
