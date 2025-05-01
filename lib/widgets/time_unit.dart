import 'package:flutter/material.dart';

class TimeUnit extends StatelessWidget {
  final String value;
  final String label;
  final bool isNegative;

  const TimeUnit({
    super.key,
    required this.value,
    required this.label,
    required this.isNegative,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isNegative ? Colors.red.shade300 : Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
