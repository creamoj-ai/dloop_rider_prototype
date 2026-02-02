import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0F),
      body: Center(child: Text('Transactions', style: TextStyle(color: Colors.white, fontSize: 24))),
    );
  }
}
