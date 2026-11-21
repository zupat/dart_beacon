import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

void main() {
  test('should not send notification when doing untracked access', () {
    final age = Beacon.writable<int>(10);
    final name = Beacon.writable<String>('John');

    var callCount = 0;

    Beacon.effect(() {
      age.value;
      callCount++;
      Beacon.untracked(() {
        name.value;
        Beacon.untracked(() {
          name.value;
        });
      });
    });

    BeaconScheduler.flush();

    expect(callCount, equals(1));

    age.value = 20;
    BeaconScheduler.flush();
    expect(callCount, equals(2));

    name.value = 'Jane';
    BeaconScheduler.flush();
    expect(callCount, equals(2));
  });

  test(
      'should not track reads inside Beacon.untracked when a derived beacon '
      'is evaluated inside an outer Beacon.untracked', () {
    final tracked = Beacon.writable(1);
    final untrackedSource = Beacon.writable(10);
    var computes = 0;

    final derived = Beacon.derived(() {
      computes++;
      final a = tracked.value;
      var b = 0;
      Beacon.untracked(() {
        b = untrackedSource.value;
      });
      return a + b;
    });

    Beacon.untracked(() {
      expect(derived.value, 11);
    });

    expect(computes, 1);
    expect(untrackedSource.listenersCount, 0);

    untrackedSource.value = 20;
    expect(derived.value, 11);
    expect(computes, 1);

    tracked.value = 2;
    expect(derived.value, 22);
    expect(computes, 2);
  });
}
