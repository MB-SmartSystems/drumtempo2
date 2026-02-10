import 'dart:async';
import 'dart:isolate';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';

/// Metronome Service mit Isolate für präzises Timing
class MetronomeService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _sendPort;

  Soundpool? _soundpool;
  int? _clickSoundId;
  bool _isRunning = false;

  /// Stream für Metronom-Ticks (für UI-Updates)
  final _tickController = StreamController<int>.broadcast();
  Stream<int> get tickStream => _tickController.stream;

  /// Initialisiere soundpool und lade Click-Sound
  Future<void> initialize() async {
    _soundpool = Soundpool.fromOptions(
      options: const SoundpoolOptions(
        streamType: StreamType.music,
        maxStreams: 1,
      ),
    );

    // Lade Click-Sound
    final asset = await rootBundle.load('assets/click.wav');
    _clickSoundId = await _soundpool!.load(asset);
  }

  /// Starte Metronom mit gegebenem BPM
  Future<void> start(int bpm) async {
    if (_isRunning) return;

    _isRunning = true;
    _receivePort = ReceivePort();

    // Starte Isolate für Timer-Logic
    _isolate = await Isolate.spawn(
      _metronomeIsolate,
      _MetronomeConfig(
        sendPort: _receivePort!.sendPort,
        bpm: bpm,
      ),
    );

    // Empfange Ticks vom Isolate
    int tickCount = 0;
    _receivePort!.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message == 'tick') {
        // Spiele Click ab
        _soundpool?.play(_clickSoundId!);

        // Benachrichtige UI
        tickCount++;
        _tickController.add(tickCount);
      }
    });
  }

  /// Stoppe Metronom
  void stop() {
    if (!_isRunning) return;

    _sendPort?.send('stop');
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _sendPort = null;
    _isRunning = false;
  }

  /// Ändere BPM während Metronom läuft
  void changeBpm(int bpm) {
    if (_isRunning && _sendPort != null) {
      _sendPort!.send(bpm);
    }
  }

  /// Cleanup
  void dispose() {
    stop();
    _tickController.close();
    _soundpool?.dispose();
  }

  bool get isRunning => _isRunning;
}

/// Konfiguration für Metronom-Isolate
class _MetronomeConfig {
  final SendPort sendPort;
  final int bpm;

  _MetronomeConfig({required this.sendPort, required this.bpm});
}

/// Isolate-Funktion für präzise Timer-Logic
void _metronomeIsolate(_MetronomeConfig config) {
  final receivePort = ReceivePort();
  config.sendPort.send(receivePort.sendPort);

  Timer? timer;
  int currentBpm = config.bpm;

  void startTimer(int bpm) {
    timer?.cancel();
    final interval = Duration(milliseconds: (60000 / bpm).round());

    timer = Timer.periodic(interval, (timer) {
      config.sendPort.send('tick');
    });
  }

  // Starte initialen Timer
  startTimer(currentBpm);

  // Höre auf Kommandos vom Main-Isolate
  receivePort.listen((message) {
    if (message == 'stop') {
      timer?.cancel();
      receivePort.close();
    } else if (message is int) {
      // BPM-Änderung
      currentBpm = message;
      startTimer(currentBpm);
    }
  });
}
