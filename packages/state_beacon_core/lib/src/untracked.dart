part of 'producer.dart';

/// Runs a function untracked.
void doUntracked(VoidCallback fn) {
  final prevConsumer = currentConsumer;
  if (prevConsumer == null) {
    fn();
    return;
  }

  currentConsumer = null;

  try {
    fn();
  } finally {
    currentConsumer = prevConsumer;
  }
}
