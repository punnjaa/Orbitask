import 'dart:math' as math;
import 'package:flutter/material.dart';

Color hexColor(String h) => Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));

class Subtask {
  final String id, taskId, title, planDate;
  final int minutes;
  bool done;
  Subtask({required this.id, required this.taskId, required this.title,
      required this.planDate, required this.minutes, required this.done});
  factory Subtask.fromJson(Map<String, dynamic> j) => Subtask(
      id: j['id'], taskId: j['task_id'], title: j['title'],
      planDate: j['plan_date'], minutes: j['minutes'], done: j['done']);
}

class Task {
  final String id, title, deadline;
  final int score;
  final List<Subtask> subtasks;
  Task({required this.id, required this.title, required this.deadline,
      required this.score, required this.subtasks});
  factory Task.fromJson(Map<String, dynamic> j) => Task(
      id: j['id'], title: j['title'], deadline: j['deadline'], score: j['workload_score'],
      subtasks: [for (final s in (j['subtasks'] as List? ?? [])) Subtask.fromJson(s)]);

  /// ภาระคงเหลือ = score x (นาทีที่ยังไม่ทำ / นาทีทั้งหมด)
  double get remaining {
    final total = subtasks.fold<int>(0, (a, s) => a + s.minutes);
    if (total == 0) return 0;
    final left = subtasks.where((s) => !s.done).fold<int>(0, (a, s) => a + s.minutes);
    return score * left / total;
  }
}

class Subject {
  final String id, name;
  final Color color;
  final List<Task> tasks;
  Subject({required this.id, required this.name, required this.color, required this.tasks});
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
      id: j['id'], name: j['name'], color: hexColor(j['color'] ?? '#6C63FF'),
      tasks: [for (final t in (j['tasks'] as List? ?? [])) Task.fromJson(t)]);
  List<Subtask> get subtasks => [for (final t in tasks) ...t.subtasks];
  double get remaining => tasks.fold(0.0, (a, t) => a + t.remaining);
}

/// subjectId -> สัดส่วน 0..1 ของภาระคงเหลือทั้งหมด
Map<String, double> workloadPct(List<Subject> all) {
  final sum = all.fold(0.0, (a, s) => a + s.remaining);
  return {for (final s in all) s.id: sum == 0 ? 0.0 : s.remaining / sum};
}

/// รัศมีวงกลม: ใช้รากที่สองเพื่อให้ "พื้นที่" แปรผันตามภาระงาน
double bubbleRadius(double pct, {double minR = 36, double maxR = 96}) =>
    minR + (maxR - minR) * math.sqrt(pct.clamp(0.0, 1.0));
