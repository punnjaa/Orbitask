import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

class Breakdown {
  final int score;
  final String reasoning;
  final List<Map<String, dynamic>> subtasks;
  Breakdown(this.score, this.reasoning, this.subtasks);
}

class ApiService {
  static Future<Breakdown> fetchTaskBreakdown({
    required String subject,
    required String description,
    required String deadline,
    required List<Map<String, dynamic>> others,
  }) async {
    final token = Supabase.instance.client.auth.currentSession!.accessToken;
    final res = await http.post(
      Uri.parse('${Env.api}/ai/breakdown'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'subject': subject, 'description': description,
        'deadline': deadline, 'other_subjects': others,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('AI ${res.statusCode}: ${utf8.decode(res.bodyBytes)}');
    }
    final j = jsonDecode(utf8.decode(res.bodyBytes));
    return Breakdown(j['workload_score'], j['reasoning'] ?? '', [
      for (final s in j['subtasks'])
        {'title': s['title'], 'plan_date': s['plan_date'], 'minutes': s['minutes']},
    ]);
  }
}
