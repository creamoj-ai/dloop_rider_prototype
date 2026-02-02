import 'package:flutter/material.dart';

class ZoneMapScreen extends StatelessWidget {
  const ZoneMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      body: Center(child: Text('Zone Map', style: TextStyle(color: Colors.white, fontSize: 24))),
    );
  }
}
