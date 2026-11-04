import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class PathField extends StatefulWidget {
  const PathField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.browseLabel,
    required this.onBrowse,
    required this.onPathDropped,
    this.enabled = true,
    this.acceptFilesAsParentDir = false,
  });

  final String label;
  final String hint;
  final String value;
  final String browseLabel;
  final VoidCallback onBrowse;
  final ValueChanged<String> onPathDropped;
  final bool enabled;

  /// If true, dropping a file uses its parent folder.
  final bool acceptFilesAsParentDir;

  @override
  State<PathField> createState() => _PathFieldState();
}

class _PathFieldState extends State<PathField> {
  bool _dragging = false;

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (!widget.enabled || details.files.isEmpty) return;

    for (final file in details.files) {
      final path = file.path;
      if (path.isEmpty) continue;

      final asDir = Directory(path);
      if (await asDir.exists()) {
        widget.onPathDropped(path);
        return;
      }

      final asFile = File(path);
      if (widget.acceptFilesAsParentDir && await asFile.exists()) {
        widget.onPathDropped(p.dirname(path));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _dragging
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final fill = _dragging
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
        : theme.colorScheme.surfaceContainerLowest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropTarget(
                enable: widget.enabled,
                onDragEntered: (_) => setState(() => _dragging = true),
                onDragExited: (_) => setState(() => _dragging = false),
                onDragDone: (details) async {
                  setState(() => _dragging = false);
                  await _handleDrop(details);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: _dragging ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: fill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Text(
                      widget.value.isEmpty ? widget.hint : widget.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.value.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: widget.enabled ? widget.onBrowse : null,
              child: Text(widget.browseLabel),
            ),
          ],
        ),
      ],
    );
  }
}
