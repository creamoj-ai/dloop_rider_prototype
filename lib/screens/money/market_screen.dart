import 'package:flutter/material.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      body: Center(child: Text('Market', style: TextStyle(color: Colors.white, fontSize: 24))),
    );
  }
}
