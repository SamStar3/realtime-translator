// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:record/record.dart';
// import 'package:web_socket_channel/io.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: SpeechTranslatorPage(),
//     );
//   }
// }
//
// /// 🌍 Language selector
// const Map<String, String> languageMap = {
//   "Spanish": "es",
//   "French": "fr",
//   "German": "de",
//   "Hindi": "hi",
//   "Tamil": "ta",
//   "Japanese": "ja",
//   "Chinese": "zh",
// };
//
// class Segment {
//   final String source;
//   final String translated;
//   final String time;
//
//   Segment({
//     required this.source,
//     required this.translated,
//     required this.time,
//   });
// }
//
// class SpeechTranslatorPage extends StatefulWidget {
//   const SpeechTranslatorPage({super.key});
//
//   @override
//   State<SpeechTranslatorPage> createState() => _SpeechTranslatorPageState();
// }
//
// class _SpeechTranslatorPageState extends State<SpeechTranslatorPage> {
//   final AudioRecorder _recorder = AudioRecorder();
//   IOWebSocketChannel? _channel;
//   StreamSubscription<Uint8List>? _audioSub;
//
//   bool _recording = false;
//
//   String _selectedLang = "Spanish";
//   String _targetLang = "es";
//
//   final List<Segment> _segments = [];
//
//   final ScrollController _scroll = ScrollController();
//
//   /// 🔌 Connect WebSocket
//   Future<void> _connectWS() async {
//     _channel = IOWebSocketChannel.connect(
//       Uri.parse("ws://192.168.1.2:8000/ws/translate"),
//     );
//
//     // send target language
//     _channel!.sink.add(jsonEncode({
//       "target_language": _targetLang,
//     }));
//
//     _channel!.stream.listen((message) {
//       final data = jsonDecode(message);
//
//       if (data["type"] == "segment") {
//         setState(() {
//           _segments.add(
//             Segment(
//               source: data["source_text"],
//               translated: data["translated_text"],
//               time: _formatTime(data["start"]),
//             ),
//           );
//         });
//
//         // auto-scroll
//         Future.delayed(const Duration(milliseconds: 100), () {
//           if (_scroll.hasClients) {
//             _scroll.animateTo(
//               _scroll.position.maxScrollExtent,
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeOut,
//             );
//           }
//         });
//       }
//     });
//   }
//
//   /// ▶ Start recording
//   Future<void> _start() async {
//     if (_recording) return;
//
//     if (!await _recorder.hasPermission()) return;
//
//     await _connectWS();
//
//     final stream = await _recorder.startStream(
//       const RecordConfig(
//         encoder: AudioEncoder.pcm16bits,
//         sampleRate: 16000,
//         numChannels: 1,
//       ),
//     );
//
//     setState(() => _recording = true);
//
//     _audioSub = stream.listen((data) {
//       _channel?.sink.add(data);
//     });
//   }
//
//   /// ⏹ Stop
//   Future<void> _stop() async {
//     setState(() => _recording = false);
//
//     await _audioSub?.cancel();
//     await _recorder.stop();
//
//     _channel?.sink.close();
//   }
//
//   String _formatTime(dynamic seconds) {
//     final s = (seconds as num).floor();
//     final m = s ~/ 60;
//     final r = s % 60;
//     return "${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Speech Translator"),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 12),
//
//           /// Language selector
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: DropdownButton<String>(
//               isExpanded: true,
//               value: _selectedLang,
//               items: languageMap.keys.map((lang) {
//                 return DropdownMenuItem(
//                   value: lang,
//                   child: Text(lang),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 if (value == null) return;
//                 setState(() {
//                   _selectedLang = value;
//                   _targetLang = languageMap[value]!;
//                 });
//
//                 // notify backend immediately
//                 _channel?.sink.add(jsonEncode({
//                   "target_language": _targetLang,
//                 }));
//               },
//             ),
//           ),
//
//           const SizedBox(height: 12),
//
//           /// Start / Stop
//           ElevatedButton(
//             onPressed: _recording ? _stop : _start,
//             style: ElevatedButton.styleFrom(
//               padding:
//               const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//               ),
//             ),
//             child: Text(_recording ? "Stop" : "Start"),
//           ),
//
//           const SizedBox(height: 12),
//
//           Text(
//             "Live Translation (${_targetLang.toUpperCase()})",
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//
//           const Divider(),
//
//           /// 🧠 LIVE SEGMENTS
//           Expanded(
//             child: ListView.builder(
//               controller: _scroll,
//               itemCount: _segments.length,
//               itemBuilder: (context, i) {
//                 final seg = _segments[i];
//                 return Padding(
//                   padding:
//                   const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "[${seg.time}] ${seg.source}",
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         seg.translated,
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const Divider(),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';

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
      home: SpeechPage(),
    );
  }
}

class SpeechPage extends StatefulWidget {
  const SpeechPage({super.key});

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

class _SpeechPageState extends State<SpeechPage> {
  final AudioRecorder _recorder = AudioRecorder();
  IOWebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _sub;

  bool _recording = false;
  String _liveText = "";

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) return;

    _channel = IOWebSocketChannel.connect(
      Uri.parse("ws://192.168.1.2:8000/ws/translate"),
    );

    _channel!.stream.listen((msg) {
      final data = jsonDecode(msg);
      if (data["type"] == "partial") {
        setState(() {
          _liveText += " ${data["text"]}";
        });
      }
    });

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _sub = stream.listen((chunk) {
      _channel?.sink.add(chunk);
    });

    setState(() => _recording = true);
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    await _recorder.stop();
    _channel?.sink.add("__STOP__");
    _channel?.sink.close();
    setState(() => _recording = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Speech Translator")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _recording ? _stop : _start,
              child: Text(_recording ? "Stop" : "Start"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _liveText.isEmpty
                      ? "Speak…"
                      : _liveText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
