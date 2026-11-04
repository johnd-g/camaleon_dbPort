class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SourceException extends AppException {
  SourceException(super.message);
}

class MariaDbException extends AppException {
  MariaDbException(super.message);
}

class DestinationDbException extends AppException {
  DestinationDbException(super.message);
}

class SchemaException extends AppException {
  SchemaException(super.message);
}
