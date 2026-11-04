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
        const SizedBox(height: 6),
        Text(
          '${l10n.t('destination')}: ${report.destinationPath}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${l10n.t('tablesImported')}: ${report.importedCount}  ·  '
          '${l10n.t('tablesMissing')}: ${report.missingCount}  ·  '
          '${l10n.t('ezwayOrders')}: ${report.ezwayOrderCount}  ·  '
          '${l10n.t('webStores')}: ${report.webStoreCount}',
        ),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              color: theme.colorScheme.surfaceContainerLowest,
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: report.tableResults.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _TableResultTile(result: report.tableResults[index]);
              },
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
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
