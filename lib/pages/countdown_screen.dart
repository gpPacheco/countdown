import 'package:flutter/material.dart';
import '../models/countdown_data.dart';
import '../widgets/animated_pause_button.dart';
import '../widgets/time_unit.dart';
import 'dart:async';

class CountdownScreen extends StatefulWidget {
  final CountdownData countdown;
  final VoidCallback onTogglePause;

  const CountdownScreen({
    super.key,
    required this.countdown,
    required this.onTogglePause,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  bool _isNegative = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _startTimer();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateTimeRemaining();
      }
    });
  }

  void _calculateTimeRemaining() {
    final duration = widget.countdown.getRemainingDuration();

    setState(() {
      if (duration.isNegative) {
        _isNegative = true;
        final positiveDuration = duration.abs();
        _days = positiveDuration.inDays;
        _hours = positiveDuration.inHours.remainder(24);
        _minutes = positiveDuration.inMinutes.remainder(60);
        _seconds = positiveDuration.inSeconds.remainder(60);
      } else {
        _isNegative = false;
        _days = duration.inDays;
        _hours = duration.inHours.remainder(24);
        _minutes = duration.inMinutes.remainder(60);
        _seconds = duration.inSeconds.remainder(60);
      }
    });
  }

  void _togglePause() {
    _animationController.forward().then((_) {
      widget.onTogglePause();
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.blueGrey.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'COUNTDOWN',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ),
                    AnimatedPauseButton(
                      isPaused: widget.countdown.isPaused,
                      onPressed: _togglePause,
                      animationController: _animationController,
                      scaleAnimation: _scaleAnimation,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.countdown.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 50),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TimeUnit(
                              value: _days.toString().padLeft(2, '0'),
                              label: 'DAY',
                              isNegative: _isNegative,
                            ),
                            const SizedBox(width: 20),
                            TimeUnit(
                              value: _hours.toString().padLeft(2, '0'),
                              label: 'HRS',
                              isNegative: _isNegative,
                            ),
                            const SizedBox(width: 20),
                            TimeUnit(
                              value: _minutes.toString().padLeft(2, '0'),
                              label: 'MIN',
                              isNegative: _isNegative,
                            ),
                            const SizedBox(width: 20),
                            TimeUnit(
                              value: _seconds.toString().padLeft(2, '0'),
                              label: 'SEC',
                              isNegative: _isNegative,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        if (_isNegative)
                          Text(
                            'TIME EXCEEDED',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (widget.countdown.isPaused)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'PAUSED',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.amber.shade300,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
