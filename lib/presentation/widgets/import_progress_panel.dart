import 'package:flutter/material.dart';

import '../../domain/entities/import_progress.dart';
import '../../l10n/app_localizations.dart';

class ImportProgressPanel extends StatelessWidget {
  const ImportProgressPanel({
    super.key,
    required this.phase,
    required this.progress,
    required this.isRunning,
  });

  final ImportPhase phase;
  final ImportProgress? progress;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fraction = progress?.fraction ?? (isRunning ? null : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.t('progress'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: isRunning ? fraction : (phase == ImportPhase.done ? 1 : 0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(l10n.phaseLabel(phase.name), style: theme.textTheme.bodyLarge),
        if (progress?.currentTable != null) ...[
          const SizedBox(height: 4),
          Text(
            '${progress!.currentTable}'
            '${progress!.totalTables > 0 ? ' (${progress!.completedTables}/${progress!.totalTables})' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
