import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auto-discovered by `flutter test`: wraps every test in the tree. Loads the
/// fonts golden images need so text renders as real glyphs instead of the
/// default placeholder boxes:
///   - the app's bundled fonts (ZenSerif + the Material icon font), and
///   - Roboto from the Flutter SDK cache, the default family used by every
///     TextStyle that doesn't name one (the coin count, "Lv.26", "Withdraw").
/// All loading is best-effort: a missing font degrades to boxes, never a crash.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  await _loadRoboto();
  await testMain();
}

Future<void> _loadBundledFonts() async {
  try {
    final manifest =
        json.decode(await rootBundle.loadString('FontManifest.json'))
            as List<dynamic>;
    for (final family in manifest) {
      final loader = FontLoader(family['family'] as String);
      for (final font in family['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  } catch (_) {
    // No manifest (or unreadable) -> bundled-font text falls back to boxes.
  }
}

Future<void> _loadRoboto() async {
  final dir = _materialFontsDir();
  if (dir == null) return;
  final loader = FontLoader('Roboto');
  var added = 0;
  for (final name in const [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    final file = File('$dir${Platform.pathSeparator}$name');
    if (file.existsSync()) {
      loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      added++;
    }
  }
  if (added > 0) await loader.load();
}

/// `<sdk>/bin/cache/artifacts/material_fonts`, derived from the running Dart
/// executable at `<sdk>/bin/cache/dart-sdk/bin/dart`, with a fixed fallback.
String? _materialFontsDir() {
  try {
    final cache = File(Platform.resolvedExecutable).parent.parent.parent.path;
    final sep = Platform.pathSeparator;
    final candidate = Directory('$cache${sep}artifacts${sep}material_fonts');
    if (candidate.existsSync()) return candidate.path;
  } catch (_) {}
  const fallback = r'C:\flutter\bin\cache\artifacts\material_fonts';
  return Directory(fallback).existsSync() ? fallback : null;
}
