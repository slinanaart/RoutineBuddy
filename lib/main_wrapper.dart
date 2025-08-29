// Thin wrapper main_wrapper.dart delegating to the verified checkpoint implementation.
// This keeps the large, canonical implementation in `main_checkpoint7.dart` and
// provides a small, stable entrypoint for quick edits.

import 'main_checkpoint7.dart' as checkpoint;

void main() => checkpoint.main();
