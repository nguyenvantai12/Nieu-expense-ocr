import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingBarChart extends StatefulWidget {
  const SpendingBarChart({
    required this.days,
    required this.semanticLabel,
    super.key,
  });

  final List<({DateTime date, double total})> days;
  final String semanticLabel;

  @override
  State<SpendingBarChart> createState() => _SpendingBarChartState();
}

class _SpendingBarChartState extends State<SpendingBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant SpendingBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _WeeklyBarPainter(
              days: widget.days,
              progress: Curves.easeOutCubic.transform(_controller.value),
              textStyle: Theme.of(context).textTheme.bodySmall!,
              gridColor: Theme.of(context).colorScheme.outlineVariant,
              barColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  const _WeeklyBarPainter({
    required this.days,
    required this.progress,
    required this.textStyle,
    required this.gridColor,
    required this.barColor,
    required this.labelColor,
  });

  final List<({DateTime date, double total})> days;
  final double progress;
  final TextStyle textStyle;
  final Color gridColor;
  final Color barColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;
    const left = 48.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 36.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final maxValue = days.fold<double>(
      0,
      (largest, day) => day.total > largest ? day.total : largest,
    );
    final scale = maxValue <= 0 ? 1.0 : maxValue * 1.15;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var line = 0; line <= 3; line++) {
      final y = top + chartHeight * line / 3;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      final value = scale * (3 - line) / 3;
      _paintText(
        canvas,
        _compactAmount(value),
        Offset(0, y - 7),
        width: left - 6,
        style: textStyle.copyWith(color: labelColor, fontSize: 10),
        align: TextAlign.right,
      );
    }

    final slotWidth = chartWidth / days.length;
    final barWidth = math.min(30.0, slotWidth * 0.56);
    final radius = Radius.circular(barWidth / 2);
    for (var index = 0; index < days.length; index++) {
      final day = days[index];
      final height = chartHeight * day.total / scale * progress;
      final x = left + slotWidth * index + (slotWidth - barWidth) / 2;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top + chartHeight - height, barWidth, height),
        topLeft: radius,
        topRight: radius,
      );
      canvas.drawRRect(rect, Paint()..color = barColor);
      _paintText(
        canvas,
        DateFormat('d/M').format(day.date),
        Offset(left + slotWidth * index, size.height - bottom + 8),
        width: slotWidth,
        style: textStyle.copyWith(color: labelColor, fontSize: 10),
        align: TextAlign.center,
      );
    }
  }

  String _compactAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}tr';
    if (amount >= 1000) return '${(amount / 1000).round()}k';
    return amount.round().toString();
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double width,
    required TextStyle style,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter oldDelegate) =>
      oldDelegate.days != days ||
      oldDelegate.progress != progress ||
      oldDelegate.textStyle != textStyle ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.barColor != barColor ||
      oldDelegate.labelColor != labelColor;
}
