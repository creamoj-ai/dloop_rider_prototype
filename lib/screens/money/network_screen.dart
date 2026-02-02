import 'package:flutter/material.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      body: Center(child: Text('Network', style: TextStyle(color: Colors.white, fontSize: 24))),
    );
  }
}
