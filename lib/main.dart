import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const CountdownListScreen(),
    );
  }
}

class CountdownData {
  final String id;
  final String name;
  DateTime targetDate;
  bool isPaused;
  DateTime? pausedAt;
  Duration? remainingDuration;
  DateTime lastUpdated;

  CountdownData({
    required this.name,
    required this.targetDate,
    this.isPaused = false,
    this.pausedAt,
    this.remainingDuration,
    String? id,
    DateTime? lastUpdated,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        lastUpdated = lastUpdated ?? DateTime.now();

  void togglePause() {
    if (isPaused) {
      if (pausedAt != null) {
        final pauseDuration = DateTime.now().difference(pausedAt!);
        targetDate = targetDate.add(pauseDuration);
      }
      pausedAt = null;
    } else {
      pausedAt = DateTime.now();
      remainingDuration = targetDate.difference(pausedAt!);
    }
    isPaused = !isPaused;
    lastUpdated = DateTime.now();
  }

  Duration getRemainingDuration() {
    if (isPaused && remainingDuration != null) {
      return remainingDuration!;
    }
    return targetDate.difference(DateTime.now());
  }

  void updateAfterRestart() {
    if (!isPaused) {
      final now = DateTime.now();
      final elapsedSinceLastUpdate = now.difference(lastUpdated);
      lastUpdated = now;
      targetDate = targetDate.subtract(elapsedSinceLastUpdate);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetDate': targetDate.toIso8601String(),
      'isPaused': isPaused,
      'pausedAt': pausedAt?.toIso8601String(),
      'remainingDuration': remainingDuration?.inSeconds,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory CountdownData.fromJson(Map<String, dynamic> json) {
    return CountdownData(
      id: json['id'],
      name: json['name'],
      targetDate: DateTime.parse(json['targetDate']),
      isPaused: json['isPaused'],
      pausedAt:
          json['pausedAt'] != null ? DateTime.parse(json['pausedAt']) : null,
      remainingDuration: json['remainingDuration'] != null
          ? Duration(seconds: json['remainingDuration'])
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }
}

class CountdownListScreen extends StatefulWidget {
  const CountdownListScreen({super.key});

  @override
  State<CountdownListScreen> createState() => _CountdownListScreenState();
}

class _CountdownListScreenState extends State<CountdownListScreen>
    with WidgetsBindingObserver {
  List<CountdownData> _countdowns = [];
  Timer? _refreshTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCountdowns();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    Timer.periodic(const Duration(seconds: 30), (_) {
      _saveCountdowns();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _saveCountdowns();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveCountdowns();
    } else if (state == AppLifecycleState.resumed) {
      _loadCountdowns();
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/countdowns.json');
  }

  Future<void> _loadCountdowns() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);

        setState(() {
          _countdowns =
              jsonList.map((json) => CountdownData.fromJson(json)).toList();
          for (var countdown in _countdowns) {
            countdown.updateAfterRestart();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading countdowns: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCountdowns() async {
    try {
      final file = await _localFile;
      final jsonList =
          _countdowns.map((countdown) => countdown.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving countdowns: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('COUNTDOWN TIMERS'),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _countdowns.isEmpty
                ? const Center(
                    child: Text(
                      'No countdowns added.\nTap + to add a new countdown.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _countdowns.length,
                    itemBuilder: (context, index) {
                      final countdown = _countdowns[index];
                      return _buildCountdownCard(countdown, index);
                    },
                  ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HolidayCalendarScreen(),
                ),
              );
            },
            child: const Icon(Icons.calendar_today),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _navigateToCreateCountdown(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard(CountdownData countdown, int index) {
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
            _buildAnimatedPauseButton(countdown),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _countdowns.removeAt(index);
                  _saveCountdowns();
                });
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CountdownScreen(
                countdown: countdown,
                onTogglePause: () {
                  setState(() {
                    countdown.togglePause();
                    _saveCountdowns();
                  });
                },
              ),
            ),
          ).then((_) {
            setState(() {});
            _saveCountdowns();
          });
        },
      ),
    );
  }

  Widget _buildAnimatedPauseButton(CountdownData countdown) {
    return AnimatedSwitcher(
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
        onPressed: () {
          setState(() {
            countdown.togglePause();
            _saveCountdowns();
          });
        },
      ),
    );
  }

  Future<void> _navigateToCreateCountdown(BuildContext context) async {
    final result = await Navigator.push<CountdownData?>(
      context,
      MaterialPageRoute(
        builder: (context) => const CountdownSetupScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _countdowns.add(result);
        _saveCountdowns();
      });
    }
  }
}

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
              child: _buildTimeInputBox(
                label: 'Years',
                value: _years,
                onChanged: (value) => setState(() => _years = value),
                maxValue: null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTimeInputBox(
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
              child: _buildTimeInputBox(
                label: 'Days',
                value: _days,
                onChanged: (value) => setState(() => _days = value),
                maxValue: 30,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTimeInputBox(
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
              child: _buildTimeInputBox(
                label: 'Minutes',
                value: _minutes,
                onChanged: (value) => setState(() => _minutes = value),
                maxValue: 59,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTimeInputBox(
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

  Widget _buildTimeInputBox({
    required String label,
    required int value,
    required Function(int) onChanged,
    int? maxValue,
  }) {
    final TextEditingController controller =
        TextEditingController(text: value.toString());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > 0
                    ? () {
                        onChanged(value - 1);
                      }
                    : null,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (text) {
                    final newValue = int.tryParse(text) ?? 0;
                    if (maxValue != null && newValue > maxValue) {
                      controller.text = maxValue.toString();
                      onChanged(maxValue);
                    } else {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: maxValue == null || value < maxValue
                    ? () {
                        onChanged(value + 1);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                    Expanded(
                      child: const Center(
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
                    _buildAnimatedPauseButton(),
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
                            _buildTimeUnit(
                                _days.toString().padLeft(2, '0'), 'DAY'),
                            const SizedBox(width: 20),
                            _buildTimeUnit(
                                _hours.toString().padLeft(2, '0'), 'HRS'),
                            const SizedBox(width: 20),
                            _buildTimeUnit(
                                _minutes.toString().padLeft(2, '0'), 'MIN'),
                            const SizedBox(width: 20),
                            _buildTimeUnit(
                                _seconds.toString().padLeft(2, '0'), 'SEC'),
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

  Widget _buildAnimatedPauseButton() {
    return GestureDetector(
      onTap: _togglePause,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            key: ValueKey<bool>(widget.countdown.isPaused),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              widget.countdown.isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _isNegative ? Colors.red.shade300 : Colors.white,
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

class Holiday {
  final String name;
  final String type;

  Holiday({required this.name, required this.type});
}

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  _HolidayCalendarScreenState createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Holiday>> _holidays = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchHolidays(DateTime.now().year);
  }

  Future<void> _fetchHolidays(int year) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(
          'https://api.invertexto.com/v1/holidays/$year?token=holiday'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<DateTime, List<Holiday>> holidaysMap = {};

        for (var holiday in data) {
          final date = DateTime.parse(holiday['date']);
          holidaysMap[date] = [
            Holiday(name: holiday['name'], type: holiday['type'])
          ];
        }

        setState(() {
          _holidays = holidaysMap;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load holidays');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feriados Nacionais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchHolidays(_focusedDay.year),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Holiday>(
            firstDay: DateTime(DateTime.now().year - 1),
            lastDay: DateTime(DateTime.now().year + 1),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchHolidays(focusedDay.year);
            },
            eventLoader: (day) => _holidays[day] ?? [],
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 16),
          _isLoading ? const CircularProgressIndicator() : _buildHolidayList(),
        ],
      ),
    );
  }

  Widget _buildHolidayList() {
    if (_selectedDay == null || _holidays[_selectedDay] == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nenhum feriado nesta data'),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _holidays[_selectedDay]!.length,
        itemBuilder: (context, index) {
          final holiday = _holidays[_selectedDay]![index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.celebration, color: Colors.red),
              title: Text(holiday.name),
              subtitle: Text('Tipo: ${holiday.type}'),
            ),
          );
        },
      ),
    );
  }
}
