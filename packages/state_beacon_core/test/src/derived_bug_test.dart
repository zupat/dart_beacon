import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'derived misses ALL updates when a source changes between '
      'subscribe(startNow: false) and the first flush', () {
    final a = Beacon.writable<String>('a');
    final b = Beacon.writable<int>(0);
    final derived = Beacon.derived(() => '${a.value}-${b.value}');

    final seen = <String>[];
    derived.subscribe(seen.add, startNow: false); // what watch(context) does
    expect(derived.value, 'a-0'); // watch() also reads synchronously in build

    a.value = 'A'; // source changes BEFORE the first flush
    BeaconScheduler.flush();

    b.increment(); // this one comes AFTER a clean flush…
    BeaconScheduler.flush();

    expect(seen, ['A-0', 'A-1']); // FAILS: seen is [] — not late, dead
  });
}
