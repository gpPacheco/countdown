import 'package:flutter/material.dart';

class AnimatedPauseButton extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onPressed;
  final AnimationController animationController;
  final Animation<double> scaleAnimation;

  const AnimatedPauseButton({
    super.key,
    required this.isPaused,
    required this.onPressed,
    required this.animationController,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: ScaleTransition(
          scale: scaleAnimation,
          child: Container(
            key: ValueKey<bool>(isPaused),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
