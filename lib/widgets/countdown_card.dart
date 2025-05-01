import 'package:flutter/material.dart';
import '../models/countdown_data.dart';
import 'animated_pause_button.dart';

class CountdownCard extends StatelessWidget {
  final CountdownData countdown;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback onTogglePause;

  const CountdownCard({
    super.key,
    required this.countdown,
    required this.onDelete,
    required this.onTap,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final duration = countdown.getRemainingDuration();
    final isNegative = duration.isNegative;

    String timeText;
    if (isNegative) {
      final positiveDuration = duration.abs();
      final days = positiveDuration.inDays;
      final hours = positiveDuration.inHours.remainder(24);
      final minutes = positiveDuration.inMinutes.remainder(60);

      timeText = "Exceeded by: ${days}d ${hours}h ${minutes}m";
    } else {
      final days = duration.inDays;
      final hours = duration.inHours.remainder(24);
      final minutes = duration.inMinutes.remainder(60);

      timeText = "Remaining: ${days}d ${hours}h ${minutes}m";
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          countdown.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          timeText,
          style: TextStyle(
            color: isNegative ? Colors.red.shade300 : Colors.white70,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: IconButton(
                key: ValueKey<bool>(countdown.isPaused),
                icon: Icon(
                  countdown.isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.white,
                ),
                onPressed: onTogglePause,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
