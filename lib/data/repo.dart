import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

final sb = Supabase.instance.client;

class Repo {
  static Future<List<Subject>> load() async {
    final rows = await sb.from('subjects').select('*, tasks(*, subtasks(*))').order('created_at');
    return [for (final r in (rows as List)) Subject.fromJson(r)];
  }

  static Future<void> toggle(String id, bool done) async {
    await sb.from('subtasks').update({'done': done}).eq('id', id);
  }

  static Future<void> saveTask({
    String? subjectId,
    required String subjectName,
    required String color,
    required String title,
    String? desc,
    required String deadline,
    required int score,
    required List<Map<String, dynamic>> subtasks,
  }) async {
    var sid = subjectId;
    sid ??= (await sb.from('subjects').insert({'name': subjectName, 'color': color}).select().single())['id'] as String;
    final task = await sb.from('tasks').insert({
      'subject_id': sid, 'title': title, 'description': desc,
      'deadline': deadline, 'workload_score': score,
    }).select().single();
    if (subtasks.isNotEmpty) {
      await sb.from('subtasks').insert([
        for (final s in subtasks)
          {'task_id': task['id'], 'title': s['title'], 'plan_date': s['plan_date'], 'minutes': s['minutes']},
      ]);
    }
  }
}
