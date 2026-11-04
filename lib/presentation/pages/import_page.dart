import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/app_localizations.dart';
import '../cubit/import_cubit.dart';
import '../widgets/import_progress_panel.dart';
import '../widgets/import_summary_panel.dart';
import '../widgets/path_field.dart';

class ImportPage extends StatelessWidget {
  const ImportPage({super.key});

  Future<void> _pickDirectory({
    required void Function(String path) onPicked,
  }) async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null && path.isNotEmpty) {
      onPicked(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ImportCubit, ImportState>(
          builder: (context, state) {
            final cubit = context.read<ImportCubit>();
            return LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 48,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.t('appTitle'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.t('subtitle'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(l10n.t('language')),
                                const SizedBox(width: 8),
                                SegmentedButton<String>(
                                  segments: [
                                    ButtonSegment(
                                      value: 'en',
                                      label: Text(l10n.t('english')),
                                    ),
                                    ButtonSegment(
                                      value: 'es',
                                      label: Text(l10n.t('spanish')),
                                    ),
                                  ],
                                  selected: {state.localeCode},
                                  onSelectionChanged: state.isRunning
                                      ? null
                                      : (s) => cubit.setLocaleCode(s.first),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            PathField(
                              label: l10n.t('sourceFolder'),
                              hint: l10n.t('sourceHint'),
                              value: state.sourceFolder,
                              browseLabel: l10n.t('browse'),
                              enabled: !state.isRunning,
                              acceptFilesAsParentDir: true,
                              onBrowse: () => _pickDirectory(
                                onPicked: cubit.setSourceFolder,
                              ),
                              onPathDropped: cubit.setSourceFolder,
                            ),
                            const SizedBox(height: 16),
                            PathField(
                              label: l10n.t('workspaceRoot'),
                              hint: l10n.t('workspaceHint'),
                              value: state.workspaceRoot,
                              browseLabel: l10n.t('browse'),
                              enabled: !state.isRunning,
                              onBrowse: () => _pickDirectory(
                                onPicked: cubit.setWorkspaceRoot,
                              ),
                              onPathDropped: cubit.setWorkspaceRoot,
                            ),
                            const SizedBox(height: 16),
                            PathField(
                              label: l10n.t('mariaBin'),
                              hint: l10n.t('mariaHint'),
                              value: state.mariaDbBinDir,
                              browseLabel: l10n.t('browse'),
                              enabled: !state.isRunning,
                              acceptFilesAsParentDir: true,
                              onBrowse: () => _pickDirectory(
                                onPicked: cubit.setMariaDbBinDir,
                              ),
                              onPathDropped: cubit.setMariaDbBinDir,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: state.isRunning
                                      ? null
                                      : cubit.startImport,
                                  icon: state.isRunning
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.play_arrow),
                                  label: Text(
                                    state.isRunning
                                        ? l10n.t('running')
                                        : l10n.t('startImport'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (state.hasSuccess || state.hasFailure)
                                  TextButton(
                                    onPressed: state.isRunning
                                        ? null
                                        : cubit.clearResult,
                                    child: Text(l10n.t('clear')),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ImportProgressPanel(
                              phase: state.phase,
                              progress: state.progress,
                              isRunning: state.isRunning,
                            ),
                            if (state.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(
                                ok: false,
                                title: l10n.t('failure'),
                                body: state.errorMessage == 'missing_paths'
                                    ? l10n.t('missingPaths')
                                    : state.errorMessage!,
                              ),
                            ],
                            if (state.hasSuccess) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(
                                ok: true,
                                title: l10n.t('success'),
                                body: state.report!.destinationPath,
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 360,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _LogPanel(lines: state.logLines),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: state.report == null
                                        ? Center(
                                            child: Text(
                                              l10n.t('idleHint'),
                                              textAlign: TextAlign.center,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          )
                                        : SingleChildScrollView(
                                            child: ImportSummaryPanel(
                                              report: state.report!,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.ok,
    required this.title,
    required this.body,
  });

  final bool ok;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = ok ? scheme.primaryContainer : scheme.errorContainer;
    final fg = ok ? scheme.onPrimaryContainer : scheme.onErrorContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            SelectableText(body, style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  const _LogPanel({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.t('log'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: lines.isEmpty
                ? const SizedBox.expand()
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      return Text(
                        lines[index],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: Platform.isWindows
                              ? 'Consolas'
                              : 'monospace',
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
