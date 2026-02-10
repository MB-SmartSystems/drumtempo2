import 'package:flutter/material.dart';
import 'metronome_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrumTempo 2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MetronomePage(),
    );
  }
}

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  State<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  final MetronomeService _metronome = MetronomeService();
  int _bpm = 120;
  int _tickCount = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initMetronome();
  }

  Future<void> _initMetronome() async {
    await _metronome.initialize();
    setState(() {
      _isInitialized = true;
    });

    // Höre auf Tick-Events
    _metronome.tickStream.listen((tickCount) {
      setState(() {
        _tickCount = tickCount;
      });
    });
  }

  void _toggleMetronome() {
    if (_metronome.isRunning) {
      _metronome.stop();
      setState(() {
        _tickCount = 0;
      });
    } else {
      _metronome.start(_bpm);
    }
    setState(() {});
  }

  void _changeBpm(int delta) {
    setState(() {
      _bpm = (_bpm + delta).clamp(40, 300);
      if (_metronome.isRunning) {
        _metronome.changeBpm(_bpm);
      }
    });
  }

  @override
  void dispose() {
    _metronome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('DrumTempo 2'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BPM Display
            Text(
              '$_bpm',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'BPM',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),

            // BPM Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  iconSize: 40,
                  onPressed: () => _changeBpm(-1),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  iconSize: 40,
                  onPressed: () => _changeBpm(-10),
                ),
                const SizedBox(width: 60),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  iconSize: 40,
                  onPressed: () => _changeBpm(10),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 40,
                  onPressed: () => _changeBpm(1),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Start/Stop Button
            ElevatedButton(
              onPressed: _toggleMetronome,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                backgroundColor: _metronome.isRunning
                    ? Colors.red
                    : Colors.green,
              ),
              child: Text(
                _metronome.isRunning ? 'STOP' : 'START',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Tick Counter
            Text(
              'Ticks: $_tickCount',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
