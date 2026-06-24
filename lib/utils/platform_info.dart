/// Platform detection that works on both web and native.
///
/// Uses conditional imports to avoid importing dart:io on web.
export 'platform_info_stub.dart'
    if (dart.library.io) 'platform_info_native.dart';
