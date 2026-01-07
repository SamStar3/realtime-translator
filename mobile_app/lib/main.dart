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

/// 🌍 Supported Languages
const Map<String, String> languageMap = {
  "Spanish": "es",
  "French": "fr",
  "German": "de",
  "Hindi": "hi",
  "Tamil": "ta",
  "Japanese": "ja",
  "Chinese": "zh",
};

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

  String _selectedLanguageName = "Spanish";
  String _targetLanguage = "es";

  String _translatedText = "";
  String _languageInfo = "";

  /// 🔌 CONNECT WEBSOCKET
  Future<void> _connectWebSocket() async {
    if (_socketConnected) return;

    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse("ws://192.168.1.2:8000/ws/translate"),
      );

      _socketConnected = true;
      print("🔌 WebSocket connected");

      // ✅ Send target language once
      _channel!.sink.add(jsonEncode({
        "target_language": _targetLanguage,
      }));
      print("🎯 Target language sent: $_targetLanguage");

      _channel!.stream.listen(
            (message) {
          if (message is String) {
            try {
              final data = jsonDecode(message);

              if (data["type"] == "final") {
                setState(() {
                  _translatedText = data["translated_text"] ?? "";
                  _languageInfo =
                  "${data["source_language"]} → ${data["target_language"]}";
                });

                print("📝 TRANSLATED: $_translatedText ($_languageInfo)");
              }
            } catch (e) {
              print("⚠️ Invalid JSON: $message");
            }
          }
        },
        onDone: () {
          print("🔌 WebSocket closed by backend");
          _socketConnected = false;
          _channel = null;
        },
        onError: (e) {
          print("❌ WebSocket error: $e");
          _socketConnected = false;
          _channel = null;
        },
      );
    } catch (e) {
      print("❌ WebSocket connection failed: $e");
      _socketConnected = false;
      _channel = null;
    }
  }

  /// ▶ START RECORDING
  Future<void> _startRecording() async {
    if (_isRecording) return;

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
      if (_isRecording && _socketConnected && _channel != null) {
        _channel!.sink.add(data);
      }
    });
  }

  /// ⏹ STOP RECORDING
  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    setState(() => _isRecording = false);

    await _audioSubscription?.cancel();
    await _recorder.stop();

    if (_socketConnected && _channel != null) {
      try {
        print("🛑 Stop signal sent");
        _channel!.sink.add("__STOP__");

        await Future.delayed(const Duration(milliseconds: 700));
        await _channel!.sink.close();
      } catch (_) {}
    }

    _socketConnected = false;
    _channel = null;
    print("⏹ Recording stopped");
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _recorder.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  /// 🖥 UI
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
            /// 🌍 Language Selector
            DropdownButton<String>(
              value: _selectedLanguageName,
              isExpanded: true,
              items: languageMap.keys.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedLanguageName = value;
                  _targetLanguage = languageMap[value]!;
                });

                print("🌍 Target language changed to $_targetLanguage");
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? "Stop" : "Start"),
            ),

            const SizedBox(height: 25),

            if (_languageInfo.isNotEmpty)
              Text(
                "Language: $_languageInfo",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _translatedText.isEmpty
                    ? "Speak something..."
                    : _translatedText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
