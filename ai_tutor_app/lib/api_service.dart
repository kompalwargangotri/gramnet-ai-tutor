import 'dart:convert';
import 'package:http/http.dart' as http;

class TutorAPI {
  static Future<Map<String, dynamic>> askTutor(String query) async {
    final url = Uri.parse("http://10.0.2.2:8000/ask");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"query": query, "lang": "en", "difficulty": "easy"}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error: ${response.body}");
    }
  }
}
