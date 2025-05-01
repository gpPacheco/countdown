import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/countdown_data.dart';
import '../utils/file_storage.dart';
import '../widgets/countdown_card.dart';
import 'countdown_screen.dart';
import 'countdown_setup_screen.dart';

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
  final FileStorage _fileStorage = FileStorage();

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

  Future<void> _loadCountdowns() async {
    try {
      final countdowns = await _fileStorage.loadCountdowns();
      setState(() {
        _countdowns = countdowns;
        for (var countdown in _countdowns) {
          countdown.updateAfterRestart();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading countdowns: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCountdowns() async {
    try {
      await _fileStorage.saveCountdowns(_countdowns);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving countdowns: $e');
      }
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
                      return CountdownCard(
                        countdown: countdown,
                        onDelete: () {
                          setState(() {
                            _countdowns.removeAt(index);
                            _saveCountdowns();
                          });
                        },
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
                        onTogglePause: () {
                          setState(() {
                            countdown.togglePause();
                            _saveCountdowns();
                          });
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add',
        onPressed: () => _navigateToCreateCountdown(context),
        child: const Icon(Icons.add),
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
