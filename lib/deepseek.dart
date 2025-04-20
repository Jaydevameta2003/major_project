import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TextAnalyzer extends StatefulWidget {
  @override
  _TextAnalyzerState createState() => _TextAnalyzerState();
}

class _TextAnalyzerState extends State<TextAnalyzer> {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  Future<void> analyzeText() async {
    final transcript = _controller.text.trim();
    if (transcript.isEmpty) {
      setState(() => _error = "Please enter transcript text.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.46:5000/summary'), // Replace with your backend URL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transcript': transcript}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() => _result = data);
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        setState(() => _error = errorData['error'] ?? 'Server Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = "Connection error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget buildResult() {
    if (_loading) return CircularProgressIndicator();
    if (_error != null) return Text("❌ $_error", style: TextStyle(color: Colors.red));
    if (_result == null) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("✅ Summary: ${_result!['data']}"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Text Analyzer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Enter Transcript'),
              maxLines: 5,
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: analyzeText,
              child: Text('Analyze Text'),
            ),
            SizedBox(height: 24),
            buildResult(),
          ],
        ),
      ),
    );
  }
}
