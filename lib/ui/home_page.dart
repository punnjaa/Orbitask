import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repo.dart';
import '../models/models.dart';
import 'add_task_page.dart';
import 'orbit_stage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Subject> subjects = [];
  int sel = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Repo.load();
    if (!mounted) return;
    setState(() {
      subjects = s;
      sel = s.isEmpty ? 0 : sel.clamp(0, s.length - 1);
      loading = false;
    });
  }

  Future<void> _toggle(Subtask t) async {
    setState(() => t.done = !t.done); // วงกลมหด % ลดทันที
    await Repo.toggle(t.id, t.done);
  }

  Future<void> _add() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => AddTaskPage(subjects: subjects)));
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final pct = workloadPct(subjects);
    final todayItems = [
      for (final s in subjects)
        for (final t in s.subtasks)
          if (t.planDate == today) (s, t),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Orbitask', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _add, icon: const Icon(Icons.add), label: const Text('เพิ่มงาน')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : subjects.isEmpty
              ? const Center(child: Text('ยังไม่มีวิชา กด "เพิ่มงาน" เพื่อเริ่มต้น'))
              : Column(children: [
                  Expanded(
                    flex: 5,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: OrbitStage(
                        key: ValueKey(subjects[sel].id),
                        subject: subjects[sel],
                        pct: pct[subjects[sel].id] ?? 0,
                        onToggle: _toggle,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 92,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (var i = 0; i < subjects.length; i++)
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() => sel = i),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: bubbleRadius(pct[subjects[i].id] ?? 0, minR: 22, maxR: 38) * 2,
                                height: bubbleRadius(pct[subjects[i].id] ?? 0, minR: 22, maxR: 38) * 2,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: subjects[i].color.withValues(alpha: i == sel ? 1 : .5),
                                  border: i == sel ? Border.all(color: Colors.white, width: 2) : null,
                                ),
                                child: Text(subjects[i].name,
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                  Expanded(
                    flex: 3,
                    child: todayItems.isEmpty
                        ? const Center(child: Text('วันนี้ไม่มีงานย่อย พักได้เลย'))
                        : ListView(children: [
                            for (final (s, t) in todayItems)
                              CheckboxListTile(
                                value: t.done,
                                onChanged: (_) => _toggle(t),
                                activeColor: s.color,
                                title: Text(t.title,
                                    style: TextStyle(decoration: t.done ? TextDecoration.lineThrough : null)),
                                subtitle: Text('${s.name} · ${t.minutes} นาที'),
                              ),
                          ]),
                  ),
                ]),
    );
  }
}
