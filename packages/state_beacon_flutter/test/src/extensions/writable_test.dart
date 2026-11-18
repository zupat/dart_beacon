import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/src/extensions/extensions.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

void main() {
  test('should convert to a value notifier', () {
    final beacon = Beacon.writable(0);

    final valueNotifier = beacon.toValueNotifier();

    expect(valueNotifier, isA<ValueNotifier<int>>());

    var called = 0;

    valueNotifier.addListener(() => called++);

    beacon.value = 1;

    BeaconScheduler.flush();

    expect(called, 1);

    beacon.value = 2;

    BeaconScheduler.flush();

    expect(called, 2);

    valueNotifier.dispose();

    beacon.value = 3;

    BeaconScheduler.flush();

    expect(called, 2);
  });

  test('should remove listeners source beacon is disposed', () {
    BeaconScheduler.use60fpsScheduler(); // just to test it out for coverage

    final beacon = Beacon.writable(0);

    final valueNotifier = beacon.toValueNotifier();

    expect(valueNotifier, isA<ValueNotifier<int>>());

    var called = 0;

    valueNotifier.addListener(() => called++);

    beacon.value = 1;

    BeaconScheduler.flush();

    expect(called, 1);

    beacon.value = 2;

    BeaconScheduler.flush();

    expect(called, 2);

    beacon.dispose();

    // ignore: invalid_use_of_protected_member
    expect(valueNotifier.hasListeners, false);
  });

  test('should return the same notifier instance', () {
    final beacon = Beacon.writable(0);

    final valueNotifier = beacon.toValueNotifier();
    final valueNotifier2 = beacon.toValueNotifier();
    final valueNotifier3 = beacon.toValueNotifier();

    expect(valueNotifier, valueNotifier2);
    expect(valueNotifier2, valueNotifier3);

    expect(hasNotifier(beacon), isTrue);

    beacon.dispose();

    expect(hasNotifier(beacon), isFalse);
  });

  test(
    'should dispose a recreated notifier when the beacon is disposed',
    () {
      final beacon = Beacon.writable(0);

      beacon.toValueNotifier().dispose();

      expect(hasNotifier(beacon), isFalse);

      final secondNotifier = beacon.toValueNotifier();

      expect(hasNotifier(beacon), isTrue);
      expect(beacon.listenersCount, 1);

      var called = 0;
      secondNotifier.addListener(() => called++);

      beacon.value = 1;
      BeaconScheduler.flush();

      expect(called, 1);

      // The stale dispose callback from the first notifier must not throw here
      // and must not prevent the recreated notifier from being cleaned up.
      beacon.dispose();

      expect(hasNotifier(beacon), isFalse);
      expect(beacon.listenersCount, 0);
      // ignore: invalid_use_of_protected_member
      expect(secondNotifier.hasListeners, isFalse);
    },
  );

  test(
    'should not throw when an earlier dispose callback disposes the notifier',
    () {
      final beacon = Beacon.writable(0);

      late final ValueNotifier<int> notifier;
      var laterCallbackRan = false;

      // The first callback is registered before the notifier's own hook, so it
      // runs first while the beacon is iterating its dispose callbacks.
      beacon
        ..onDispose(() => notifier.dispose())
        ..onDispose(() => laterCallbackRan = true);

      notifier = beacon.toValueNotifier();

      beacon.dispose();

      expect(laterCallbackRan, isTrue);
      expect(hasNotifier(beacon), isFalse);
      expect(beacon.listenersCount, 0);
      // ignore: invalid_use_of_protected_member
      expect(notifier.hasListeners, isFalse);
    },
  );

  test(
    'should not leave dispose callbacks behind after repeated '
    'dispose/recreate cycles',
    () {
      final beacon = Beacon.writable(0);

      for (var i = 0; i < 3; i++) {
        beacon.toValueNotifier().dispose();
        expect(hasNotifier(beacon), isFalse);
        expect(beacon.listenersCount, 0);
      }

      final notifier = beacon.toValueNotifier();

      expect(hasNotifier(beacon), isTrue);
      expect(beacon.listenersCount, 1);

      beacon.dispose();

      expect(hasNotifier(beacon), isFalse);
      expect(beacon.listenersCount, 0);
      // ignore: invalid_use_of_protected_member
      expect(notifier.hasListeners, isFalse);
    },
  );

  test('should remove notifier from cache when notifier is disposed.', () {
    final age = Beacon.writable(50);
    final name = Beacon.writable('bob');

    final aNotifier = age.toValueNotifier();
    final nNotifier = name.toValueNotifier();

    expect(hasNotifier(age), isTrue);
    expect(hasNotifier(name), isTrue);
    expect(age.listenersCount, 1);
    expect(name.listenersCount, 1);

    aNotifier.dispose();

    expect(hasNotifier(age), isFalse);
    expect(hasNotifier(name), isTrue);
    expect(age.listenersCount, 0);

    nNotifier.dispose();

    expect(hasNotifier(age), isFalse);
    expect(hasNotifier(name), isFalse);
    expect(name.listenersCount, 0);
  });
}
