import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

class BudgetGauge extends StatefulWidget {
  const BudgetGauge({required this.spent, required this.budget, super.key});

  final double spent;
  final double budget;

  @override
  State<BudgetGauge> createState() => _BudgetGaugeState();
}

class _BudgetGaugeState extends State<BudgetGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double get _usage => widget.budget <= 0 ? 0 : widget.spent / widget.budget;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant BudgetGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spent != widget.spent || oldWidget.budget != widget.budget) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.budget <= 0) {
      return const Center(
        child: Text('Hãy đặt ngân sách tháng trong Cài đặt.'),
      );
    }

    final usage = _usage;
    final color = _usageColor(usage);
    return Semantics(
      label:
          'Đã chi ${formatVND(widget.spent)} trên ngân sách ${formatVND(widget.budget)}, sử dụng ${(usage * 100).round()} phần trăm',
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _GaugePainter(
                  progress: (usage.clamp(0.0, 1.0) * _controller.value)
                      .toDouble(),
                  color: color,
                  trackColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  needleColor: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Text(
            '${(usage * 100).round()}%',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('${formatVND(widget.spent)} / ${formatVND(widget.budget)}'),
          const SizedBox(height: 4),
          Text(
            usage >= 1
                ? 'Đã vượt ngân sách tháng'
                : 'Còn ${formatVND(widget.budget - widget.spent)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Color _usageColor(double usage) {
    if (usage >= 0.9) return const Color(0xFFC62828);
    if (usage >= 0.7) return const Color(0xFFE09A00);
    return const Color(0xFF2E7D32);
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.needleColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final Color needleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.88);
    final radius = math.min(size.width * 0.42, size.height * 0.82);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final strokeWidth = radius * 0.13;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    final needleAngle = startAngle + sweepAngle * progress;
    final needleLength = radius * 0.78;
    final needleEnd = Offset(
      center.dx + math.cos(needleAngle) * needleLength,
      center.dy + math.sin(needleAngle) * needleLength,
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = needleColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, strokeWidth * 0.35, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.needleColor != needleColor;
}
