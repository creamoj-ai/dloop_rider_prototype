import 'dart:io';

/// Native implementation using dart:io Platform.
String getPlatformName() => Platform.isAndroid ? 'android' : 'ios';
