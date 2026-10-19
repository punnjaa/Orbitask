import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';

class OrbitStage extends StatefulWidget {
  const OrbitStage({super.key, required this.subject, required this.pct, required this.onToggle});
  final Subject subject;
  final double pct; // 0..1
  final void Function(Subtask) onToggle;
  @override
  State<OrbitStage> createState() => _OrbitStageState();
}

class _OrbitStageState extends State<OrbitStage> with SingleTickerProviderStateMixin {
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    final todo = s.subtasks.where((t) => !t.done).toList();
    return LayoutBuilder(builder: (context, box) {
      final c = Offset(box.maxWidth / 2, box.maxHeight / 2);
      final orbit = math.max(60.0, math.min(box.maxWidth, box.maxHeight) / 2 - 36);
      final r = bubbleRadius(widget.pct, minR: 52, maxR: math.min(100, orbit * .6));
      return AnimatedBuilder(
        animation: _spin,
        builder: (_, __) => Stack(children: [
          Center(
            child: Container(
              width: orbit * 2, height: orbit * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: s.color.withValues(alpha: .25)),
              ),
            ),
          ),
          for (var i = 0; i < todo.length; i++)
            Positioned(
              left: c.dx + orbit * math.cos(2 * math.pi * (i / todo.length + _spin.value)) - 32,
              top: c.dy + orbit * math.sin(2 * math.pi * (i / todo.length + _spin.value)) - 32,
              child: GestureDetector(
                onTap: () => widget.onToggle(todo[i]),
                child: Container(
                  width: 64, height: 64, padding: const EdgeInsets.all(6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF191D36),
                    border: Border.all(color: s.color, width: 1.5),
                  ),
                  child: Text(todo[i].title,
                      maxLines: 3, overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, height: 1.1)),
                ),
              ),
            ),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              width: r * 2, height: r * 2,
              decoration: BoxDecoration(shape: BoxShape.circle, color: s.color),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(s.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('${(widget.pct * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      );
    });
  }
}
