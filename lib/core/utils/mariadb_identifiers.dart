/// Builds a MariaDB schema name safe for datadir folders and `USE`.
///
/// Folder names like `demoperu-sami` are fine on disk for Camaleon, but the
/// temporary MariaDB often rejects or fails to open them via the client
/// (Error 1049). Hyphens and other punctuation become `_`.
String sanitizeMariaDbSchemaName(String folderOrDbName) {
  var name = folderOrDbName.trim();
  if (name.isEmpty) return 'camaleon_import';

  name = name.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  name = name.replaceAll(RegExp(r'_+'), '_');
  name = name.replaceAll(RegExp(r'^_+|_+$'), '');
  if (name.isEmpty) return 'camaleon_import';

  // Identifiers should not start with a digit.
  if (RegExp(r'^[0-9]').hasMatch(name)) {
    name = 'db_$name';
  }
  return name;
}

String quoteMariaDbIdentifier(String name) => '`${name.replaceAll('`', '``')}`';
