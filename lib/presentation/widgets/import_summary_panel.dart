import 'package:flutter/material.dart';

import '../../domain/entities/import_report.dart';
import '../../domain/entities/table_import_result.dart';
import '../../l10n/app_localizations.dart';

class ImportSummaryPanel extends StatelessWidget {
  const ImportSummaryPanel({super.key, required this.report});

  final ImportReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.t('summary'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('${l10n.t('destination')}: ${report.destinationPath}'),
        Text('${l10n.t('tablesImported')}: ${report.importedCount}'),
        Text('${l10n.t('tablesMissing')}: ${report.missingCount}'),
        Text('${l10n.t('ezwayOrders')}: ${report.ezwayOrderCount}'),
        Text('${l10n.t('webStores')}: ${report.webStoreCount}'),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.builder(
            itemCount: report.tableResults.length,
            itemBuilder: (context, index) {
              final row = report.tableResults[index];
              return _TableResultTile(result: row);
            },
          ),
        ),
      ],
    );
  }
}

class _TableResultTile extends StatelessWidget {
  const _TableResultTile({required this.result});

  final TableImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = switch (result.status) {
      TableImportStatus.imported => l10n.t('statusImported'),
      TableImportStatus.missingInSource => l10n.t('statusMissing'),
      TableImportStatus.skippedError => l10n.t('statusError'),
    };
    final color = switch (result.status) {
      TableImportStatus.imported => theme.colorScheme.primary,
      TableImportStatus.missingInSource => theme.colorScheme.tertiary,
      TableImportStatus.skippedError => theme.colorScheme.error,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              result.tableName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$status · ${l10n.t('rowsRead')} ${result.rowsRead} · '
              '${l10n.t('rowsWritten')} ${result.rowsWritten}'
              '${result.ignoredSourceColumns.isEmpty ? '' : ' · ${l10n.t('ignoredCols')}: ${result.ignoredSourceColumns.join(', ')}'}'
              '${result.warning == null ? '' : ' · ${result.warning}'}',
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
