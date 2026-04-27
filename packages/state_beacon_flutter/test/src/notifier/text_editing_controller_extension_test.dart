import 'package:flutter_test/flutter_test.dart';
import 'package:state_beacon_flutter/state_beacon_flutter.dart';

void main() {
  test('should sync with WritableBeacon<String>', () {
    final beacon = Beacon.writable('initial');
    final controller = beacon.getTextEditingController();

    expect(controller.text, 'initial');

    beacon.set('new value');
    expect(controller.text, 'new value');

    controller.text = 'from controller';
    expect(beacon.peek(), 'from controller');
  });

  test('should return same controller for same beacon', () {
    final beacon = Beacon.writable('initial');
    final controller1 = beacon.getTextEditingController();
    final controller2 = beacon.getTextEditingController();

    expect(controller1, controller2);
  });

  test('should remove from cache when controller is disposed', () {
    final beacon = Beacon.writable('initial');
    final controller1 = beacon.getTextEditingController();

    controller1.dispose();

    final controller2 = beacon.getTextEditingController();
    expect(controller1, isNot(controller2));
  });

  test('should dispose controller when beacon is disposed', () {
    final beacon = Beacon.writable('initial');
    final controller = beacon.getTextEditingController();

    beacon.dispose();

    // In Flutter, checking if a controller is disposed is usually done by
    // checking if adding a listener throws an error.
    expect(() => controller.addListener(() {}), throwsFlutterError);
  });
}
