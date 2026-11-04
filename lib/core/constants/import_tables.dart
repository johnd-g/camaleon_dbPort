/// Shared import policy for Camaleon MyISAM → SQLite.
class ImportTables {
  ImportTables._();

  /// Present only in the seed SQLite. Never cleared or rewritten.
  static const Set<String> sqliteOnlyTables = {
    'country_city',
    'email_sends',
    'grouping_sta_rel',
    'it_tbillboard',
    'kdsconfig',
    'new_dev_found',
    'p_order',
    'p_order_items',
    'type_place',
    'wilcu_give_away',
  };

  static const Set<String> sensitiveColumnHints = {
    'sqlpass',
    'user_pass',
    'password',
    'passwd',
    'pass',
  };

  static bool isSqliteOnly(String tableName) =>
      sqliteOnlyTables.contains(tableName.toLowerCase());

  static bool isSensitiveColumn(String name) {
    final lower = name.toLowerCase();
    return sensitiveColumnHints.any((h) => lower.contains(h));
  }
}
