import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(
    VAutoSpeakApp()
);

class VAutoSpeakApp extends StatelessWidget {
  const VAutoSpeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: VAutoSpeakAppHomePage());
  }
}

class VAutoSpeakAppHomePage extends StatefulWidget {
  const VAutoSpeakAppHomePage({super.key});

  @override
  VAutoSpeakAppHomePageState createState() => VAutoSpeakAppHomePageState();
}

class VAutoSpeakAppHomePageState extends State<VAutoSpeakAppHomePage> {
  String _text = '';
  List<String> initialList = [];
  List<String> finalList = [];
  FlutterSoundRecorder recorder = FlutterSoundRecorder();
  String? audioPath;
  bool isRecording = false;
  List<CarPartResult> parts = [];
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  // List<String> transcriptChunks = [];
  bool isChunkRecording = false;
  final apiKey = '';
  final assistantId = '';
  final fileId = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> startRecord() async {
    setState(() {
      isRecording = true;
      _text = 'Recording started...';
    });
  }

  Future<void> startRecording() async {
    final micStatus = await Permission.microphone.request();

    if (micStatus != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required to record.')),
      );
      return;
    }

    Directory tempDir = await getTemporaryDirectory();
    audioPath = '${tempDir.path}/voice.mp4';
    print("Recording to: $audioPath");

