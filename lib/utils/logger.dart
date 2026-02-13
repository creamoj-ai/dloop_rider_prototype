import 'package:flutter/foundation.dart';

/// Debug-only logger. Prints nothing in release builds.
void dlog(Object? message) {
  if (kDebugMode) {
    debugPrint(message?.toString() ?? 'null');
  }
}
