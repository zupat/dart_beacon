// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: hash_and_equals

import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/src/extensions/extensions.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

class _CollidingBeacon<T> extends WritableBeacon<T> {
  _CollidingBeacon(T initialValue, this.forcedHash)
      : super(initialValue: initialValue);

  final int forcedHash;

  @override
  int get hashCode => forcedHash;
}

Future<void> _forceFullGC() async {
  final start = reachabilityBarrier;
  final oldGen = <List<int>>[];
  while (reachabilityBarrier < start + 3) {
    oldGen.add(List<int>.filled(256 * 1024, 0));
    if (oldGen.length > 32) {
      oldGen.clear();
    }
    await Future<void>.delayed(Duration.zero);
  }
}

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

  test(
    'toValueNotifier should not add duplicate listeners that overwrite '
    'user listener mutations',
    () {
      final beacon = Beacon.writable(0);
      final vn1 = beacon.toValueNotifier();
      vn1.addListener(() {
        if (vn1.value == 1) {
          beacon.value = 99;
        }
      });

      // Calling toValueNotifier() again returns the same notifier and must
      // not append a duplicate write-back listener after user listeners.
      final vn2 = beacon.toValueNotifier();
      expect(identical(vn1, vn2), isTrue);

      beacon.value = 1;
      BeaconScheduler.flush();

      expect(
        beacon.value,
        99,
        reason: 'A second toValueNotifier() call must not attach a duplicate '
            'listener that overwrites mutations made by user listeners.',
      );

      // External writes to the ValueNotifier still sync back to the beacon.
      vn1.value = 42;
      expect(beacon.value, 42);

      beacon.dispose();
    },
  );

  test(
    'toValueNotifier should not collide for distinct beacons with the same '
    'hashCode',
    () {
      final intBeacon = _CollidingBeacon<int>(1, 12345);
      final strBeacon = _CollidingBeacon<String>('hi', 12345);

      final intVn = intBeacon.toValueNotifier();
      expect(intVn.value, 1);

      expect(
        () {
          final strVn = strBeacon.toValueNotifier();
          expect(strVn.value, 'hi');
        },
        returnsNormally,
        reason: 'Distinct beacons with the same hashCode must not collide in '
            '_vnCache or throw TypeError.',
      );

      intBeacon.dispose();
      strBeacon.dispose();
    },
  );

  test(
    'toValueNotifier on a disposed beacon should not pollute _vnCache',
    () {
      final beacon = Beacon.writable(0)..dispose();

      expect(beacon.toValueNotifier, throwsA(isA<AssertionError>()));
      expect(
        hasNotifier(beacon),
        isFalse,
        reason: 'A failed toValueNotifier() on a disposed beacon must not '
            'leave an unsubscribed notifier in _vnCache.',
      );
      expect(beacon.toValueNotifier, throwsA(isA<AssertionError>()));
    },
  );

  test(
    'toListenable should not prevent unreachable beacons from being '
    'garbage collected',
    () async {
      WeakReference<WritableBeacon<int>> createPlainAndDrop() {
        final b = Beacon.writable(0);
        return WeakReference(b);
      }

      WeakReference<WritableBeacon<int>> createListenableAndDrop() {
        final b = Beacon.writable(0)..toListenable();
        return WeakReference(b);
      }

      final plainRef = createPlainAndDrop();
      final vnRef = createListenableAndDrop();

      await _forceFullGC();

      // Control: plain unreachable beacon is collected.
      expect(plainRef.target, isNull);

      expect(
        vnRef.target,
        isNull,
        reason: 'Calling toListenable() must not permanently root the beacon '
            'in a strong global Map.',
      );
    },
  );
}