    await recorder.openRecorder();
    await recorder.startRecorder(
      toFile: audioPath,
      codec: Codec.aacMP4,
    );
  }

  // Future<void> startRecording() async {
  //   final micStatus = await Permission.microphone.request();
  //   if (micStatus != PermissionStatus.granted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Microphone permission is required to record.')),
  //     );
  //     return;
  //   }
  //
  //   await recorder.openRecorder();
  //   isChunkRecording = true;
  //   recordChunkLoop();
  // }

  // Future<void> recordChunkLoop() async {
  //   while (isChunkRecording) {
  //     final tempDir = await getTemporaryDirectory();
  //     final path = '${tempDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.mp4';
  //
  //     await recorder.startRecorder(toFile: path, codec: Codec.aacMP4);
  //     await Future.delayed(Duration(seconds: 5));
  //     await recorder.stopRecorder();
  //
  //     try {
  //       final chunkTranscript = await transcribeAudioWithWhisper(path);
  //
  //       if (chunkTranscript.trim().isNotEmpty) {
  //         setState(() {
  //           transcriptChunks.add(chunkTranscript.trim());
  //           _text = transcriptChunks.join(" ");
  //         });
  //       } else {
  //         print("Skipping empty transcript chunk...");
  //       }
  //
  //     } catch (e) {
  //       print("Transcription error: $e");
  //     }
  //
  //     await Future.delayed(Duration(milliseconds: 200)); // avoid overlaps
  //   }
  //
  //   await recorder.closeRecorder();
  // }

  // Future<void> recordChunkLoop() async {
  //   final tempDir = await getTemporaryDirectory();
  //
  //   // Start long-running recording
  //   final fullPath = '${tempDir.path}/full_recording.mp4';
  //   await recorder.startRecorder(toFile: fullPath, codec: Codec.aacMP4);
  //
  //   int chunkCount = 0;
  //   isChunkRecording = true;
  //
  //   while (isChunkRecording) {
  //     await Future.delayed(Duration(seconds: 5));
  //
  //     final chunkPath = '${tempDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.mp4';
  //     final fullFile = File(fullPath);
  //
  //     print("---> fullFile: ${fullFile.exists()}");
  //     print("---> chunkPath: $chunkPath");
  //
  //     if (await fullFile.exists()) {
  //       try {
  //         final copied = await fullFile.copy(chunkPath);
  //         print("---> Copied chunk to: ${copied.path}");
  //         final chunkTranscript = await transcribeAudioWithWhisper(copied.path);
  //
  //         print("---> chunkTranscript: $chunkTranscript");
  //
  //         if (chunkTranscript.trim().isNotEmpty) {
  //           setState(() {
  //             transcriptChunks.add(chunkTranscript.trim());
  //             _text = transcriptChunks.join(" ");
  //           });
  //         } else {
  //           print("Skipping empty transcript chunk...");
  //         }
  //       } catch (e) {
  //         print("Chunk process error: $e");
  //       }
  //     }
  //
  //     chunkCount++;
  //   }
  //
  //   await recorder.stopRecorder();
  //   await recorder.closeRecorder();
  // }

  Future<void> stopRecord() async {
    setState(() {
    isLoading = true;
    });
  }

  Future<void> stopRecording() async {
    await recorder.stopRecorder();
    await recorder.closeRecorder();
  }

  // Future<void> stopRecording() async {
  //   isChunkRecording = false;
  //
  //   if (recorder.isRecording) {
  //     await recorder.stopRecorder();
  //   }
  //
  //   await recorder.closeRecorder();
  //   setState(() {
  //     _text = transcriptChunks.join(" ");
  //   });
  // }

  // Future<String> uploadCSVFile(String csvPath) async {
  //   final url = Uri.parse('https://api.openai.com/v1/files');
  //   var request = http.MultipartRequest('POST', url)
  //     ..headers['Authorization'] = 'Bearer $apiKey'
  //     ..files.add(await http.MultipartFile.fromPath('file', csvPath))
  //     ..fields['purpose'] = 'assistants'; // required
  //
  //   final response = await request.send();
  //   final body = await http.Response.fromStream(response);
  //
  //   if (body.statusCode == 200) {
  //     final fileId = jsonDecode(body.body)['id'];
  //     print("Uploaded File ID: $fileId");
  //     return fileId;
  //   } else {
  //     throw Exception('File upload failed: ${body.body}');
  //   }
  // }

  List<CarPartResult> parseCarPartsFromAssistant(String fullText) {
    try {
      final List<dynamic> decoded = jsonDecode(fullText);
      return decoded.map((e) => CarPartResult.fromJson(e)).toList();
    } catch (e) {
      final regex = RegExp(r'```json(.*?)```', dotAll: true);
      final match = regex.firstMatch(fullText);
      if (match != null) {
        final jsonString = match.group(1)!.trim();
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => CarPartResult.fromJson(e)).toList();
      }
      print('Failed to parse car parts JSON: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Clean up controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("vAutoSpeak", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Text(
                              _text.isEmpty ? "Your voice transcription will appear here." : _text,
                              style: const TextStyle(fontSize: 18, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        isRecording
                            ? 'Listening... tap to stop.'
                            : 'Tap the mic below to speak.',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (parts.isNotEmpty)
                    SizedBox(
                        height: 350,
                        child: Card(
                          elevation: 1,
                          shadowColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              children: [
                                Container(
                                  color: Colors.indigo.shade100,
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const VerticalDivider(width: 1, thickness: 1),
                                      const Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const VerticalDivider(width: 1, thickness: 1),
                                      SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.transparent),
                                          tooltip: 'Delete',
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    scrollDirection: Axis.vertical,
                                    child: Column(
                                      children: parts.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final part = entry.value;

                                        return Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Colors.grey, width: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Text(part.fullName),
                                                ),
                                              ),
                                              VerticalDivider(width: 1, thickness: 1),
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Text(part.totalPrice),
                                                ),
                                              ),
                                              VerticalDivider(width: 1, thickness: 1),
                                              SizedBox(
                                                width: 40,
                                                child: IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  tooltip: 'Delete',
                                                  onPressed: () {
                                                    setState(() {
                                                      parts.removeAt(index);
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                Container(
                                  color: Colors.indigo.shade50,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            'Total Price',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      VerticalDivider(width: 1, thickness: 1),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Text(
                                            getTotalPrice(),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      VerticalDivider(width: 1, thickness: 1),
                                      const SizedBox(width: 40),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  width: 120,
                  margin: EdgeInsets.only(top: 15),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        parts.clear();
                        _text = 'Your voice transcription will appear here.';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withAlpha(77),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isRecording ? Colors.redAccent : Colors.green,
        onPressed: () async {
          if (!isRecording) {
            await startRecord();
            await startRecording();
          } else {
            await stopRecord();
            await stopRecording();

            try {
              final transcript = await transcribeAudioWithWhisper(audioPath!);
              // final transcript = 'Front bumper corner scratched - needs painting, two diamond alloy wheels damaged need repairing dent on passenger door needs local repair';
              print("---> transcript: $transcript");

              // print("---> transcriptChunks: $transcriptChunks");
              // final transcript = transcriptChunks.join(" ");
              // print("---> transcript: $transcript");
              // transcriptChunks.clear();

              setState(() {
                _text = transcript;
              });

              final resultText = await queryWithCompletionAPI(transcript);
              print("resultText: $resultText");

              setState(() {

                final newParts = parseCarPartsFromAssistant(resultText);
                for (var part in newParts) {
                  final exists = parts.any((existingPart) =>
                  existingPart.fullName == part.fullName &&
                      existingPart.totalPrice == part.totalPrice);

                  if (!exists) {
                    print("---> Adding new unique part: ${part.fullName} - ${part.totalPrice}");
                    parts.add(part);
                  }
                }

                isRecording = false;
              });

            } catch (e) {
              print("Error: $e");
            } finally {
              setState(() => isLoading = false);
            }
          }
        },
        child: Icon(
          isRecording ? Icons.stop : Icons.mic,
          size: 30,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String getTotalPrice() {
    double total = 0;
    for (var part in parts) {
      final numeric = part.totalPrice.replaceAll(RegExp(r'[^\d.]'), '');
      total += double.tryParse(numeric) ?? 0;
    }
    return "£${total.toStringAsFixed(2)}";
  }

  Future<String> transcribeAudioWithWhisper(String audioPath) async {
    final url = Uri.parse('https://api.openai.com/v1/audio/transcriptions');

    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..files.add(await http.MultipartFile.fromPath('file', audioPath))
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'en';

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'];
    } else {
      throw Exception('Whisper transcription failed: ${response.body}');
    }
  }

  // Future<String> queryAssistantWithVoice(String transcript) async {
  //
  //   final threadRes = await http.post(
  //     Uri.parse('https://api.openai.com/v1/threads'),
  //     headers: {
  //       'Authorization': 'Bearer $apiKey',
  //       'Content-Type': 'application/json',
  //       'OpenAI-Beta': 'assistants=v2',
  //     },
  //     body: jsonEncode({}),
  //   );
  //   if (threadRes.statusCode != 200) {
  //     print("Failed to create thread: ${threadRes.statusCode}");
  //     print("Response body: ${threadRes.body}");
  //     throw Exception("Thread creation failed");
  //   }
  //   final threadId = jsonDecode(threadRes.body)['id'];
  //   print("---> threadId: $threadId");
  //
  //
  //   await http.post(
  //     Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
  //     headers: {
  //       'Authorization': 'Bearer $apiKey',
  //       'Content-Type': 'application/json',
  //       'OpenAI-Beta': 'assistants=v2',
  //     },
  //     body: jsonEncode({
  //       'role': 'user',
  //       'content': transcript,
  //       'attachments': [
  //         {
  //           "file_id": fileId,
  //           "tools": [
  //             {
  //               "type": "code_interpreter"
  //             }
  //           ]
  //         }
  //       ]
  //     }),
  //   );
  //
  //
  //   final runRes = await http.post(
  //     Uri.parse('https://api.openai.com/v1/threads/$threadId/runs'),
  //     headers: {
  //       'Authorization': 'Bearer $apiKey',
  //       'Content-Type': 'application/json',
  //       'OpenAI-Beta': 'assistants=v2',
  //     },
  //     body: jsonEncode({'assistant_id': assistantId}),
  //   );
  //   final runId = jsonDecode(runRes.body)['id'];
  //   print("---> runId: $runId");
  //
  //
  //   while (true) {
  //     final statusRes = await http.get(
  //       Uri.parse('https://api.openai.com/v1/threads/$threadId/runs/$runId'),
  //       headers: {
  //         'Authorization': 'Bearer $apiKey',
  //         'OpenAI-Beta': 'assistants=v2',
  //       },
  //     );
  //     final status = jsonDecode(statusRes.body)['status'];
  //     if (status == 'completed') break;
  //     await Future.delayed(Duration(seconds: 2));
  //   }
  //
  //
  //   final messagesRes = await http.get(
  //     Uri.parse('https://api.openai.com/v1/threads/$threadId/messages'),
  //     headers: {
  //       'Authorization': 'Bearer $apiKey',
  //       'OpenAI-Beta': 'assistants=v2',
  //     },
  //   );
  //   final messages = jsonDecode(messagesRes.body)['data'];
  //
  //   final assistantReply = messages.firstWhere((m) => m['role'] == 'assistant', orElse: () => null);
  //   final contents = assistantReply['content'] as List;
  //   final fullText = contents.map((c) => c['text']['value']).join("\n");
  //   print("---> Text: $fullText");
  //
  //   return messages.first['content'][0]['text']['value'];
  // }

  // Future<String> loadExcelContentAsText() async {
  //
  //   final data = await rootBundle.load('assets/excel/warrington_used_car_sales_matrix.xlsx');
  //   final bytes = data.buffer.asUint8List();
  //
  //   final excel = Excel.decodeBytes(bytes);
  //
  //   final buffer = StringBuffer();
  //   for (final table in excel.tables.keys) {
  //     final sheet = excel.tables[table];
  //     if (sheet == null) continue;
  //
  //     for (final row in sheet.rows) {
  //       final line = row.map((cell) => cell?.value?.toString() ?? "").join('\t');
  //       buffer.writeln(line);
  //     }
  //   }
  //
  //   return buffer.toString();
  // }

  Future<String> queryWithCompletionAPI(String transcript) async {
    final url = Uri.parse('https://api.openai.com/v1/responses');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4o",
        "input": [
          {
            "role": "system",
            "content": '''
            You are an assistant that helps users identify car parts and their associated repair types based on natural-language damage descriptions, using data from a JSON file.\n\nThe JSON file contains a pricing matrix. Each item represents a repair task, and includes:\n\nThe full part and job name in the \"Description\" field (e.g., \"FRONT BUMPER PAINT\", \"ALLOY WHEEL REFURB\")\n\nSeveral numeric fields representing cost components (2024 Price, Labour Split, P&M Split)\n\nYour task:\n\nUse Python and json.load() or pandas.read_json() to read the file.\n\nExtract key damage areas or part names from the user's input (e.g., \"bumper scratched\", \"two alloy wheels damaged\", \"dent on passenger door\").\n\nUse fuzzy matching on the \"Description\" field to find the most relevant items.\n\nFor each matched item:\n\nReturn:\n\n\"full_name\": the exact string from the \"Description\" field\n\n\"total_price\": the sum of all numeric values in that item\n\nAlways respond only in JSON format, like:\n\n[\n  {\n    \"full_name\": \"FRONT BUMPER PAINT\",\n    \"total_price\": \"£320.00\"\n  },\n  {\n    \"full_name\": \"ALLOY WHEEL REFURB\",\n    \"total_price\": \"£450.00\"\n  }\n]\n\nDo not provide any explanations, bullet points, markdown code blocks, or additional commentary — only return the JSON array.
            ''',
          },
          {
            "role": "user",
            "content": transcript
          }
        ],
        "tools": [{
          "type": "file_search",
          "vector_store_ids": ["vs_6870b612c3a48191a3667580690f37c2"]
        }]
      }),
    );

    if (response.statusCode != 200) {
      print("Completion API error: ${response.statusCode}");
      print("Body: ${response.body}");
      throw Exception("Chat completion failed");
    }

    final json = jsonDecode(response.body);
    print ("---> json: $json");
    // final message = json['choices'][0]['message']['content'];
    // print("---> Chat reply: $message");

    return "$json";
  }

  // Future<String> queryWithCompletionAPI(String transcript) async {
  //   final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  //   final excelContent = await loadExcelContentAsText();
  //
  //   final response = await http.post(
  //     url,
  //     headers: {
  //       'Authorization': 'Bearer $apiKey',
  //       'Content-Type': 'application/json',
  //     },
  //     body: jsonEncode({
  //       "model": "gpt-4",
  //       "messages": [
  //         {
  //           "role": "system",
  //           "content": '''
  //             You are an assistant that helps users identify car parts and their associated repair types based on natural-language damage descriptions, using data from an Excel file.
  //             The Excel content contains a pricing matrix. Each row represents a repair task, and includes:
  //             The full part and job name in the first column (e.g., "FRONT BUMPER PAINT", "ALLOY WHEEL REFURB")
  //             Several numeric columns representing cost components (2024, Labour split,  P&M Split)
  //             Your task:
  //             Use Python and pandas.read_excel() to read the file.
  //             Extract key damage areas or part names from the user's input (e.g., "bumper scratched", "two alloy wheels damaged", "dent on passenger door").
  //             Use fuzzy matching on the first column to find the most relevant rows.
  //             For each matched row:
  //             Return:
  //             "full_name": the exact string from the first column
  //             "total_price": the sum of all numeric values in that row
  //             Always respond **only** in JSON format, like:
  //             [
  //              {
  //               "full_name": "FRONT BUMPER PAINT",
  //               "total_price": "£320.00"
  //              },
  //              {
  //               "full_name": "ALLOY WHEEL REFURB",
  //               "total_price": "£450.00"
  //              }
  //             ]
  //             Do not provide any explanations, bullet points, markdown code blocks, or additional commentary — only return the JSON array.'''
  //         },
  //         {
  //           "role": "user",
  //           "content": "Given the following car part list:\n$excelContent\nNow, based on my input: $transcript",
  //         }
  //       ],
  //       "temperature": 0.7
  //     }),
  //   );
  //
  //   if (response.statusCode != 200) {
  //     print("Completion API error: ${response.statusCode}");
  //     print("Body: ${response.body}");
  //     throw Exception("Chat completion failed");
  //   }
  //
  //   final json = jsonDecode(response.body);
  //   final message = json['choices'][0]['message']['content'];
  //   print("---> Chat reply: $message");
  //
  //   return message;
  // }

}

class CarPartResult {
  final String fullName;
  final String totalPrice;

  CarPartResult({required this.fullName, required this.totalPrice});

  factory CarPartResult.fromJson(Map<String, dynamic> json) {
    return CarPartResult(
      fullName: json['full_name'],
      totalPrice: json['total_price'],
    );
  }
}

