import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

void main() {
  BeaconScheduler.useFlutterScheduler();

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
}
