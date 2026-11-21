// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/src/value_notifier_beacon.dart';

void main() {
  test('should notify listener and call dispose callbacks', () {
    final beacon = ValueNotifierBeacon(0);
    var called = 0;

    void disposeTest() => called++;

    beacon.addListener(() => called++);

    expect(beacon.value, 0);

    beacon.set(1);

    expect(beacon.value, 1);
    expect(called, 1);

    beacon
      ..addDisposeCallback(disposeTest)
      ..dispose();

    expect(called, 2);
  });

  test('should clear disposeListeners after dispose', () {
    final beacon = ValueNotifierBeacon(0)..addDisposeCallback(() {});

    expect(beacon.disposeListeners, hasLength(1));

    beacon.dispose();

    expect(
      beacon.disposeListeners,
      isEmpty,
      reason: 'disposeListeners should be cleared on dispose to avoid '
          'retaining closures.',
    );
  });

  test(
    'should not throw ConcurrentModificationError when a dispose callback '
    'modifies disposeListeners',
    () {
      final beacon = ValueNotifierBeacon(0);
      var secondRan = false;

      beacon
        ..addDisposeCallback(() => beacon.addDisposeCallback(() {}))
        ..addDisposeCallback(() => secondRan = true);

      expect(beacon.dispose, returnsNormally);
      expect(secondRan, isTrue);
    },
  );
}
