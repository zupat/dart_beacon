import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

Set<String> _collectExportedLibraries(String entryPath) {
  final visited = <String>{};
  final queue = <String>[entryPath];
  final directivePattern = RegExp(r'''^(?:export|part)\s+['"]([^'"]+)['"]''');

  while (queue.isNotEmpty) {
    final path = queue.removeLast();
    final file = File(path);
    if (!file.existsSync()) continue;
    final normalized = file.uri.normalizePath().toFilePath();
    if (!visited.add(normalized)) continue;

    final dir = file.parent.uri;
    for (final line in file.readAsLinesSync()) {
      final match = directivePattern.firstMatch(line.trim());
      if (match == null) continue;
      final target = match.group(1)!;
      if (target.startsWith('package:') || target.startsWith('dart:')) {
        continue;
      }
      queue.add(dir.resolve(target).toFilePath());
    }
  }

  return visited;
}

void main() {
  test('should be exported from package entrypoint', () {
    final exported = _collectExportedLibraries('lib/state_beacon_flutter.dart');
    final valueNotifierExt = File('lib/src/extensions/value_notifier.dart')
        .uri
        .normalizePath()
        .toFilePath();

    expect(
      exported,
      contains(valueNotifierExt),
      reason: 'ValueNotifierUtils (toBeacon) should be exported from '
          'lib/state_beacon_flutter.dart.',
    );
  });
  test('should be synced with source value notifier', () async {
    final notifier = ValueNotifier(0);
    final beacon = notifier.toBeacon();

    expect(beacon.peek(), 0);

    notifier.value = 1;

    expect(beacon.value, 1);

    notifier.value = 2;

    expect(beacon.value, 2);

    beacon.increment();

    expect(beacon.value, 3);

    expect(notifier.value, 3);
  });

  test(
    'should stay in sync when a ValueNotifier listener modifies value '
    're-entrantly',
    () {
      final notifier = ValueNotifier(0);
      final beacon = notifier.toBeacon();

      notifier.addListener(() {
        if (notifier.value > 10) {
          notifier.value = 10;
        }
      });

      beacon.value = 20;

      expect(notifier.value, 10);
      expect(
        beacon.value,
        10,
        reason: 'Re-entrant writes from a ValueNotifier listener must sync '
            'back to the beacon.',
      );

      beacon.dispose();
      notifier.dispose();
    },
  );

  test(
    'should not trigger spurious ValueNotifier notifications on creation',
    () {
      final notifier = ValueNotifier<double>(double.nan);
      var calls = 0;
      notifier.addListener(() => calls++);

      final beacon = notifier.toBeacon();

      expect(
        calls,
        0,
        reason: 'toBeacon() should subscribe with startNow: false so it does '
            'not emit a spurious notification on creation.',
      );

      beacon.dispose();
      notifier.dispose();
    },
  );
}
