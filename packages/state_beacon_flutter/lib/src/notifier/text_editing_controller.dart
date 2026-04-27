import 'package:flutter/widgets.dart';
import 'package:state_beacon_core/state_beacon_core.dart';

final Map<int, _TextEditingController> _controllerCache = {};

/// This is a wrapper around a [TextEditingController] that
/// allows you to hook into the controller's lifecycle.
class _TextEditingController extends TextEditingController {
  VoidCallback? disposeCallback;
  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    disposeCallback?.call();
    super.dispose();
  }
}

/// A beacon that wraps a [TextEditingController].
class TextEditingBeacon extends WritableBeacon<TextEditingValue> {
  /// @macro [TextEditingBeacon]
  TextEditingBeacon({String? text, BeaconGroup? group, super.name})
      : super(
          initialValue: text == null
              ? TextEditingValue.empty
              : TextEditingValue(text: text),
        ) {
    group?.add(this);
    var syncing = false;

    void safeWrite(VoidCallback fn) {
      if (syncing) return;
      syncing = true;
      try {
        fn();
      } finally {
        syncing = false;
      }
    }

    _controller.addListener(() {
      safeWrite(() => set(_controller.value, force: true));
    });

    subscribeSynchronously(
      (v) => safeWrite(() => _controller.value = v),
    );

    _controller.disposeCallback = dispose;
  }

  late final _controller = _TextEditingController();

  /// The current [TextEditingController].
  TextEditingController get controller => _controller;

  /// The current string the user is editing.
  String get text => _controller.text;

  set text(String newText) {
    _controller.text = newText;
  }

  /// The currently selected [text].
  ///
  /// If the selection is collapsed, then this property gives
  /// the offset of the cursor within the text.
  TextSelection get selection => _controller.selection;

  /// Alias for controller.clear()
  void clear() => _controller.clear();

  @override
  void dispose() {
    // we are being disposed so controller doesn't
    // need to call our dispose method.
    _controller.disposeCallback = null;

    _controller.dispose();
    super.dispose();
  }
}

/// Extensions for [WritableBeacon] to work with [TextEditingController].
extension WritableBeaconTextEditingController on WritableBeacon<String> {
  /// Returns a [TextEditingController] that is synced with this beacon.
  TextEditingController getTextEditingController() {
    final key = hashCode;
    final cached = _controllerCache[key];

    if (cached != null) return cached;

    final controller = _TextEditingController();
    _controllerCache[key] = controller;

    var syncing = false;

    void safeWrite(VoidCallback fn) {
      if (syncing) return;
      syncing = true;
      try {
        fn();
      } finally {
        syncing = false;
      }
    }

    controller
      ..text = peek()
      ..addListener(() {
        safeWrite(() => set(controller.text));
      });

    final unsub = subscribeSynchronously(
      (v) => safeWrite(() => controller.text = v),
    );

    controller.disposeCallback = () {
      unsub();
      _controllerCache.remove(key);
    };

    onDispose(controller.dispose);

    return controller;
  }
}
