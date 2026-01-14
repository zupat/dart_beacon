import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

import '../../common.dart';

void main() {
  test('should have initial value', () {
    final myBeacon = Beacon.progress(k10ms, (i, progress) => i + 1);
    expect(myBeacon.peek(), 1);
  });

  test('should emit values periodically', () async {
    final myBeacon = Beacon.progress(k10ms, (i, progress) => i + 1);

    final nextFive = await myBeacon.buffer(5).next();

    expect(nextFive, [1, 2, 3, 4, 5]);

    myBeacon.dispose();

    expect(myBeacon.isDisposed, true);
  });

  test('should pause and resume emition of values', () async {
    // BeaconObserver.useLogging();

    final myBeacon = Beacon.progress(k10ms, (i, progress) => i + 1);

    final buff = myBeacon.buffer(5);

    await delay(k10ms * 2);

    final length = buff.currentBuffer().length;

    expect(length, inInclusiveRange(1, 3));

    myBeacon.pause();

    await delay(k10ms * 4);

    expect(buff.currentBuffer().length, length);

    myBeacon.resume();

    final nextFive = await buff.next();

    expect(nextFive, [1, 2, 3, 4, 5]);
  });

  test('manualStart uses provided initialValue and does not auto-start',
      () async {
    final myBeacon = Beacon.progress<int>(
      k10ms,
      (i, progress) => i + 1,
      manualStart: true,
      initialValue: 0,
    );

    expect(myBeacon.peek(), 0);

    await delay(k10ms * 3);

    // Still initial value because start() has not been called.
    expect(myBeacon.peek(), 0);
  });

  test('progress goes from 0.0 to 1.0 when maxIterations is set', () async {
    final beacon = Beacon.progress<double>(
      k10ms,
      (i, progress) => progress,
      maxIterations: 3,
    );

    final values = await beacon.buffer(4).next();

    expect(values.first, equals(0.0));
    expect(values.last, equals(1.0));
    for (final v in values) {
      expect(v, inInclusiveRange(0.0, 1.0));
    }
  });
}
