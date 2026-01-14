import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

import '../../common.dart';

// Define throwsAssertionError for the test
final throwsAssertionError = throwsA(isA<AssertionError>());

void main() {
  test('should have initial value of 0.0 progress', () {
    final myBeacon = Beacon.progress(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 5,
    );
    expect(myBeacon.peek(), 0.0);
    myBeacon.dispose();
  });

  test('should emit values periodically with progress', () async {
    final myBeacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
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
      interval: k10ms,
      onProgress: (progress) => progress,
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
      interval: k10ms,
      onProgress: (progress) => progress,
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
      interval: k10ms,
      onProgress: (progress) => progress,
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
      interval: k10ms,
      onProgress: (progress) => progress,
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

  test(
      'should throw assertion error if manualStart is true and'
      ' initialValue is not provided', () {
    expect(
      () => Beacon.progress<double>(
        interval: k10ms,
        onProgress: (progress) => progress,
        totalDuration: k10ms * 3,
        manualStart: true,
        // initialValue is missing
      ),
      throwsAssertionError,
    );
  });

  test(
      'should stop emitting values and cancel'
      ' subscription when stop() is called', () async {
    final values = <double>[];
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 10,
    );

    beacon.subscribe(values.add);

    await delay(k10ms * 2);
    final progressBeforeStop = beacon.peek();
    expect(progressBeforeStop, greaterThan(0.0));
    expect(progressBeforeStop, lessThan(1.0));

    beacon.stop();

    await delay(k10ms * 3);

    // Progress should not have changed after stop
    expect(beacon.peek(), equals(progressBeforeStop));
    expect(values.length, equals(2)); // Should have stopped emitting

    beacon.dispose();
  });

  test('should support custom return types (non-double) for onProgress',
      () async {
    final beacon = Beacon.progress<String>(
      interval: k10ms,
      onProgress: (progress) => 'Progress: ${progress * 100}%',
      totalDuration: k10ms * 3,
    );

    await delay(k10ms * 2);
    final value = beacon.peek();
    expect(value, isA<String>());
    expect(value, contains('Progress:'));
    expect(value, contains('%'));

    await delay(k10ms * 2);
    expect(beacon.peek(), equals('Progress: 100.0%'));

    beacon.dispose();
  });

  test(
      'should restart progression from zero if'
      ' start() is called while already running', () async {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 3,
    );

    await delay(k10ms * 2.5);
    final progressBeforeRestart = beacon.peek();
    expect(progressBeforeRestart, greaterThan(0.0));
    expect(progressBeforeRestart, lessThan(1.0));

    beacon.start(); // Restart while running

    await delay(k10ms);
    final progressAfterRestart = beacon.peek();
    expect(progressAfterRestart, lessThan(progressBeforeRestart));
    expect(progressAfterRestart, greaterThan(0.0));

    beacon.dispose();
  });

  test(
      'should handle pause() and resume() safely when'
      ' the beacon is not yet started or already stopped', () {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 3,
      manualStart: true,
      initialValue: 0,
    );

    // Should not crash when called on a beacon that hasn't started
    expect(beacon.pause, returnsNormally);
    expect(beacon.resume, returnsNormally);

    beacon.start();
    beacon.stop();

    // Should not crash when called on a stopped beacon
    expect(beacon.pause, returnsNormally);
    expect(beacon.resume, returnsNormally);

    beacon.dispose();
  });

  test('should throw if the interval is greater than or equal to totalDuration',
      () async {
    late final beacon = Beacon.progress<double>(
      interval: k10ms * 5, // Interval > totalDuration
      onProgress: (progress) => progress,
      totalDuration: k10ms * 3,
    );

    expect(() => beacon, throwsAssertionError);
  });

  test(
      'should clamp progress to 1.0 and stop '
      'even if elapsed time exceeds totalDuration', () async {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 2,
    );

    await delay(k10ms * 5); // Wait longer than totalDuration
    expect(beacon.peek(), equals(1.0));

    // Should not exceed 1.0 even after more time
    await delay(k10ms * 5);
    expect(beacon.peek(), equals(1.0));

    beacon.dispose();
  });

  test('should not emit any values or perform work after dispose() is called',
      () async {
    final values = <double>[];
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 10,
    );

    beacon.subscribe(values.add);

    await delay(k10ms * 2);
    final initialCount = values.length;
    expect(initialCount, greaterThan(0));

    beacon.dispose();

    await delay(k10ms * 3);

    // Should not have emitted any new values after dispose
    expect(values.length, equals(initialCount));
  });
}
