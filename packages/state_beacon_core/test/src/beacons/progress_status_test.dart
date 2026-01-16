import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

import '../../common.dart';

void main() {
  test('should have correct status when starting and stopping', () async {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 5,
    );

    expect(beacon.status.value, ProgressStatus.running);

    await delay(k10ms * 2);
    expect(beacon.status.value, ProgressStatus.running);

    beacon.stop();
    expect(beacon.status.value, ProgressStatus.stopped);

    beacon.start();
    expect(beacon.status.value, ProgressStatus.running);

    await delay(k10ms * 7);
    expect(beacon.status.value, ProgressStatus.stopped);

    beacon.dispose();
  });

  test('should have correct status when pausing and resuming', () async {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 5,
    );

    expect(beacon.status.value, ProgressStatus.running);

    beacon.pause();
    expect(beacon.status.value, ProgressStatus.paused);

    beacon.resume();
    expect(beacon.status.value, ProgressStatus.running);

    beacon.stop();
    expect(beacon.status.value, ProgressStatus.stopped);

    // Pause on stopped beacon should not change status
    beacon.pause();
    expect(beacon.status.value, ProgressStatus.stopped);

    beacon.dispose();
  });

  test('should have correct status with onStart', () async {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 5,
      onStart: () => 0.0,
      initialValue: 0,
    );

    expect(beacon.status.value, ProgressStatus.stopped);

    beacon.start();
    expect(beacon.status.value, ProgressStatus.running);

    beacon.dispose();
  });

  test('should have correct status with loop', () async {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 2,
      loop: true,
    );

    expect(beacon.status.value, ProgressStatus.running);

    await delay(k10ms * 3);
    // Even after it finishes once, it should be running (restarting)
    expect(beacon.status.value, ProgressStatus.running);

    beacon.dispose();
  });

  test('status beacon should be reactive', () async {
    final beacon = Beacon.progress<double>(
      interval: k10ms,
      onProgress: (progress) => progress,
      totalDuration: k10ms * 5,
    );

    expect(
      beacon.status.stream,
      emitsInOrder([
        ProgressStatus.running,
        ProgressStatus.paused,
        ProgressStatus.running,
        ProgressStatus.stopped,
      ]),
    );

    BeaconScheduler.flush();

    beacon.pause();
    BeaconScheduler.flush();

    beacon.resume();
    BeaconScheduler.flush();

    beacon.stop();
    BeaconScheduler.flush();

    beacon.dispose();
  });
}
