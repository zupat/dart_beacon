import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

import '../../common.dart';

void main() {
  group('BufferedCountBeacon', () {
    test('should buffer values until count is reached', () async {
      final beacon = Beacon.bufferedCount<int>(3);
      var buffer = <int>[];

      beacon
        ..subscribe((value) => buffer = value)
        ..add(1)
        ..add(2)
        ..add(3); // This should trigger the buffer to be set

      BeaconScheduler.flush();

      expect(buffer, equals([1, 2, 3]));
    });

    test('should clear buffer after reaching count threshold', () async {
      final beacon = Beacon.bufferedCount<int>(2);

      var buffer = <int>[];

      beacon
        ..subscribe((value) => buffer = value)
        ..add(1)
        ..add(2); // First trigger

      BeaconScheduler.flush();

      expect(buffer, equals([1, 2]));

      expect(beacon.currentBuffer.value, equals([]));

      beacon.add(3);

      expect(beacon.currentBuffer.value, equals([3]));

      beacon.add(4); // Second trigger

      BeaconScheduler.flush();

      expect(buffer, equals([3, 4]));
    });

    test('should update currentBuffer', () async {
      final beacon = Beacon.bufferedCount<int>(3);

      var buffer = <int>[];

      beacon
        ..subscribe((value) => buffer = value)
        ..add(1)
        ..add(2);

      BeaconScheduler.flush();

      expect(beacon.currentBuffer.value, equals([1, 2]));

      beacon
        ..add(3) // This should trigger the buffer to be set
        ..add(4);

      expect(beacon.currentBuffer.value, equals([4]));

      BeaconScheduler.flush();

      expect(buffer, equals([1, 2, 3]));
    });

    test('should reset', () {
      final beacon = Beacon.bufferedCount<int>(3);

      var buffer = <int>[];

      beacon
        ..subscribe((value) => buffer = value)
        ..add(1)
        ..add(2)
        ..add(3);

      expect(beacon.value, [1, 2, 3]);

      beacon.reset();

      expect(beacon.currentBuffer.value, equals([]));
      expect(beacon.value, equals([]));

      BeaconScheduler.flush();
      expect(buffer, equals([]));
    });

    test('should be safe to dispose twice', () {
      final beacon = Beacon.bufferedCount<int>(3);
      beacon.add(1);
      beacon.dispose();
      expect(beacon.dispose, returnsNormally);
      expect(beacon.isDisposed, isTrue);
    });
  });

  group('BufferedTimeBeacon', () {
    test('should buffer values over a time duration', () async {
      final beacon = Beacon.bufferedTime<int>(duration: k10ms * 5);

      var buffer = <int>[];

      beacon
        ..subscribe((value) => buffer = value)
        ..add(1)
        ..add(2);

      await delay(k10ms);

      expect(buffer, equals([]));

      await delay(k10ms * 5);

      expect(buffer, equals([1, 2]));
    });

    test('should cancel a pending timer when disposed', () async {
      final beacon = Beacon.bufferedTime<int>(duration: k10ms);

      beacon.add(1);
      beacon.dispose();

      await delay(k10ms * 2);

      expect(beacon.isDisposed, isTrue);
      expect(beacon.peek(), isEmpty);
    });

    test('should reset buffer after time duration', () async {
      final beacon = Beacon.bufferedTime<int>(duration: k10ms * 3);

      var buffer = <int>[];

      beacon
        ..subscribe((value) => buffer = value)
        ..add(1)
        ..add(2)
        ..add(3)
        ..add(4);

      await delay(k10ms * 4);

      expect(beacon.currentBuffer.value, equals([]));

      expect(buffer, equals([1, 2, 3, 4]));
    });

    test('should reset', () async {
      final beacon = Beacon.bufferedTime<int>(duration: k10ms * 3);

      var buffer = <int>[];

      beacon
        ..subscribe((value) => buffer = value)
        ..add(1)
        ..add(2)
        ..reset();

      await delay(k10ms * 4);

      expect(beacon.currentBuffer.value, equals([]));
      expect(buffer, equals([]));
    });

    test('should be safe to dispose twice', () {
      final beacon = Beacon.bufferedTime<int>(duration: k10ms);
      beacon.add(1);
      beacon.dispose();
      expect(beacon.dispose, returnsNormally);
      expect(beacon.isDisposed, isTrue);
    });
  });

  group('lazy currentBuffer', () {
    test('does not allocate currentBuffer beacon until accessed', () {
      final created = <String>[];
      BeaconObserver.instance = _CreateRecordingObserver(created);
      addTearDown(() => BeaconObserver.instance = null);

      final beacon = Beacon.bufferedCount<int>(2, name: 'buf');
      beacon
        ..add(1)
        ..add(2)
        ..add(3)
        ..reset()
        ..dispose();

      expect(created, equals(['buf']));
    });

    test(
      'syncs previously buffered values on first access and disposes cleanly',
      () {
        final beacon = Beacon.bufferedCount<int>(4, name: 'buf');
        beacon
          ..add(10)
          ..add(20);

        final current = beacon.currentBuffer;
        expect(current.value, equals([10, 20]));

        final seen = <List<int>>[];
        current.subscribe(
          (v) => seen.add(List.of(v)),
          startNow: false,
        );

        beacon.add(30);
        BeaconScheduler.flush();
        expect(
          seen,
          equals([
            [10, 20, 30],
          ]),
        );

        beacon.add(40);
        BeaconScheduler.flush();
        expect(beacon.value, equals([10, 20, 30, 40]));
        expect(
          seen,
          equals([
            [10, 20, 30],
            <int>[],
          ]),
        );

        beacon.dispose();
        expect(current.isDisposed, isTrue);
      },
    );

    test('returns an already-disposed currentBuffer if accessed after dispose',
        () {
      final beacon = Beacon.bufferedCount<int>(3, name: 'buf');
      beacon
        ..add(1)
        ..dispose();

      final current = beacon.currentBuffer;
      expect(current.isDisposed, isTrue);
      expect(current.peek(), isEmpty);
    });
  });
}

class _CreateRecordingObserver extends BeaconObserver {
  _CreateRecordingObserver(this.created);

  final List<String> created;

  @override
  void onCreate(ReadableBeacon<dynamic> beacon, bool isLazy) {
    created.add(beacon.name);
  }

  @override
  void onDispose(ReadableBeacon<dynamic> beacon) {}

  @override
  void onStopWatch(String label, BaseBeacon<dynamic> beacon) {}

  @override
  void onUpdate(ReadableBeacon<dynamic> beacon) {}

  @override
  void onWatch(String label, BaseBeacon<dynamic> beacon) {}
}
