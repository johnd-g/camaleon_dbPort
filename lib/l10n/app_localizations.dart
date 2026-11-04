import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('es')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localized = {
    'en': {
      'appTitle': 'Camaleon DB Importer',
      'subtitle': 'Copy all shared MyISAM tables into a named SQLite seed.',
      'language': 'Language',
      'english': 'English',
      'spanish': 'Spanish',
      'sourceFolder': 'MyISAM source folder',
      'sourceHint': 'Drop a folder here, or browse (.frm / .MYD / .MYI)',
      'outputFolder': 'Output folder',
      'outputHint': 'Where <name>.db is saved',
      'mariaBin': 'MariaDB bin folder (optional)',
      'mariaHint': 'Drop MariaDB bin folder, or leave empty to auto-detect',
      'browse': 'Browse',
      'startImport': 'Start import',
      'running': 'Importing…',
      'clear': 'Clear result',
      'progress': 'Progress',
      'log': 'Log',
      'summary': 'Summary',
      'success': 'Import succeeded',
      'failure': 'Import failed',
      'copyError': 'Copy error',
      'missingPaths': 'Select source folder and output folder.',
      'destination': 'Destination',
      'tablesImported': 'Tables imported',
      'tablesMissing': 'Tables missing in source',
      'ezwayOrders': 'Online accounts (EZway_order ≠ 0)',
      'webStores': 'Web stores (web_store = 1)',
      'rowsRead': 'Read',
      'rowsWritten': 'Written',
      'ignoredCols': 'Ignored columns',
      'statusImported': 'Imported',
      'statusMissing': 'Missing',
      'statusError': 'Skipped',
      'idleHint': 'Choose source and output folders, then run the import.',
      'idleReadyHint': 'Paths selected. Press Start import — results appear here.',
      'phase_idle': 'Ready',
      'phase_validating': 'Validating',
      'phase_preparingSeed': 'Preparing seed',
      'phase_copyingSource': 'Copying source',
      'phase_startingMariaDb': 'Starting MariaDB',
      'phase_importingTables': 'Importing tables',
      'phase_verifying': 'Verifying schemas',
      'phase_finalizing': 'Finalizing',
      'phase_cleaningUp': 'Cleaning up',
      'phase_done': 'Done',
      'phase_failed': 'Failed',
    },
    'es': {
      'appTitle': 'Importador DB Camaleon',
      'subtitle': 'Copia todas las tablas MyISAM compartidas a un SQLite con su nombre.',
      'language': 'Idioma',
      'english': 'Inglés',
      'spanish': 'Español',
      'sourceFolder': 'Carpeta MyISAM origen',
      'sourceHint': 'Suelta una carpeta aquí, o elige (.frm / .MYD / .MYI)',
      'outputFolder': 'Carpeta de salida',
      'outputHint': 'Dónde se guarda <nombre>.db',
      'mariaBin': 'Carpeta bin de MariaDB (opcional)',
      'mariaHint': 'Suelta la carpeta bin de MariaDB, o déjala vacía',
      'browse': 'Elegir',
      'startImport': 'Iniciar importación',
      'running': 'Importando…',
      'clear': 'Limpiar resultado',
      'progress': 'Progreso',
      'log': 'Registro',
      'summary': 'Resumen',
      'success': 'Importación correcta',
      'failure': 'Importación fallida',
      'copyError': 'Copiar error',
      'missingPaths': 'Elige carpeta origen y carpeta de salida.',
      'destination': 'Destino',
      'tablesImported': 'Tablas importadas',
      'tablesMissing': 'Tablas ausentes en origen',
      'ezwayOrders': 'Cuentas online (EZway_order ≠ 0)',
      'webStores': 'Tiendas web (web_store = 1)',
      'rowsRead': 'Leídas',
      'rowsWritten': 'Escritas',
      'ignoredCols': 'Columnas ignoradas',
      'statusImported': 'Importada',
      'statusMissing': 'Ausente',
      'statusError': 'Omitida',
      'idleHint': 'Elige origen y carpeta de salida, e inicia la importación.',
      'idleReadyHint':
          'Rutas listas. Pulsa Iniciar importación — el resumen sale aquí.',
      'phase_idle': 'Listo',
      'phase_validating': 'Validando',
      'phase_preparingSeed': 'Preparando semilla',
      'phase_copyingSource': 'Copiando origen',
      'phase_startingMariaDb': 'Arrancando MariaDB',
      'phase_importingTables': 'Importando tablas',
      'phase_verifying': 'Verificando esquemas',
      'phase_finalizing': 'Finalizando',
      'phase_cleaningUp': 'Limpiando',
      'phase_done': 'Listo',
      'phase_failed': 'Falló',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _localized[lang]?[key] ?? _localized['en']![key] ?? key;
  }

  String phaseLabel(String phaseName) => t('phase_$phaseName');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
