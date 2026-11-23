// ignore_for_file: strict_raw_type, inference_failure_on_instance_creation

import 'dart:async';

import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

Future<int> testFuture(bool crash) async {
  if (crash) {
    throw Exception('error');
  }
  return 1;
}

void main() {
  test('should return AsyncData when future is successful', () async {
    final result = await AsyncValue.tryCatch(() => testFuture(false));
    expect(result, isA<AsyncData>());
  });

  test('should return AsyncError when future throws', () async {
    final result = await AsyncValue.tryCatch(() => testFuture(true));
    expect(result, isA<AsyncError>());
  });

  test('should set the beacon supplied', () async {
    final beacon = Beacon.writable<AsyncValue<int>>(AsyncData(0));

    final beaconStream = beacon.stream;

    expect(
      beaconStream,
      emitsInOrder(
        [
          AsyncData(0),
          AsyncLoading<int>(),
          AsyncData(1),
          // start errorResult
          AsyncLoading<int>(),
          isA<AsyncError>(),
        ],
      ),
    );

    BeaconScheduler.flush();

    final successResult = await AsyncValue.tryCatch(
      () => testFuture(false),
      beacon: beacon,
    );

    BeaconScheduler.flush();

    expect(successResult, isA<AsyncData>());

    final errorResult = await AsyncValue.tryCatch(
      () => testFuture(true),
      beacon: beacon,
    );

    BeaconScheduler.flush();

    expect(errorResult, isA<AsyncError>());
  });

  test('should set optimistic result while loading', () async {
    final beacon = Beacon.writable<AsyncValue<int>>(AsyncData(0));

    final beaconStream = beacon.stream;

    expect(
      beaconStream,
      emitsInOrder(
        [
          AsyncData(0),
          AsyncData(1), // optimistic result

          // start errorResult
          AsyncData(2), // optimistic result
          isA<AsyncError>(),
        ],
      ),
    );

    BeaconScheduler.flush();

    final successResult = await AsyncValue.tryCatch(
      () => testFuture(false),
      beacon: beacon,
      optimisticResult: 1,
    );

    BeaconScheduler.flush();

    expect(successResult, isA<AsyncData>());

    final errorResult = await AsyncValue.tryCatch(
      () => testFuture(true),
      beacon: beacon,
      optimisticResult: 2,
    );

    BeaconScheduler.flush();

    expect(errorResult, isA<AsyncError>());
  });

  test('should return correct values for asError', () {
    final loading = AsyncLoading();
    expect(loading.asError, null);

    final idle = AsyncIdle();
    expect(idle.asError, null);

    final error = AsyncError('error', StackTrace.current);
    expect(error.asError, error);

    final data = AsyncData(1);
    expect(data.asError, null);
  });

  test('should share the same hashCode with sister instances', () {
    final data = AsyncData(1);
    final data2 = AsyncData(1);

    expect(data.hashCode, data2.hashCode);

    final load = AsyncLoading<int>();
    final load2 = AsyncLoading<int>();

    expect(load, load2);
    expect(load.hashCode, load2.hashCode);

    final stack = StackTrace.current;
    final error = AsyncError<int>('error', stack);
    final error2 = AsyncError<int>('error', stack);
    final error3 = AsyncError<int>('error');

    expect(error, error2);
    expect(error == error3, false);
    expect(error.hashCode, error2.hashCode);

    final idle = AsyncIdle<int>();
    final idle2 = AsyncIdle<int>();

    expect(idle, idle2);
    expect(idle.hashCode, idle2.hashCode);
  });

  test('should set lastData and correct status', () {
    final loading = AsyncLoading();

    expect(loading.lastData, null);
    expect(loading.unwrapOrNull(), null);
    expect(loading.isIdleOrLoading, true);
    expect(loading.isLoading, true);

    loading.setLastData(1);

    expect(loading.lastData, 1);
    expect(loading.unwrapOrNull(), null);

    final idle = AsyncIdle();

    expect(idle.lastData, null);
    expect(idle.unwrapOrNull(), null);
    expect(idle.isIdle, true);
    expect(idle.unwrap, throwsException);
    expect(idle.isData, false);

    idle.setLastData(1);

    expect(idle.lastData, 1);
    expect(idle.unwrapOrNull(), null);
    expect(idle.isError, false);
    expect(idle.isIdleOrLoading, true);

    final error = AsyncError('error', StackTrace.current);

    expect(error.lastData, null);
    expect(error.unwrapOrNull(), null);
    expect(error.isLoading, false);
    expect(error.isIdleOrLoading, false);

    error.setLastData(1);

    expect(error.lastData, 1);
    expect(error.unwrapOrNull(), null);
    expect(error.isIdle, false);

    final data = AsyncData(1);

    expect(data.lastData, 1);
    expect(data.unwrapOrNull(), 1);
    expect(data.isLoading, false);

    // can't set lastData on AsyncData
    data.setLastData(2);

    expect(data.lastData, 1);
    expect(data.unwrapOrNull(), 1);
    expect(data.isLoading, false);
  });

  test('tryCatch should not throw if beacon is disposed while pending',
      () async {
    final beaconSuccess = Beacon.writable<AsyncValue<int>>(AsyncIdle());
    final completerSuccess = Completer<int>();
    final futureSuccess = AsyncValue.tryCatch(
      () => completerSuccess.future,
      beacon: beaconSuccess,
    );

    beaconSuccess.dispose();
    completerSuccess.complete(42);

    final resultSuccess = await futureSuccess;
    expect(resultSuccess, AsyncData(42));

    final beaconError = Beacon.writable<AsyncValue<int>>(AsyncIdle());
    final completerError = Completer<int>();
    final futureError = AsyncValue.tryCatch(
      () => completerError.future,
      beacon: beaconError,
    );

    beaconError.dispose();
    completerError.completeError(Exception('boom'));

    final resultError = await futureError;
    expect(resultError, isA<AsyncError<int>>());
  });

  test('hashCode does not call toString and matches across covariant types',
      () {
    final obj1 = _NoToStringObject(42);
    final obj2 = _NoToStringObject(42);
    final data1 = AsyncData(obj1);
    final data2 = AsyncData(obj2);

    expect(data1, equals(data2));
    expect(data1.hashCode, equals(data2.hashCode));
    expect(obj1.toStringCalls, 0);
    expect(obj2.toStringCalls, 0);

    final stack = StackTrace.current;
    final err1 = AsyncError<int>(obj1, stack);
    final err2 = AsyncError<int>(obj2, stack);

    expect(err1, equals(err2));
    expect(err1.hashCode, equals(err2.hashCode));
    expect(obj1.toStringCalls, 0);
    expect(obj2.toStringCalls, 0);

    final numData = AsyncData<num>(1);
    final intData = AsyncData<int>(1);
    expect(numData == intData, isTrue);
    expect(numData.hashCode, equals(intData.hashCode));

    expect(AsyncLoading<int>().hashCode, isNot(AsyncIdle<int>().hashCode));
  });
}

class _NoToStringObject {
  _NoToStringObject(this.id);

  final int id;
  int toStringCalls = 0;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is _NoToStringObject && other.id == id;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => id.hashCode;

  @override
  String toString() {
    toStringCalls++;
    return '_NoToStringObject($id)';
  }
}
