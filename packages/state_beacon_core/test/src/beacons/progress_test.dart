import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

import '../../common.dart';

void main() {
  test('should have initial value of 0.0 progress', () {
    final myBeacon = Beacon.progress(
      k10ms,
      (progress) => progress,
      totalDuration: k10ms * 5,
    );
    expect(myBeacon.peek(), 0.0);
    myBeacon.dispose();
  });

  test('should emit values periodically with progress', () async {
    final myBeacon = Beacon.progress<double>(
      k10ms,
      (progress) => progress,
      totalDuration: k10ms * 3,
    );

    // Wait for completion
    await delay(k10ms * 5);

    // Final value should be 1.0 (100% progress)
    expect(myBeacon.peek(), equals(1.0));

    myBeacon.dispose();

    expect(myBeacon.isDisposed, true);
  });

  test('should pause and resume emission of values', () async {
    final myBeacon = Beacon.progress<double>(
      k10ms,
      (progress) => progress,
      totalDuration: k10ms * 10,
    );

    await delay(k10ms * 2);

    final progressBeforePause = myBeacon.peek();
    expect(progressBeforePause, greaterThan(0.0));
    expect(progressBeforePause, lessThan(1.0));

    myBeacon.pause();

    await delay(k10ms * 3);

    // Progress should not have changed while paused
    expect(myBeacon.peek(), equals(progressBeforePause));

    myBeacon.resume();

    await delay(k10ms * 10);

    // Should have completed after resume
    expect(myBeacon.peek(), equals(1.0));

    myBeacon.dispose();
  });

  test('manualStart uses provided initialValue and does not auto-start',
      () async {
    final myBeacon = Beacon.progress<double>(
      k10ms,
      (progress) => progress,
      totalDuration: k10ms * 3,
      manualStart: true,
      initialValue: 0,
    );

    expect(myBeacon.peek(), 0.0);

    await delay(k10ms * 3);

    // Still initial value because start() has not been called.
    expect(myBeacon.peek(), 0.0);

    myBeacon.dispose();
  });

  test('progress goes from 0.0 to 1.0 based on elapsed time', () async {
    final values = <double>[];
    final beacon = Beacon.progress<double>(
      k10ms,
      (progress) => progress,
      totalDuration: k10ms * 3,
    );

    beacon.subscribe(values.add);

    // Wait for completion
    await delay(k10ms * 5);

    expect(values.first, equals(0.0));
    expect(values.last, equals(1.0));
    for (final v in values) {
      expect(v, inInclusiveRange(0.0, 1.0));
    }

    beacon.dispose();
  });

  test('start() restarts the beacon from beginning', () async {
    final beacon = Beacon.progress<double>(
      k10ms,
      (progress) => progress,
      totalDuration: k10ms * 3,
    );

    // Wait for completion
    await delay(k10ms * 5);

    expect(beacon.peek(), equals(1.0));

    // Restart
    beacon.start();

    // Should have reset progress
    await delay(k10ms);

    final progressAfterRestart = beacon.peek();
    expect(progressAfterRestart, lessThan(1.0));
    expect(progressAfterRestart, greaterThan(0.0));

    beacon.dispose();
  });
}
