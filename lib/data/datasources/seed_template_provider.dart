import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../core/error/exceptions.dart';

/// Resolves the bundled Camaleon SQLite schema template to a real file path.
class SeedTemplateProvider {
  static const assetKey = 'assets/demo/camaleon_sqlite_database';

  /// Copies the Flutter asset (or a repo fallback) to a temp file for sqlite3.
  Future<String> materialize() async {
    final out = File(
      p.join(
        Directory.systemTemp.path,
        'camaleon_schema_seed_${DateTime.now().millisecondsSinceEpoch}.db',
      ),
    );

    try {
      final data = await rootBundle.load(assetKey);
      await out.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return out.path;
    } catch (_) {
      // Fallbacks for tests / running without a bound asset bundle.
      for (final candidate in _fallbackPaths()) {
        final file = File(candidate);
        if (await file.exists()) {
          await file.copy(out.path);
          return out.path;
        }
      }
      throw DestinationDbException(
        'Seed template missing. Expected Flutter asset "$assetKey".',
      );
    }
  }

  List<String> _fallbackPaths() {
    final cwd = Directory.current.path;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return [
      p.join(cwd, 'assets', 'demo', 'camaleon_sqlite_database'),
      p.join(
        exeDir,
        'data',
        'flutter_assets',
        'assets',
        'demo',
        'camaleon_sqlite_database',
      ),
    ];
  }
}
