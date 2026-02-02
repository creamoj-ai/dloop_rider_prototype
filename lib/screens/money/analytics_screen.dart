import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      body: Center(child: Text('Analytics', style: TextStyle(color: Colors.white, fontSize: 24))),
    );
  }
}
