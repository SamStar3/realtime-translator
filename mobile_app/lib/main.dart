import 'dart:async';
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

  bool _isRecording = false;

  IOWebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _audioSubscription;

  // 🔌 Connect to backend WebSocket
  void _connectWebSocket() {
    _channel = IOWebSocketChannel.connect(
      Uri.parse("ws://10.0.2.2:8000/ws/translate"),
    );
    print("🔌 WebSocket connected");
  }

  // ▶ Start recording and streaming audio
  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      print("🎤 Microphone permission granted");

      _connectWebSocket();

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
        _channel?.sink.add(data);
        print("➡ Sent ${data.length} bytes");
      });
    } else {
      print("❌ Microphone permission denied");
    }
  }

  // ⏹ Stop recording and close connections
  Future<void> _stopRecording() async {
    await _audioSubscription?.cancel();
    await _recorder.stop();
    await _channel?.sink.close();

    setState(() => _isRecording = false);
    print("⏹ Recording stopped");
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _recorder.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Audio Streaming"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          child: Text(_isRecording ? "Stop" : "Start"),
        ),
      ),
    );
  }
}
