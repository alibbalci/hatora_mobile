import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});
  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final strokes = <List<Offset>>[];
  bool erasing = false;
  // TR: Karalama yalnızca yerel etkileşimdir; oturum veya iş kuralı değildir.
  // EN: Drawing is local interaction state, not a review session or business rule.
  void point(Offset position, Size size, {bool start = false}) {
    final normalized = Offset(
      (position.dx / size.width).clamp(0, 1),
      (position.dy / size.height).clamp(0, 1),
    );
    setState(() {
      if (erasing) {
        strokes.removeWhere(
          (stroke) => stroke.any((p) => (p - normalized).distance < .04),
        );
      } else {
        if (start || strokes.isEmpty) strokes.add([]);
        strokes.last.add(normalized);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Karalama alanı')),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Bu çizim kaydedilmez. Ekrandan çıkınca silinir.'),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Silgi'),
                selected: erasing,
                onSelected: (value) => setState(() => erasing = value),
              ),
              TextButton.icon(
                onPressed: strokes.isEmpty
                    ? null
                    : () => setState(() => strokes.removeLast()),
                icon: const Icon(Icons.undo),
                label: const Text('Geri al'),
              ),
              TextButton.icon(
                onPressed: strokes.isEmpty
                    ? null
                    : () => setState(strokes.clear),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Temizle'),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColoredBox(
                  color: AppColors.surface,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) =>
                            point(d.localPosition, size, start: true),
                        onPanUpdate: (d) => point(d.localPosition, size),
                        child: CustomPaint(
                          size: size,
                          painter: _DrawingPainter(
                            strokes.map(List<Offset>.of).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(this.strokes);
  final List<List<Offset>> strokes;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final pen = Paint()
      ..color = AppColors.primaryInk
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    Offset scale(Offset p) => Offset(p.dx * size.width, p.dy * size.height);
    for (final stroke in strokes) {
      if (stroke.length == 1) canvas.drawCircle(scale(stroke.first), 1.25, pen);
      for (var i = 1; i < stroke.length; i++) {
        canvas.drawLine(scale(stroke[i - 1]), scale(stroke[i]), pen);
      }
    }
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
