import 'package:flutter/material.dart';
import '../core/api.dart';
import '../data/repo.dart';
import '../models/models.dart';

const _palette = ['#7C6CF0', '#F0657A', '#2EC4B6', '#F4A259', '#5AA9E6', '#B8D45A'];

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key, required this.subjects});
  final List<Subject> subjects;
  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final subject = TextEditingController(), title = TextEditingController(), desc = TextEditingController();
  DateTime deadline = DateTime.now().add(const Duration(days: 7));
  double score = 50;
  String reasoning = '';
  bool busy = false;
  final List<Map<String, dynamic>> subs = [];

  String _d(DateTime d) => d.toIso8601String().substring(0, 10);

  void _msg(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _ai() async {
    if (subject.text.trim().isEmpty || desc.text.trim().isEmpty) return _msg('กรอกชื่อวิชาและรายละเอียดงานก่อน');
    setState(() => busy = true);
    try {
      final r = await ApiService.fetchTaskBreakdown(
        subject: subject.text.trim(),
        description: desc.text.trim(),
        deadline: _d(deadline),
        others: [for (final s in widget.subjects) {'name': s.name, 'remaining_score': s.remaining.round()}],
      );
      setState(() {
        subs..clear()..addAll(r.subtasks);
        score = r.score.toDouble().clamp(1, 100);
        reasoning = r.reasoning;
      });
    } catch (e) {
      _msg('AI ใช้งานไม่ได้: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _save() async {
    if (subject.text.trim().isEmpty || title.text.trim().isEmpty) return _msg('กรอกชื่อวิชาและชื่องาน');
    final name = subject.text.trim();
    final match = widget.subjects.where((s) => s.name.toLowerCase() == name.toLowerCase());
    setState(() => busy = true);
    try {
      await Repo.saveTask(
        subjectId: match.isEmpty ? null : match.first.id,
        subjectName: name,
        color: _palette[widget.subjects.length % _palette.length],
        title: title.text.trim(),
        desc: desc.text.trim(),
        deadline: _d(deadline),
        score: score.round(),
        subtasks: subs.where((s) => (s['title'] as String).trim().isNotEmpty).toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _msg('บันทึกไม่สำเร็จ: $e');
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('เพิ่มงาน')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: subject, decoration: const InputDecoration(labelText: 'วิชา')),
          const SizedBox(height: 10),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'ชื่องาน')),
          const SizedBox(height: 10),
          TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'รายละเอียดงานสั้นๆ')),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('กำหนดส่ง ${_d(deadline)}'),
            trailing: const Icon(Icons.event),
            onTap: () async {
              final d = await showDatePicker(
                  context: context, initialDate: deadline,
                  firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 730)));
              if (d != null) setState(() => deadline = d);
            },
          ),
          Text('ภาระงาน ${score.round()}/100'),
          Slider(value: score, min: 1, max: 100, onChanged: (v) => setState(() => score = v)),
          if (reasoning.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Orbi: $reasoning')),
          Row(children: [
            Expanded(child: FilledButton.icon(
                onPressed: busy ? null : _ai, icon: const Icon(Icons.auto_awesome),
                label: const Text('ให้ Orbi ช่วยแตกงาน'))),
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () => setState(() => subs.add({'title': '', 'plan_date': _d(DateTime.now()), 'minutes': 30})),
                child: const Text('เพิ่มเอง')),
          ]),
          if (busy) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
          const SizedBox(height: 8),
          for (final s in subs)
            Row(key: ObjectKey(s), children: [
              Expanded(child: TextFormField(
                  initialValue: s['title'], onChanged: (v) => s['title'] = v,
                  decoration: const InputDecoration(hintText: 'งานย่อย'))),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context, initialDate: DateTime.tryParse(s['plan_date']) ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 730)));
                  if (d != null) setState(() => s['plan_date'] = _d(d));
                },
                child: Text((s['plan_date'] as String).substring(5)),
              ),
              SizedBox(width: 52, child: TextFormField(
                  initialValue: '${s['minutes']}', keyboardType: TextInputType.number,
                  onChanged: (v) => s['minutes'] = int.tryParse(v) ?? 30,
                  decoration: const InputDecoration(suffixText: 'น.'))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => subs.remove(s))),
            ]),
          const SizedBox(height: 20),
          FilledButton(onPressed: busy ? null : _save, child: const Text('บันทึก')),
        ]),
      );
}
