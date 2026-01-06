import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AudioPage(),
    );
  }
}

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  final AudioRecorder _recorder = AudioRecorder();

  IOWebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _audioSubscription;

  bool _isRecording = false;
  bool _socketConnected = false;

  String _transcript = "";
  String _language = "";

  /// 🔌 CONNECT WEBSOCKET
  Future<void> _connectWebSocket() async {
    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(
          "ws://192.168.1.14:8000/ws/translate", // 🔥 YOUR PC IP
        ),
      );

      _socketConnected = true;
      print("🔌 WebSocket connected");

      _channel!.stream.listen(
            (message) {
          if (message is String) {
            final data = jsonDecode(message);

            if (data["type"] == "final") {
              setState(() {
                _transcript = data["text"] ?? "";
                _language = data["language"] ?? "";
              });

              print("📝 FINAL ASR: $_transcript ($_language)");
            }
          }
        },
        onDone: () {
          print("🔌 WebSocket closed by backend");
          _socketConnected = false;
        },
        onError: (e) {
          print("❌ WebSocket error: $e");
          _socketConnected = false;
        },
      );

    } catch (e) {
      print("❌ WebSocket connection failed: $e");
      _socketConnected = false;
    }
  }

  /// ▶ START RECORDING
  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      print("❌ Microphone permission denied");
      return;
    }

    await _connectWebSocket();
    if (!_socketConnected) return;

    final audioStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    setState(() => _isRecording = true);
    print("▶ Recording started");

    _audioSubscription = audioStream.listen((Uint8List data) {
      if (_isRecording && _socketConnected) {
        _channel?.sink.add(data);
        print("➡ Sent ${data.length} bytes");
      }
    });
  }

  /// ⏹ STOP RECORDING
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    setState(() => _isRecording = false);

    await _audioSubscription?.cancel();
    await _recorder.stop();

    if (_socketConnected) {
      _channel?.sink.add("__STOP__");
      print("🛑 Stop signal sent");
    }

    // ❌ DO NOT close socket here
  }


  @override
  void dispose() {
    _audioSubscription?.cancel();
    _recorder.dispose();

    if (_socketConnected) {
      _channel?.sink.close();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Speech Translator"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? "Stop" : "Start"),
            ),
            const SizedBox(height: 20),

            if (_language.isNotEmpty)
              Text(
                "Language: $_language",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _transcript.isEmpty ? "Speak something..." : _transcript,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        )
      ),
    );
  }
}
