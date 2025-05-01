import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contador via API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _seconds = 0;
  DateTime? _startTime;
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchTimeAndStartCounter();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTimeAndStartCounter() async {
    try {
      final response = await http.get(
          Uri.parse('http://worldtimeapi.org/api/timezone/America/Sao_Paulo'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentTime = DateTime.parse(data['datetime']);

        setState(() {
          _startTime = currentTime;
          _isLoading = false;
        });

        _startCounter();
      } else {
        throw Exception('Falha ao carregar o tempo');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro: $e';
      });
    }
  }

  void _startCounter() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_startTime!);
        setState(() {
          _seconds = difference.inSeconds;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador via API'),
        centerTitle: true,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage.isNotEmpty
                ? Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tempo decorrido desde:',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        _startTime?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        _formatTime(_seconds),
                        style: const TextStyle(
                            fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Horário obtido da World Time API',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchTimeAndStartCounter,
        tooltip: 'Recarregar',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
