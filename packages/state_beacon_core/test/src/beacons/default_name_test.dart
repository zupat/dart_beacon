import 'package:state_beacon_core/state_beacon_core.dart';
import 'package:test/test.dart';

class _CustomWritable extends WritableBeacon<int> {
  _CustomWritable(int initialValue) : super(initialValue: initialValue);
}

class _CustomReadable extends ReadableBeacon<int> {
  _CustomReadable(int initialValue) : super(initialValue: initialValue);
}

class _CustomList extends ListBeacon<int> {
  _CustomList(super.initialValue);
}

class _CustomDebounced extends DebouncedBeacon<int> {
  _CustomDebounced(int initialValue) : super(initialValue: initialValue);
}

class _NameRecordingObserver extends LoggingObserver {
  final List<String> createdNames = [];

  @override
  void onCreate(ReadableBeacon<dynamic> beacon, bool lazy) {
    createdNames.add(beacon.name);
  }

  @override
  void onUpdate(ReadableBeacon<dynamic> beacon) {}

  @override
  void onWatch(String consumerName, BaseBeacon<dynamic> beacon) {}

  @override
  void onStopWatch(String consumerName, BaseBeacon<dynamic> beacon) {}

  @override
  void onDispose(ReadableBeacon<dynamic> beacon) {}
}

void main() {
  test('creators and direct constructors preserve expected default names', () {
    expect(Beacon.writable(0).name, 'Writable<int>');
    expect(Beacon.lazyWritable<int>().name, 'LazyWritable<int>');
    expect(Beacon.lazyWritable<int?>().name, 'LazyWritable<int?>');
    expect(
      Beacon.lazyWritable<int>(initialValue: 1).name,
      'LazyWritable<int>',
    );
    expect(WritableBeacon<int>().name, 'WritableBeacon<int>');
    expect(WritableBeacon<int>(initialValue: 1).name, 'WritableBeacon<int>');

    expect(Beacon.readable(0).name, 'Readable<int>');
    expect(ReadableBeacon<int>(initialValue: 0).name, 'ReadableBeacon<int>');

    expect(Beacon.debounced(0).name, 'DebouncedBeacon<int>');
    expect(Beacon.lazyDebounced<int?>().name, 'LazyDebouncedBeacon<int?>');
    expect(
      Beacon.lazyDebounced<int>(initialValue: 1).name,
      'LazyDebouncedBeacon<int>',
    );
    expect(DebouncedBeacon<int>().name, 'DebouncedBeacon<int>');

    expect(Beacon.throttled(0).name, 'ThrottledBeacon<int>');
    expect(Beacon.lazyThrottled<int?>().name, 'LazyThrottledBeacon<int?>');
    expect(ThrottledBeacon<int>().name, 'ThrottledBeacon<int>');

    expect(Beacon.filtered(0).name, 'FilteredBeacon<int>');
    expect(Beacon.lazyFiltered<int?>().name, 'LazyFilteredBeacon<int?>');
    expect(FilteredBeacon<int>().name, 'FilteredBeacon<int>');

    expect(Beacon.undoRedo(0).name, 'UndoRedoBeacon<int>');
    expect(Beacon.lazyUndoRedo<int?>().name, 'LazyUndoRedoBeacon<int?>');
    expect(UndoRedoBeacon<int>().name, 'UndoRedoBeacon<int>');

    expect(Beacon.timestamped(0).name, 'TimestampBeacon<int>');
    expect(Beacon.lazyTimestamped<int?>().name, 'LazyTimestampBeacon<int?>');
    expect(TimestampBeacon<int>().name, 'TimestampBeacon<int>');

    expect(Beacon.derived(() => 1).name, 'DerivedBeacon<int>');
    expect(Beacon.list<int>([]).name, 'ListBeacon<int>');
    expect(Beacon.hashSet<int>({}).name, 'SetBeacon<int>');
    expect(Beacon.hashMap<String, int>({}).name, 'MapBeacon<String,int>');
    expect(Beacon.bufferedCount<int>(2).name, 'BufferedCountBeacon<int>');
    expect(
      Beacon.bufferedTime<int>(duration: const Duration(seconds: 1)).name,
      'BufferedTimeBeacon<int>',
    );

    expect(Beacon.writable(0, name: 'custom').name, 'custom');
    expect(Beacon.lazyWritable<int>(name: 'customLazy').name, 'customLazy');
  });

  test('external subclasses preserve their own runtimeType name', () {
    expect(_CustomWritable(1).name, '_CustomWritable');
    expect(_CustomReadable(1).name, '_CustomReadable');
    expect(_CustomList([1]).name, '_CustomList');
    expect(_CustomDebounced(1).name, '_CustomDebounced');
  });

  test('BeaconObserver.onCreate sees the correct lazy default name', () {
    final observer = _NameRecordingObserver();
    BeaconObserver.instance = observer;
    addTearDown(() => BeaconObserver.instance = null);

    Beacon.writable(1);
    Beacon.lazyWritable<int?>();
    WritableBeacon<int>(initialValue: 1);
    _CustomWritable(1);

    expect(
      observer.createdNames,
      [
        'Writable<int>',
        'LazyWritable<int?>',
        'WritableBeacon<int>',
        '_CustomWritable',
      ],
    );
  });
}
