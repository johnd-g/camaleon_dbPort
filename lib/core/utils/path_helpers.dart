import 'dart:io';

import 'package:path/path.dart' as p;

String joinPath(String a, [String? b, String? c, String? d]) {
  if (d != null) return p.join(a, b!, c!, d);
  if (c != null) return p.join(a, b!, c);
  if (b != null) return p.join(a, b);
  return a;
}

String basenamePath(String path) => p.basename(path);

Future<void> ensureParentDir(String filePath) async {
  final dir = Directory(p.dirname(filePath));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}

Future<void> copyFile(String from, String to) async {
  await ensureParentDir(to);
  await File(from).copy(to);
}

Future<void> copyDirectory(Directory source, Directory target) async {
  if (await target.exists()) {
    await target.delete(recursive: true);
  }
  await target.create(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    final name = p.basename(entity.path);
    if (entity is File) {
      await entity.copy(p.join(target.path, name));
    } else if (entity is Directory) {
      await copyDirectory(entity, Directory(p.join(target.path, name)));
    }
  }
}

Future<int> findFreePort({int start = 3310, int end = 3400}) async {
  for (var port = start; port <= end; port++) {
    try {
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      await server.close();
      return port;
    } catch (_) {
      continue;
    }
  }
  throw StateError('No free local port between $start and $end');
}
