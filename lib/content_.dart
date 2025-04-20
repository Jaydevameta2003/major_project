import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';

void main() {
  runApp(SummaryApp());
}

class SummaryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Summary & Polarity',
      home: SummaryHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SummaryHomePage extends StatefulWidget {
  @override
  _SummaryHomePageState createState() => _SummaryHomePageState();
}

class _SummaryHomePageState extends State<SummaryHomePage> {
  TextEditingController _controller = TextEditingController();
  bool _loading = false;

  String _summary = '';
  double? _polarity;
  double? _subjectivity;
  List<String> _keywords = [];
  List<List<dynamic>> _entities = [];
  String? _emotion;
  String? _language;
  int? _wordCount;
  double? _readability;
  double? _toxicity;

  Future<void> _analyzeText() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _loading = true;
      _summary = '';
      _polarity = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.46:5000/analyze'), // Adjust IP if needed
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'text': userInput}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _summary = data['summary'];
          _polarity = data['polarity']?.toDouble();
          _subjectivity = data['subjectivity']?.toDouble();
          _keywords = List<String>.from(data['keywords']);
          _entities = List<List<dynamic>>.from(data['entities']);
          _emotion = data['emotion'];
          _language = data['language'];
          _wordCount = data['word_count'];
          _readability = data['readability_score']?.toDouble();
          _toxicity = data['toxicity_score']?.toDouble();
        });
      } else {
        setState(() {
          _summary = 'Error: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _summary = 'Request failed: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color _getPolarityColor(double score) {
    if (score >= 0.5) return Colors.green;
    if (score >= 0.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Summary & Sentiment'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter text to summarize and analyze...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _analyzeText,
              child: Text('Analyze'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            if (_loading)
              CircularProgressIndicator()
            else if (_summary.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    ExpansionTile(
                      title: Text("Summary", style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(_summary),
                        ),
                      ],
                    ),
                    if (_polarity != null)
                      ExpansionTile(
                        title: Text("Polarity"),
                        children: [
                          Center(
                            child: CircularPercentIndicator(
                              radius: 80.0,
                              lineWidth: 10.0,
                              percent: (_polarity! + 1) / 2,
                              center: Text(
                                (_polarity! * 100).toStringAsFixed(1),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              progressColor: _getPolarityColor(_polarity!),
                              backgroundColor: Colors.grey.shade300,
                              footer: Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text("Polarity Score", style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (_subjectivity != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Subjectivity: ${_subjectivity!.toStringAsFixed(2)}"),
                            ),
                        ],
                      ),
                    if (_keywords.isNotEmpty)
                      ExpansionTile(
                        title: Text("Keywords"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Wrap(
                              spacing: 6.0,
                              children: _keywords.map((k) => Chip(label: Text(k))).toList(),
                            ),
                          ),
                        ],
                      ),
                    if (_entities.isNotEmpty)
                      ExpansionTile(
                        title: Text("Named Entities"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Wrap(
                              spacing: 6.0,
                              children: _entities
                                  .map((e) => Chip(label: Text('${e[0]} (${e[1]})')))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    if (_emotion != null)
                      ExpansionTile(
                        title: Text("Emotion"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Detected Emotion: $_emotion"),
                          ),
                        ],
                      ),
                    if (_language != null || _wordCount != null || _readability != null)
                      ExpansionTile(
                        title: Text("Text Info"),
                        children: [
                          if (_language != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Language: $_language"),
                            ),
                          if (_wordCount != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Word Count: $_wordCount"),
                            ),
                          if (_readability != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Readability Score: ${_readability!.toStringAsFixed(1)}"),
                            ),
                        ],
                      ),
                    if (_toxicity != null)
                      ExpansionTile(
                        title: Text("Toxicity"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Toxicity Score: ${_toxicity!.toStringAsFixed(2)}"),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
