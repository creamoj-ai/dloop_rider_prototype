import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() {
  runApp(const DloopRiderApp());
}

class DloopRiderApp extends StatelessWidget {
  const DloopRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'dloop rider',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF121214), Color(0xFF0D0D0F)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
