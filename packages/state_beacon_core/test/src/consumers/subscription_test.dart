import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

void main() {
  test('subscription to beacon should run until disposed', () async {
    final a = Beacon.writable(0);
    var called = 0;

    final dispose = a.subscribe((_) => called++);

    BeaconScheduler.flush();
    expect(called, 1);

    a.value = 2;
    BeaconScheduler.flush();
    expect(called, 2);

    a.value = 2; // no change
    BeaconScheduler.flush();
    expect(called, 2);

    a.set(2, force: true); // force change
    BeaconScheduler.flush();
    expect(called, 3);

    dispose();
    a.value = 10;
    BeaconScheduler.flush();
    expect(called, 3);
  });

  test('subscription to beacon should run until disposed when startNow=false',
      () async {
    final a = Beacon.writable(0);
    var called = 0;

    final dispose = a.subscribe((_) => called++, startNow: false);

    BeaconScheduler.flush();
    expect(called, 0);

    a.value = 2;
    BeaconScheduler.flush();
    expect(called, 1);

    a.value = 2; // no change
    BeaconScheduler.flush();
    expect(called, 1);

    a.set(2, force: true); // force change
    BeaconScheduler.flush();
    expect(called, 2);

    dispose();
    a.value = 10;
    BeaconScheduler.flush();
    expect(called, 2);
  });

  test(
    'subscription with startNow=false should not '
    'invoke callback immediately for lazy beacon',
    () async {
      final source = Beacon.lazyWritable<int>();

      var callCount = 0;
      final receivedValues = <int>[];

      // Subscribe with startNow = false
      // The callback should NOT be invoked immediately
      final unsub = source.subscribe(
        (value) {
          callCount++;
          receivedValues.add(value);
        },
        startNow: true,
      );

      BeaconScheduler.flush();

      // Bug #4: Previously, this would fail because the callback
      // was invoked immediately despite startNow=false
      expect(callCount, 0);

      expect(receivedValues, isEmpty);

      // Now trigger an update
      source.value = 15;
      BeaconScheduler.flush();

      // The callback should be invoked on actual updates
      expect(callCount, 1);
      expect(receivedValues, [15]);

      unsub();
    },
  );

  test('should notify all observers', () {
    final count = Beacon.writable(0);
    final triple = Beacon.derived(() => count.value * 3);

    var sub1Called = 0;
    var sub2Called = 0;

    triple.subscribe((_) => ++sub1Called);
    triple.subscribe((_) => ++sub2Called);

    BeaconScheduler.flush();

    expect(sub1Called, 1);
    expect(sub2Called, 1);

    count.increment();

    BeaconScheduler.flush();

    expect(sub1Called, 2);
    expect(sub2Called, 2, reason: 'async sub should also be called');
  });

  test('should not throw when unsub in own callback', () {
    final beacon = Beacon.writable<int>(0);
    var mounted = true;

    late void Function() unsub;
    unsub = beacon.subscribe(
      (v) {
        if (!mounted) unsub(); // Unsubscribe when "unmounted"
      },
    );

    beacon.subscribeSynchronously((v) {});
    beacon.subscribe((v) {});
    beacon.value = 1;
    mounted = false;
    beacon.value = 2;
    BeaconScheduler.flush();
  });

  test('should notify all observers (sync+async)', () {
    final count = Beacon.writable(0);
    final triple = Beacon.derived(() => count.value * 3);

    var syncCalled = 0;
    var asyncCalled = 0;
    var async2Called = 0;

    triple.subscribe((_) => ++asyncCalled);
    triple.subscribe((_) => ++async2Called);
    count.subscribeSynchronously((_) => syncCalled++);

    BeaconScheduler.flush();

    expect(asyncCalled, 1);
    expect(async2Called, 1);
    expect(syncCalled, 1);

    count.increment();
    expect(syncCalled, 2);

    BeaconScheduler.flush();

    expect(syncCalled, 2);
    expect(asyncCalled, 2);
  });

  test(
      'should notify subscription after peeking with '
      'startNow=false and type is nullable for writable', () {
    final a = Beacon.lazyWritable<int?>();

    var subCalled = 0;

    a.subscribe((_) => subCalled++, startNow: false);

    BeaconScheduler.flush();

    expect(subCalled, 0);

    a.value = 1;

    BeaconScheduler.flush();

    expect(subCalled, 1);
  });

  test('should receive updates triggered by mutating producer inside callback',
      () {
    final a = Beacon.writable(0);
    final seen = <int>[];

    final unsub = a.subscribe(
      (v) {
        seen.add(v);
        if (v == 1) a.value = 2;
      },
      startNow: false,
    );

    a.value = 1;
    BeaconScheduler.flush();

    expect(seen, [1, 2]);
    unsub();
  });

  test('should recover and receive future updates after callback throws', () {
    final a = Beacon.writable(0);
    final seen = <int>[];

    final unsub = a.subscribe(
      (v) {
        if (v == 1) throw StateError('callback error');
        seen.add(v);
      },
      startNow: false,
    );

    a.value = 1;
    expect(BeaconScheduler.flush, throwsStateError);

    a.value = 2;
    BeaconScheduler.flush();

    expect(seen, [2]);
    unsub();
  });

  test('should safely add and remove subscribers during multi-observer update',
      () {
    final a = Beacon.writable(0);
    final log = <String>[];
    void Function()? unsubRemoved;
    void Function()? unsubAdded;

    // Register a synchronous observer plus two async observers (triggering the
    // multi-observer loop). During notification, the sync observer removes one
    // async observer (calling _removeObserver synchronously while _notifying>0)
    // and adds a new observer (calling _addObserver while _notifying>0).
    final unsubFirst = a.subscribeSynchronously(
      (v) {
        log.add('first:$v');
        if (v == 1) {
          unsubRemoved?.call();
          unsubAdded = a.subscribeSynchronously(
            (v2) => log.add('added:$v2'),
            startNow: false,
          );
        }
      },
      startNow: false,
    );

    unsubRemoved = a.subscribe(
      (v) => log.add('removed:$v'),
      startNow: false,
    );

    final unsubAsync = a.subscribe(
      (v) => log.add('async:$v'),
      startNow: false,
    );

    a.value = 1;
    BeaconScheduler.flush();

    // Copy-on-write preserves the snapshot for the in-flight notification,
    // while removing `removed` and adding `added` for subsequent updates.
    expect(log, ['first:1', 'async:1']);
    expect(a.listenersCount, 3);
    log.clear();

    a.value = 2;
    BeaconScheduler.flush();

    expect(log, ['first:2', 'added:2', 'async:2']);

    unsubFirst();
    unsubAdded?.call();
    unsubAsync();
  });
}
