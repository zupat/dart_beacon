import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

void main() {
  test('should be synced with internal TextEditingController', () async {
    final beacon = TextEditingBeacon();
    final controller = beacon.controller;

    expect(beacon.peek(), TextEditingValue.empty);
    expect(beacon.text, '');
    expect(controller.text, '');

    beacon.text = '1';

    expect(beacon.text, '1');
    expect(controller.text, '1');

    beacon.text = '2';

    expect(beacon.text, '2');
    expect(controller.text, '2');

    beacon.clear();

    expect(beacon.text, '');
    expect(controller.text, '');

    controller.text = '3';

    expect(beacon.text, '3');
    expect(controller.text, '3');

    controller.clear();

    expect(beacon.text, '');
    expect(controller.text, '');

    controller.dispose();

    expect(beacon.isDisposed, true);
  });

  test('should reflect changes to the controller', () async {
    final beacon = TextEditingBeacon(text: '1');
    final controller = beacon.controller;

    expect(beacon.text, '1');
    expect(controller.text, '1');

    expect(beacon.selection, controller.selection);

    beacon.value = const TextEditingValue(text: 'hello');
    expect(controller.text, 'hello');

    beacon.text = 'goodbye';
    expect(controller.text, 'goodbye');
  });

  test('should add beacon to group provided', () {
    final group = BeaconGroup();
    final beacon = group.textEditing(text: '1');

    expect(group.beacons.length, 1);
    expect(group.beacons.first, beacon);

    group.disposeAll();

    expect(group.beacons.isEmpty, true);

    expect(beacon.isDisposed, true);
  });

  test('should call dispose once', () {
    final beacon = TextEditingBeacon(text: '1');
    var called = 0;

    beacon
      ..onDispose(() => called++)
      ..dispose();

    expect(called, 1);
  });

  test(
    'should stay in sync when a controller listener modifies text re-entrantly',
    () {
      final beacon = TextEditingBeacon();
      beacon.controller.addListener(() {
        if (beacon.controller.text == 'bad') {
          beacon.controller.text = 'good';
        }
      });

      beacon.value = const TextEditingValue(text: 'bad');

      expect(beacon.controller.text, 'good');
      expect(
        beacon.value.text,
        'good',
        reason: 'Re-entrant controller listener updates must sync back to the '
            'beacon.',
      );

      beacon.dispose();
    },
  );

  test(
    'BeaconGroup.onCreate hook should see initial controller text and '
    'preserve mutations',
    () {
      final group = BeaconGroup();
      String? controllerTextInHook;

      group.onCreate((b) {
        if (b is TextEditingBeacon) {
          controllerTextInHook = b.controller.text;
          b.text = 'updated-in-hook';
        }
      });

      final beacon = group.textEditing(text: 'initial');

      expect(
        controllerTextInHook,
        'initial',
        reason: 'Controller must be initialized with initial text before '
            'group.add(this) notifies onCreate hooks.',
      );
      expect(beacon.text, 'updated-in-hook');
      expect(beacon.controller.text, 'updated-in-hook');

      group.disposeAll();
    },
  );
}
