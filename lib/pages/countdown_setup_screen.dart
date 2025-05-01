import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/countdown_data.dart';
import '../widgets/time_input_box.dart';

class CountdownSetupScreen extends StatefulWidget {
  const CountdownSetupScreen({super.key});

  @override
  State<CountdownSetupScreen> createState() => _CountdownSetupScreenState();
}

class _CountdownSetupScreenState extends State<CountdownSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _years = 0;
  int _months = 0;
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createCountdown() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for the countdown'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_years == 0 &&
        _months == 0 &&
        _days == 0 &&
        _hours == 0 &&
        _minutes == 0 &&
        _seconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a time for the countdown'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final targetDate = now.add(Duration(
      days: _years * 365 + _months * 30 + _days,
      hours: _hours,
      minutes: _minutes,
      seconds: _seconds,
    ));

    final countdownData = CountdownData(
      name: _nameController.text,
      targetDate: targetDate,
      lastUpdated: now,
    );

    Navigator.pop(context, countdownData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Countdown'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Countdown Name:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Vacation, Birthday, etc.',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Set Time:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTimeInputs(),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      onPressed: _createCountdown,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'CREATE COUNTDOWN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TimeInputBox(
                label: 'Years',
                value: _years,
                onChanged: (value) => setState(() => _years = value),
                maxValue: null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimeInputBox(
                label: 'Months',
                value: _months,
                onChanged: (value) => setState(() => _months = value),
                maxValue: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TimeInputBox(
                label: 'Days',
                value: _days,
                onChanged: (value) => setState(() => _days = value),
                maxValue: 30,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimeInputBox(
                label: 'Hours',
                value: _hours,
                onChanged: (value) => setState(() => _hours = value),
                maxValue: 23,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TimeInputBox(
                label: 'Minutes',
                value: _minutes,
                onChanged: (value) => setState(() => _minutes = value),
                maxValue: 59,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TimeInputBox(
                label: 'Seconds',
                value: _seconds,
                onChanged: (value) => setState(() => _seconds = value),
                maxValue: 59,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
