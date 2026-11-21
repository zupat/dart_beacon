import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

void main() {
  test(
    'flutterScheduler does not wedge _flushing if triggered before '
    'WidgetsFlutterBinding is initialized',
    () async {
      BeaconScheduler.useFlutterScheduler();

      final a = Beacon.writable(0);
      final b = Beacon.writable(0);
      var bCalls = 0;

      a.subscribe((_) {}, startNow: false);
      b.subscribe((_) => bCalls++, startNow: false);

      // Updating a beacon before WidgetsFlutterBinding.ensureInitialized()
      // throws because SchedulerBinding.instance is not initialized yet.
      expect(() => a.value = 1, throwsA(isA<FlutterError>()));

      // Once the binding is initialized (e.g., via runApp), subsequent updates
      // must flush normally instead of remaining permanently wedged.
      TestWidgetsFlutterBinding.ensureInitialized();

      b.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        bCalls,
        1,
        reason: '_flushing must not remain stuck true after '
            'SchedulerBinding.instance throws.',
      );

      a.dispose();
      b.dispose();
    },
  );
}
