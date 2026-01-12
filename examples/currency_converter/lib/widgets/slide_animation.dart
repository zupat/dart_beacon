part of 'widgets.dart';

// This animates the slide offsets for both currency selectors
// when the currencies are swapped.
// It can be global since it lives for the lifetime of the app.
final _slideOffsets = Beacon.writable((0.0, 0.0));
Timer? _timer;
void _startAnimation() {
  _timer?.cancel();
  // Start from both ends: left currency from -1.0, right currency from 1.0
  _slideOffsets.value = (-1.0, 1.0);
  var elapsed = 0;
  const duration = 300;
  const interval = 16;
  _timer = Timer.periodic(const Duration(milliseconds: interval), (timer) {
    elapsed += interval;
    final progress = (elapsed / duration).clamp(0, 1);
    // Move from sides to center: -1.0 -> 0.0 and 1.0 -> 0.0
    final leftOffset = -1.0 + (progress * 1.0);
    final rightOffset = 1.0 - (progress * 1.0);
    _slideOffsets.value = (leftOffset, rightOffset);
    if (progress >= 1) {
      timer.cancel();
      _slideOffsets.value = (0.0, 0.0);
    }
  });
}
