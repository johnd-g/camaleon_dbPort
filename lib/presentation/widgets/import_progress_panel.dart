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
    final fraction = progress?.fraction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(l10n.t('progress'), style: theme.textTheme.labelLarge),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                [
                  l10n.phaseLabel(phase.name),
                  if (progress?.currentTable != null)
                    '${progress!.currentTable}'
                    '${progress!.totalTables > 0 ? ' (${progress!.completedTables}/${progress!.totalTables})' : ''}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: isRunning ? fraction : (phase == ImportPhase.done ? 1 : 0),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
