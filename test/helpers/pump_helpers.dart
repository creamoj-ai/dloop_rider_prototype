import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wraps a widget in ProviderScope + MaterialApp (dark theme).
/// Use for widgets that render INSIDE a Scaffold.
Widget testApp(
  Widget child, {
  List<Override> overrides = const [],
}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    ),
  );
}

/// Wraps a full screen (with its own Scaffold) in ProviderScope + MaterialApp.
Widget testScreen(
  Widget screen, {
  List<Override> overrides = const [],
}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: screen,
    ),
  );
}
