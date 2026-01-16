part of 'widgets.dart';

// This animates the slide offsets for both currency selectors
// when the currencies are swapped.
// It can be global since it lives for the lifetime of the app.

const _kSlideDuration = Duration(milliseconds: 150);
const _kSlideInterval = Duration(milliseconds: 150);

final _slideOffsets = Beacon.progress(
  interval: _kSlideInterval,
  totalDuration: _kSlideDuration,
  initialValue: (0.0, 0.0),
  onStart: () => (-0.1, 0.1),
  onDone: () => (0.0, 0.0),
);

void _startAnimation() {
  // Restart the slide animation from the beginning.
  _slideOffsets.start();
}
