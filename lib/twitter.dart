import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';

void main() => runApp(TwitterAnalyzerApp());

class TwitterAnalyzerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twitter Sentiment Analyzer',
      home: TwitterHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TwitterHomePage extends StatefulWidget {
  @override
  _TwitterHomePageState createState() => _TwitterHomePageState();
}

class _TwitterHomePageState extends State<TwitterHomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<Map<String, dynamic>> _tweets = [];

  Future<void> _fetchTweets() async {
    final username = _controller.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _loading = true;
      _tweets.clear();
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.29.46:5000/user_tweets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tweets = List<Map<String, dynamic>>.from(data['tweets']);
        });
      } else {
        setState(() {
          _tweets = [
            {'text': 'Error: ${response.body}', 'polarity': 0.0}
          ];
        });
      }
    } catch (e) {
      setState(() {
        _tweets = [
          {'text': 'Request failed: $e', 'polarity': 0.0}
        ];
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color _getPolarityColor(double polarity) {
    if (polarity >= 0.5) return Colors.green;
    if (polarity >= 0.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildListTile(String title, String? value) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value ?? 'N/A'),
    );
  }

  Widget _buildTweetTile(Map<String, dynamic> tweet, int index) {
    final polarity = tweet['polarity']?.toDouble() ?? 0.0;

    return ExpansionTile(
      title: Text(
        'Tweet ${index + 1}',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        _buildListTile("Tweet Text", tweet['text']),
        _buildListTile("Summary", tweet['summary']),
        _buildListTile("Subjectivity", tweet['subjectivity']?.toString()),
        _buildListTile("Keywords", (tweet['keywords'] as List?)?.join(', ')),
        _buildListTile("Entities", (tweet['entities'] as List?)?.join(', ')),
        _buildListTile("Emotion", tweet['emotion']),
        _buildListTile("Language", tweet['language']),
        _buildListTile("Word Count", tweet['word_count']?.toString()),
        _buildListTile("Readability Score", tweet['readability_score']?.toString()),
        _buildListTile("Toxicity Score", tweet['toxicity_score']?.toStringAsFixed(2)),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 10.0,
            percent: ((polarity + 1) / 2).clamp(0.0, 1.0),
            center: Text(
              (polarity * 100).toStringAsFixed(1),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            progressColor: _getPolarityColor(polarity),
            backgroundColor: Colors.grey.shade300,
            footer: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text("Polarity Score", style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Twitter Sentiment Analyzer'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter Twitter username (e.g. elonmusk)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchTweets,
              child: Text('Analyze Tweets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            if (_loading)
              CircularProgressIndicator()
            else if (_tweets.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _tweets.length,
                  itemBuilder: (context, index) {
                    return _buildTweetTile(_tweets[index], index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
