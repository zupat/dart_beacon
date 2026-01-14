part of 'widgets.dart';

// This animates the slide offsets for both currency selectors
// when the currencies are swapped.
// It can be global since it lives for the lifetime of the app.

const _kSlideDuration = Duration(milliseconds: 300);
const _kSlideInterval = Duration(milliseconds: 15);

final _slideOffsets = Beacon.progress(
  interval: _kSlideInterval,
  totalDuration: _kSlideDuration,
  manualStart: true,
  initialValue: (0.0, 0.0),
  onProgress: (progress) {
    // Move from sides to center: -1.0 -> 0.0 and 1.0 -> 0.0
    final leftOffset = -1.0 + (progress * 1.0);
    final rightOffset = 1.0 - (progress * 1.0);
    return (leftOffset, rightOffset);
  },
);

void _startAnimation() {
  // Restart the slide animation from the beginning.
  _slideOffsets.start();
}
