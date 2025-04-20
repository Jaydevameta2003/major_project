import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getUrlSentiment(String newsUrl) async {
  final url = Uri.parse('http://192.168.29.46:5001/news-sentiment');

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"url": newsUrl}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'polarity': data['polarity'],
        'subjectivity': data['subjectivity'],
        'summary': data['summary'],
      };
    } else {
      throw Exception('Failed: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error connecting to backend: $e');
  }
}
