import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

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
  BeaconScheduler.useFlutterScheduler();

  tearDown(BeaconScheduler.useFlutterScheduler);

  testWidgets('observe uses the latest callback after a rebuild', (
    tester,
  ) async {
    final beacon = Beacon.writable(0);
    final calls = <String>[];

    Widget buildApp(String tag) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              beacon.observe(context, (prev, next) {
                calls.add('$tag: $prev -> $next');
              });
              return Text('${beacon.watch(context)}');
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp('first'));

    beacon.value = 1;
    await tester.pumpAndSettle();

    expect(calls, ['first: 0 -> 1']);

    await tester.pumpWidget(buildApp('second'));

    beacon.value = 2;
    await tester.pumpAndSettle();

    expect(
      calls,
      ['first: 0 -> 1', 'second: 1 -> 2'],
      reason: 'The callback from the latest build must replace the old one.',
    );

    beacon.dispose();
  });

  test(
    'observe allows unmounted Element to be garbage collected when callback '
    'captures context',
    () async {
      final watchBeacon = Beacon.writable(0);
      final observeBeacon = Beacon.writable(0);

      WeakReference<Element> createWatched() {
        final el = StatelessElement(const Placeholder());
        watchBeacon.watch(el);
        return WeakReference(el);
      }

      WeakReference<Element> createObserved() {
        final el = StatelessElement(const Placeholder());
        observeBeacon.observe(el, (prev, next) {
          // Standard usage: callback captures BuildContext.
          el.widget;
        });
        return WeakReference(el);
      }

      final watchRef = createWatched();
      final observeRef = createObserved();

      await _forceFullGC();

      // Control: watch() does not retain the Element.
      expect(watchRef.target, isNull);
      expect(watchBeacon.listenersCount, 0);

      expect(
        observeRef.target,
        isNull,
        reason: 'observe() must not keep a strong GC root to context via '
            '_finalizer / _observerCallbacks.',
      );
      expect(observeBeacon.listenersCount, 0);

      watchBeacon.dispose();
      observeBeacon.dispose();
    },
  );

  testWidgets(
    'observe does not throw LateInitializationError on an uninitialized '
    'lazy beacon',
    (tester) async {
      final lazy = Beacon.lazyWritable<int>();
      final transitions = <(int, int)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              lazy.observe(context, (prev, next) {
                transitions.add((prev, next));
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'observe() returns void and must not crash calling peek() on '
            'an uninitialized lazy beacon.',
      );

      // First value initializes the lazy beacon (previousValue is null).
      lazy.value = 1;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(transitions, isEmpty);

      // Subsequent updates deliver (prev, next) normally.
      lazy.value = 2;
      await tester.pumpAndSettle();
      expect(transitions, [(1, 2)]);

      lazy.dispose();
    },
  );

  testWidgets(
    'observe does not throw TypeError when DerivedBeacon recovers from '
    'initial error',
    (tester) async {
      final shouldThrow = Beacon.writable(true);
      final derived = Beacon.derived<int>(() {
        if (shouldThrow.value) throw StateError('init fail');
        return 42;
      });

      expect(() => derived.value, throwsStateError);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              try {
                derived.observe(context, (prev, next) {});
              } catch (_) {}
              return const SizedBox();
            },
          ),
        ),
      );
      // Clear any exception from initial forced evaluation.
      tester.takeException();
      BeaconScheduler.useFlutterScheduler();

      shouldThrow.value = false;

      expect(
        BeaconScheduler.flush,
        returnsNormally,
        reason: 'observe() must not throw TypeError casting null '
            'previousValue to T on recovery.',
      );

      derived.dispose();
      shouldThrow.dispose();
    },
  );
}
