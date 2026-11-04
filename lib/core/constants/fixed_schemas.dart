/// Fixed SQLite shapes that the importer must verify after load.
class FixedSchemas {
  FixedSchemas._();

  static const List<FixedColumn> itTkey = [
    FixedColumn(name: 'KEY_ID', type: 'INTEGER'),
    FixedColumn(name: 'Key_Name', type: 'TEXT'),
    FixedColumn(name: 'Key_Code', type: 'TEXT'),
    FixedColumn(name: 'Key_Item_ID', type: 'TEXT'),
  ];

  static const List<FixedColumn> itTstorelist = [
    FixedColumn(name: 'StoreID', type: 'INTEGER'),
    FixedColumn(name: 'StoreName', type: 'TEXT'),
    FixedColumn(name: 'StoreAddr', type: 'TEXT'),
    FixedColumn(name: 'SQLHost', type: 'TEXT'),
    FixedColumn(name: 'SQLPort', type: 'TEXT'),
    FixedColumn(name: 'SQLUser', type: 'TEXT'),
    FixedColumn(name: 'SQLPass', type: 'TEXT'),
    FixedColumn(name: 'SQLDB', type: 'TEXT'),
    FixedColumn(name: 'StoreSyncStage', type: 'INTEGER'),
    FixedColumn(name: 'web_store', type: 'INTEGER'),
    FixedColumn(name: 'Company_Logo_Path', type: 'TEXT'),
    FixedColumn(name: 'bussines_id', type: 'TEXT'),
    FixedColumn(name: 'location_id', type: 'TEXT'),
    FixedColumn(name: 'Company_Logo', type: 'BLOB'),
  ];
}

class FixedColumn {
  const FixedColumn({required this.name, required this.type});

  final String name;
  final String type;
}
