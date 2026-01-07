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
      home: SpeechTranslatorPage(),
    );
  }
}

class SpeechTranslatorPage extends StatefulWidget {
  const SpeechTranslatorPage({super.key});

  @override
  State<SpeechTranslatorPage> createState() => _SpeechTranslatorPageState();
}

class _SpeechTranslatorPageState extends State<SpeechTranslatorPage> {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;
  IOWebSocketChannel? _channel;

  bool _recording = false;

  final List<_Segment> _segments = [];
  final ScrollController _scroll = ScrollController();

  String targetLanguage = "es";

  // ------------------ CONNECT ------------------
  Future<void> _connect() async {
    _channel = IOWebSocketChannel.connect(
      Uri.parse("ws://192.168.1.2:8000/ws/translate"),
    );

    _channel!.sink.add(jsonEncode({
      "target_language": targetLanguage,
    }));

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);

      if (data["type"] == "segment") {
        setState(() {
          _segments.add(
            _Segment(
              original: data["original_text"],
              translated: data["translated_text"],
              sourceLang: data["source_language"],
              targetLang: data["target_language"],
            ),
          );
        });

        // auto scroll
        Future.delayed(const Duration(milliseconds: 50), () {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      }
    });
  }

  // ------------------ START ------------------
  Future<void> _start() async {
    if (!await _recorder.hasPermission()) return;

    _segments.clear();
    await _connect();

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    setState(() => _recording = true);

    _audioSub = stream.listen((chunk) {
      _channel?.sink.add(chunk);
    });
  }

  // ------------------ STOP ------------------
  Future<void> _stop() async {
    setState(() => _recording = false);

    await _audioSub?.cancel();
    await _recorder.stop();

    _channel?.sink.add("__STOP__");
    _channel?.sink.close();
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Speech Translator"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 🎛 Controls
          ElevatedButton(
            onPressed: _recording ? _stop : _start,
            child: Text(_recording ? "Stop" : "Start"),
          ),

          const SizedBox(height: 10),

          Text(
            "Live Translation (${targetLanguage.toUpperCase()})",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const Divider(),

          // 📝 Transcription + Translation
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _segments.length,
              itemBuilder: (context, index) {
                final seg = _segments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original
                      Text(
                        seg.original,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Translation
                      Text(
                        seg.translated,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    _recorder.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}

// ------------------ MODEL ------------------
class _Segment {
  final String original;
  final String translated;
  final String sourceLang;
  final String targetLang;

  _Segment({
    required this.original,
    required this.translated,
    required this.sourceLang,
    required this.targetLang,
  });
}
