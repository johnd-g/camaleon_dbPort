import 'package:get_it/get_it.dart';

import 'data/datasources/mariadb_locator.dart';
import 'data/datasources/mariadb_temp_server.dart';
import 'data/datasources/seed_template_provider.dart';
import 'data/datasources/sqlite_destination_datasource.dart';
import 'data/repositories/database_import_repository_impl.dart';
import 'domain/repositories/database_import_repository.dart';
import 'domain/usecases/import_camaleon_database.dart';
import 'presentation/cubit/import_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  sl
    ..registerLazySingleton(MariaDbLocator.new)
    ..registerLazySingleton(SeedTemplateProvider.new)
    ..registerFactory(() => MariaDbTempServer(sl()))
    ..registerFactory(SqliteDestinationDatasource.new)
    ..registerFactory<DatabaseImportRepository>(
      () => DatabaseImportRepositoryImpl(
        mariaDbTempServer: sl(),
        sqliteDestination: sl(),
        seedTemplateProvider: sl(),
      ),
    )
    ..registerFactory(() => ImportCamaleonDatabase(sl()))
    ..registerFactory(() => ImportCubit(sl()));
}
