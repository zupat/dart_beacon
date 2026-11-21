import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

void main() {
  tearDown(BeaconScheduler.useFlutterScheduler);

  testWidgets(
    'flutterScheduler recovers and flushes future updates after an error '
    'in microtask flush',
    (tester) async {
      BeaconScheduler.useFlutterScheduler();
      final a = Beacon.writable(0);
      final b = Beacon.writable(0);
      var bCalls = 0;

      a.subscribe(
        (v) {
          if (v == 1) throw StateError('boom');
        },
        startNow: false,
      );
      b.subscribe((_) => bCalls++, startNow: false);

      final errors = <Object>[];
      await tester.runAsync(() async {
        await runZonedGuarded(
          () async {
            a.value = 1;
            await Future<void>.delayed(const Duration(milliseconds: 20));
          },
          (error, _) => errors.add(error),
        );
      });

      expect(errors, hasLength(1));
      expect(errors.first, isA<StateError>());

      b.value = 1;
      await tester.pumpAndSettle();

      expect(
        bCalls,
        1,
        reason: '_flushing must be reset in finally so subsequent updates '
            'still flush after an error.',
      );

      a.dispose();
      b.dispose();
    },
  );

  testWidgets(
    'flutterScheduler recovers and flushes future updates after an error '
    'in postFrameCallback flush',
    (tester) async {
      BeaconScheduler.useFlutterScheduler();
      final a = Beacon.writable(0);
      final b = Beacon.writable(0);
      var bCalls = 0;

      a.subscribe(
        (v) {
          if (v == 1) throw StateError('boom in postFrame');
        },
        startNow: false,
      );
      b.subscribe((_) => bCalls++, startNow: false);

      // Mutate `a` during build (SchedulerPhase.persistentCallbacks) so
      // _flutterScheduler schedules via addPostFrameCallback.
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            if (a.peek() == 0) {
              a.value = 1;
            }
            return const SizedBox();
          },
        ),
      );

      expect(tester.takeException(), isA<StateError>());

      b.value = 1;
      await tester.pumpAndSettle();

      expect(
        bCalls,
        1,
        reason: '_flushing must be reset in finally in the postFrameCallback '
            'branch too.',
      );

      a.dispose();
      b.dispose();
    },
  );
}
