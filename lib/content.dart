import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';

class Content extends StatefulWidget {
  const Content({super.key});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content> {
  TextEditingController controller = TextEditingController();
  double score = 0.0;
  String sentiment = "";

  Future<void> fetchSentiment(String query) async {
    final url = Uri.parse(
      'http://192.168.223.189:5000/analyze?query=${Uri.encodeComponent(query)}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          score = data['normalized_score']?.toDouble() ?? 0.0;
          sentiment = data['sentiment'] ?? "No sentiment";
        });
      } else {
        setState(() {
          sentiment = 'Error: ${response.statusCode}';
          score = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        sentiment = 'Error: Could not connect to API';
        score = 0.0;
      });
    }
  }

  void clearInput() {
    setState(() {
      controller.clear();
      sentiment = "";
      score = 0.0;
    });
  }

  Color getProgressColor(double value) {
    if (value < 0.5) {
      return Colors.red;
    } else if (value == 0.5) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade100,
      appBar: AppBar(
        title: const Text("News Sentiment Analyzer"),
        backgroundColor: Colors.deepPurple.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter news headline...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => fetchSentiment(controller.text),
                  icon: const Icon(Icons.send),
                  label: const Text("Submit"),
                ),
                const SizedBox(width: 20),
                OutlinedButton.icon(
                  onPressed: clearInput,
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear"),
                ),
              ],
            ),
            const SizedBox(height: 40),
            CircularPercentIndicator(
              animation: true,
              animationDuration: 1000,
              radius: 120,
              lineWidth: 20,
              percent: score.clamp(0.0, 1.0),
              progressColor: getProgressColor(score),
              backgroundColor: Colors.deepPurple.shade200,
              circularStrokeCap: CircularStrokeCap.round,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${(score * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sentiment,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
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
