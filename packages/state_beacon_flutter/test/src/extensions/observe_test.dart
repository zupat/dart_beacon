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
}
