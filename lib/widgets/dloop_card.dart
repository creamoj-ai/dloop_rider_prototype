import 'package:flutter/material.dart';

class DloopCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final VoidCallback? onTap;

  const DloopCard({
    super.key,
    required this.child,
    this.padding = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
