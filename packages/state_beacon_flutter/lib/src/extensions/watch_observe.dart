// ignore_for_file: invalid_use_of_protected_member, use_if_null_to_convert_nulls_to_bools, lines_longer_than_80_chars, deprecated_member_use

part of 'extensions.dart';

// ignore: public_member_api_docs
typedef ObserverCallback<T> = void Function(T prev, T next);

// coverage:ignore-start
// requires a manual GC trigger to test
final Finalizer<void Function()> _finalizer = Finalizer((fn) => fn());
// coverage:ignore-end

/// The latest `observe` callback for each widget and beacon.
///
/// Keyed by widget [BuildContext] (outer [Expando]) and beacon identity
/// (inner [Expando]) so rebuilding a widget replaces its callback without
/// creating a second subscription, while keeping no strong GC root from the
/// beacon or [_finalizer] to `context` (even when the callback captures
/// `context`).
final _observerCallbacks = Expando<Expando<VoidCallback>>();

/// @macro WidgetUtils
extension WidgetUtils<T> on BaseBeacon<T> {
  /// Watches a beacon and triggers a widget
  /// rebuild when its value changes.
  ///
  /// Note: must be called within a widget's build method.
  ///
  /// Conditional watching is not supported: once a widget starts watching a
  /// beacon, it will not stop until the beacon is disposed or the widget is
  /// unmounted. If the watched beacon can change between builds, give the
  /// widget a key tied to the beacon's identity (e.g. `ValueKey(item.id)`).
  ///
  /// Usage:
  /// ```dart
  /// final counter = Beacon.writable(0);
  ///
  /// class Counter extends StatelessWidget {
  ///  const Counter({super.key});
  ///
  ///  @override
  ///  Widget build(BuildContext context) {
  ///    final count = counter.watch(context);
  ///    return Text(count.toString());
  ///  }
  ///}
  /// ```
  T watch(BuildContext context) {
    final key = identityHashCode(context);

    _watchOrObserve(
      key,
      context,
    );

    return peek();
  }

  /// Observes the state of a beacon and triggers a callback with the current state.
  ///
  /// The callback is provided with the current state of the beacon and a BuildContext.
  /// This can be used to show snackbars or other side effects.
  ///
  /// Conditional observing is not supported: once a widget starts observing
  /// a beacon, the callback keeps firing until the beacon is disposed or the
  /// widget is unmounted (see [watch]).
  ///
  /// Usage:
  /// ```dart
  /// final exampleBeacon = Beacon.writable("Initial State");
  ///
  /// class ExampleWidget extends StatelessWidget {
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     context.observe(exampleBeacon, (state, context) {
  ///       ScaffoldMessenger.of(context).showSnackBar(
  ///         SnackBar(content: Text(state)),
  ///       );
  ///     });
  ///     return Container();
  ///   }
  /// }
  /// ```
  void observe(BuildContext context, ObserverCallback<T> callback) {
    final key = Object.hash(
      identityHashCode(context),
      'isObserving', // create 1 subscription for each widget
    );

    _watchOrObserve(
      key,
      context,
      callback: () {
        final prev = previousValue;
        if (prev is T) {
          callback(prev, peek());
        }
      },
    );
  }

  void _watchOrObserve(
    int key,
    BuildContext context, {
    VoidCallback? callback,
  }) {
    final isObserving = callback != null;

    // Rebuilding with a new `observe` callback must replace the old one, even
    // though the beacon subscription itself already exists.
    if (isObserving) {
      (_observerCallbacks[context] ??= Expando<VoidCallback>())[this] =
          callback;
    }

    if ($$widgetSubscribers$$.contains(key)) {
      return;
    }

    $$widgetSubscribers$$.add(key);

    final elementRef = WeakReference(context as Element);
    final detachToken = Object();
    late VoidCallback unsub;

    void handleNewValue(T value) {
      final element = elementRef.target;
      if (element?.mounted == true) {
        if (isObserving) {
          _observerCallbacks[element!]?[this]?.call();
        } else {
          element!.markNeedsBuild();
        }
      } else {
        unsub();
        _finalizer.detach(detachToken);
        $$widgetSubscribers$$.remove(key);
        if (element != null) {
          _observerCallbacks[element]?[this] = null;
        }
      }
    }

    unsub = subscribe(
      handleNewValue,
      startNow: false,
    );

    // coverage:ignore-start
    // clean up if the widget is disposed
    // and value is never modified again
    _finalizer.attach(
      context,
      () {
        unsub();
        $$widgetSubscribers$$.remove(key);
      },
      detach: detachToken,
    );
    // coverage:ignore-end
  }
}
