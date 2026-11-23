import 'dart:async';

import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

class _ValueReadingObserver extends LoggingObserver {
  _ValueReadingObserver(this.beaconName);

  final String beaconName;
  int updates = 0;
  final List<int> observedValues = [];

  @override
  void onUpdate(ReadableBeacon<dynamic> beacon) {
    if (beacon.name != beaconName) return;
    updates++;
    observedValues.add(beacon.value as int);
  }
}

//rm: 2 irrelevant tests
void main() {
  test('should not run until accessed', () async {
    final beacon = Beacon.writable(1);
    var effectCount = 0;

    final d = Beacon.derived(() {
      effectCount++;
      return beacon();
    });

    BeaconScheduler.flush();

    expect(effectCount, 0);

    beacon.increment();

    BeaconScheduler.flush();

    expect(effectCount, 0);

    expect(d(), 2);
    expect(effectCount, 1);

    beacon.increment();

    BeaconScheduler.flush();

    expect(effectCount, 1);

    expect(d(), 3);
    expect(effectCount, 2);
  });

  test('should be correct derived value upon initialization', () {
    final beacon = Beacon.writable<int>(10);
    final derivedBeacon = Beacon.derived(() => beacon.value * 2);

    expect(derivedBeacon.value, 20);
  });

  test('should update derived value when dependency changes', () {
    final beacon = Beacon.writable<int>(10);
    final derivedBeacon = Beacon.derived(() => beacon.value * 2);

    beacon.value = 20;
    expect(derivedBeacon.value, 40);
  });

  test('should run once per update', () {
    final beacon = Beacon.writable<int>(10);
    var called = 0;
    final derivedBeacon = Beacon.derived(() {
      called++;
      return beacon.value * 2;
    });

    beacon.value = 30;
    expect(derivedBeacon.value, 60);

    expect(called, 1);
  });

  test('should recompute when watching multiple dependencies', () {
    final beacon1 = Beacon.writable<int>(10);
    final beacon2 = Beacon.writable<int>(20);
    final derivedBeacon = Beacon.derived(() => beacon1.value + beacon2.value);

    beacon1.value = 15;
    expect(derivedBeacon.value, 35);

    beacon2.value = 25;
    expect(derivedBeacon.value, 40);
  });

  test('should ignore when derived computation mutates', () {
    final beacon1 = Beacon.writable<int>(10);

    final d = Beacon.derived(() => beacon1.value++);

    expect(d(), 10);

    beacon1.value = 20;

    expect(d(), 20);
  });

  test('should stop watching dependencies when it has no more watchers',
      () async {
    final num1 = Beacon.writable<int>(10);
    final num2 = Beacon.writable<int>(20);

    final derivedBeacon = Beacon.derived(() => num1.value + num2.value);

    expect(num1.listenersCount, 0);
    expect(num2.listenersCount, 0);
    expect(derivedBeacon.listenersCount, 0);

    final unsub = Beacon.effect(() => derivedBeacon.value);

    BeaconScheduler.flush();

    expect(derivedBeacon.listenersCount, 1);
    expect(num1.listenersCount, 1);
    expect(num2.listenersCount, 1);

    unsub();

    expect(derivedBeacon.listenersCount, 0);
    expect(num1.listenersCount, 1);
    expect(num2.listenersCount, 1);

    // should start listening again when value is accessed
    num1.value = 15;

    expect(derivedBeacon.value, 35);

    expect(derivedBeacon.listenersCount, 0);
    expect(num1.listenersCount, 1);
    expect(num2.listenersCount, 1);

    // should stop listening again when it has no more listeners

    final unsub2 = Beacon.effect(() => derivedBeacon.value);

    BeaconScheduler.flush();

    expect(derivedBeacon.listenersCount, 1);

    unsub2();

    expect(derivedBeacon.listenersCount, 0);
    expect(num1.listenersCount, 1);
    expect(num2.listenersCount, 1);

    // should start listening again when value is accessed
    num1.value = 20;

    expect(derivedBeacon.peek(), 40);

    expect(derivedBeacon.listenersCount, 0);
    expect(num1.listenersCount, 1);
    expect(num2.listenersCount, 1);
  });

  test('should conditionally stop watching beacons', () async {
    final a = Beacon.writable(1, name: 'a');
    final b = Beacon.writable(2, name: 'b');
    final c = Beacon.writable(2, name: 'c');
    final guard = Beacon.writable(true, name: 'guard');
    var ran = 0;
    var notified = 0;

    final d = Beacon.derived(
      () {
        ran++;
        if (guard.value) {
          return a() + b();
        }
        return c();
      },
      name: 'derived',
    );

    final dispose = d.subscribe((_) => notified++);

    BeaconScheduler.flush();

    expect(ran, 1);
    expect(notified, 1);

    expect(a.listenersCount, 1);
    expect(b.listenersCount, 1);
    expect(c.listenersCount, 0);

    a.value = 3;

    BeaconScheduler.flush();

    expect(ran, 2);
    expect(notified, 2);
    expect(a.listenersCount, 1);
    expect(b.listenersCount, 1);
    expect(c.listenersCount, 0);

    guard.value = false;

    BeaconScheduler.flush();

    expect(ran, 3);
    expect(notified, 3);
    expect(a.listenersCount, 0);
    expect(b.listenersCount, 0);
    expect(c.listenersCount, 1);

    b.value = 4;

    BeaconScheduler.flush();

    expect(ran, 3);
    expect(notified, 3);

    c.value = 5;

    BeaconScheduler.flush();

    expect(ran, 4);
    expect(notified, 4);

    dispose();

    BeaconScheduler.flush();

    expect(d.listenersCount, 0);
    expect(a.listenersCount, 0);
    expect(b.listenersCount, 0);
    expect(c.listenersCount, 1);
    expect(guard.listenersCount, 1);
    expect(ran, 4);
    expect(notified, 4);

    // derived shouldn't run because it's not being listened to
    guard.value = true;

    BeaconScheduler.flush();

    expect(ran, 4);
    expect(notified, 4);
  });

  test('should create single dependency if accessed multiple times', () {
    final a = Beacon.writable(1);
    var ran = 0;
    final d = Beacon.derived(() {
      ran++;
      a.value;
      a.value;
      return a.value;
    });

    expect(ran, 0);
    expect(d.value, 1);
    expect(ran, 1);
    expect(a.listenersCount, 1);
  });

  test('should allow recursive derived beacon call with existing value', () {
    final counter = Beacon.writable(0);
    late ReadableBeacon<int> derived;

    derived = Beacon.derived(() {
      final count = counter.value;
      if (count > 0 && count < 3) {
        return derived.peek() + count;
      }
      return count;
    });

    expect(derived.value, 0);

    counter.value = 1;
    expect(derived.value, 1);

    counter.value = 2;
    expect(derived.value, 3);

    counter.value = 3;
    expect(derived.value, 3);
  });

  test('should throw StateError when recursively called before it has a value',
      () {
    late ReadableBeacon<int> derived;

    derived = Beacon.derived(() {
      return derived.peek() + 1;
    });

    expect(
      () => derived.value,
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Derived Beacon called recursively before it has a value'),
        ),
      ),
    );
  });

  test('should handle nested recursive derived beacon calls', () {
    final a = Beacon.writable(0);
    late ReadableBeacon<int> derived1;
    late ReadableBeacon<int> derived2;

    derived1 = Beacon.derived(() {
      final val = a.value;
      if (val > 0) {
        return val + derived1.peek();
      }
      return val;
    });

    derived2 = Beacon.derived(() {
      final val = derived1.value;
      if (val > 0 && val < 5) {
        return val + derived2.peek();
      }
      return val;
    });

    expect(derived2.value, 0);

    a.value = 1;
    expect(derived1.value, 1);
    expect(derived2.value, 1);

    a.value = 2;
    expect(derived1.value, 3);
    expect(derived2.value, 4);

    a.value = 3;
    expect(derived1.value, 6);
    expect(derived2.value, 6);
  });

  test('should distinguish between recursive peek() and value access', () {
    final trigger = Beacon.writable(0);
    late ReadableBeacon<int> derived;
    var computeCount = 0;

    derived = Beacon.derived(() {
      computeCount++;
      final val = trigger.value;
      if (val > 0) {
        return val + derived.peek();
      }
      return val;
    });

    expect(derived.value, 0);
    expect(computeCount, 1);

    trigger.value = 1;
    expect(derived.value, 1);
    expect(computeCount, 2);

    trigger.value = 2;
    expect(derived.value, 3);
    expect(computeCount, 3);
  });

  test('should restore tracking context when compute throws', () {
    final source = Beacon.writable(0);
    var shouldThrow = true;

    final derived = Beacon.derived(() {
      final value = source.value;
      if (shouldThrow) throw StateError('compute failed');
      return value;
    });

    expect(() => derived.value, throwsStateError);

    shouldThrow = false;

    // Before the fix, currentConsumer was left pointing at this beacon, so
    // this read failed with "Recursive access detected" instead of recovering.
    expect(derived.value, 0);
    expect(derived.value, 0);
  });

  test('should let observers read the value after tracking is restored', () {
    final source = Beacon.writable(0);
    final derived = Beacon.derived(() => source.value * 2, name: 'derived');

    expect(derived.value, 0);

    final observer = _ValueReadingObserver('derived');
    BeaconObserver.instance = observer;
    addTearDown(() => BeaconObserver.instance = null);

    source.value = 1;
    expect(derived.value, 2);

    expect(observer.updates, 1);
    expect(observer.observedValues, [2]);
  });

  test('should track a different but equal raw stream beacon', () async {
    final one = StreamController<int>();
    final two = StreamController<int>();
    var created = 0;
    Stream<int> create() => created++ == 0 ? one.stream : two.stream;

    final a = Beacon.streamRaw<int>(create, initialValue: 0, name: 'raw');
    final b = Beacon.streamRaw<int>(create, initialValue: 0, name: 'raw');
    addTearDown(() {
      a.dispose();
      b.dispose();
      unawaited(one.close());
      unawaited(two.close());
    });

    final select = Beacon.writable(false);
    final derived = Beacon.derived(() => select.value ? b.value : a.value);

    expect(a, b);
    expect(derived.value, 0);

    select.value = true;
    expect(derived.value, 0);

    two.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(b.value, 2);
    expect(derived.value, 2);
  });

  test('should throw AssertionError on recursive value access', () {
    late ReadableBeacon<int> derived;

    derived = Beacon.derived(() {
      return derived.value + 1;
    });

    expect(
      () => derived.value,
      throwsA(
        isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('Recursive access detected'),
        ),
      ),
    );
  });

  test('should recover and notify observers after transient compute error', () {
    final divisor = Beacon.writable(1);
    final quotient = Beacon.derived(() {
      if (divisor.value == 0) throw StateError('divide by zero');
      return 100 ~/ divisor.value;
    });
    final doubled = Beacon.derived(() => quotient.value * 2);

    final subValues = <int>[];
    final effectValues = <int>[];
    final unsub = quotient.subscribe(subValues.add);
    final disposeEffect = Beacon.effect(() => effectValues.add(doubled.value));

    BeaconScheduler.flush();
    expect(subValues, [100]);
    expect(effectValues, [200]);

    divisor.value = 0;
    expect(BeaconScheduler.flush, throwsStateError);
    // Drain the second queued consumer that also failed on divisor == 0.
    expect(BeaconScheduler.flush, throwsStateError);

    divisor.value = 2;
    BeaconScheduler.flush();

    expect(subValues, [100, 50]);
    expect(effectValues, [200, 100]);

    unsub();
    disposeEffect();
  });

  test('should recover when first compute throws and source later changes', () {
    final divisor = Beacon.writable(0);
    final quotient = Beacon.derived(() {
      if (divisor.value == 0) throw StateError('divide by zero');
      return 100 ~/ divisor.value;
    });

    final seen = <int>[];
    final unsub = quotient.subscribe(seen.add);

    expect(BeaconScheduler.flush, throwsStateError);
    expect(seen, isEmpty);

    divisor.value = 4;
    BeaconScheduler.flush();

    expect(seen, [25]);
    unsub();
  });

  test(
    'should preserve error state when upstream derived '
    'recomputes to same value',
    () {
      final raw = Beacon.writable(1);
      final absVal = Beacon.derived(() => raw.value.abs());
      final risky = Beacon.derived(() {
        if (absVal.value == 2) throw StateError('bad value');
        return absVal.value * 10;
      });

      // Establish an initial valid value, then enter ERROR state.
      expect(risky.value, 10);
      raw.value = 2;
      expect(() => risky.value, throwsStateError);

      // Changing raw from 2 -> -2 sends CHECK to risky, while absVal
      // recomputes to the same value (2). risky must still rethrow instead of
      // returning 10.
      raw.value = -2;
      expect(() => risky.value, throwsStateError);

      // Once absVal changes to a valid value, risky recovers.
      raw.value = 3;
      expect(risky.value, 30);
    },
  );

  test(
    'should preserve initial error state when upstream derived '
    'recomputes to same value',
    () {
      final raw = Beacon.writable(2);
      final absVal = Beacon.derived(() => raw.value.abs());
      final risky = Beacon.derived(() {
        if (absVal.value == 2) throw StateError('bad initial value');
        return absVal.value * 10;
      });

      expect(() => risky.value, throwsStateError);

      // Must still throw StateError (not LateInitializationError).
      raw.value = -2;
      expect(() => risky.value, throwsStateError);

      raw.value = 4;
      expect(risky.value, 40);
    },
  );
}
