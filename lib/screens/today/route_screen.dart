import 'package:flutter/material.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      body: Center(child: Text('Route', style: TextStyle(color: Colors.white, fontSize: 24))),
    );
  }
}
