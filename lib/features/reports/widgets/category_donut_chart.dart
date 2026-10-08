import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_category.dart';

typedef CategorySpending = ({ExpenseCategory category, double amount});

class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({required this.items, super.key});

  final List<CategorySpending> items;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedIndex;

  double get _total => widget.items.fold(0, (sum, item) => sum + item.amount);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _selectedIndex = null;
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
    final total = _total;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, 220);
            return SizedBox(
              height: size.height,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final painter = _DonutPainter(
                    items: widget.items,
                    total: total,
                    progress: CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    ).value,
                    selectedIndex: _selectedIndex,
                    mutedColor: Theme.of(context).colorScheme.outlineVariant,
                  );
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final index = painter.segmentAt(
                        details.localPosition,
                        size,
                      );
                      if (index == null) return;
                      setState(() => _selectedIndex = index);
                      _showCategoryDetails(context, widget.items[index], total);
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(size: size, painter: painter),
                        Center(
                          child: Semantics(
                            label:
                                'Tổng chi tiêu tháng này: ${formatVND(total)}',
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tổng tháng',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatVND(total),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < widget.items.length; index++)
          _LegendRow(
            item: widget.items[index],
            total: total,
            selected: index == _selectedIndex,
            onTap: () {
              setState(() => _selectedIndex = index);
              _showCategoryDetails(context, widget.items[index], total);
            },
          ),
      ],
    );
  }

  void _showCategoryDetails(
    BuildContext context,
    CategorySpending item,
    double total,
  ) {
    final share = total == 0 ? 0 : item.amount / total * 100;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.category.icon, color: item.category.color, size: 32),
              const SizedBox(height: 12),
              Text(
                item.category.displayName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                formatVND(item.amount),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('${share.toStringAsFixed(1)}% tổng chi tiêu tháng'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.item,
    required this.total,
    required this.selected,
    required this.onTap,
  });

  final CategorySpending item;
  final double total;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0 : item.amount / total * 100;
    return Semantics(
      button: true,
      label:
          '${item.category.displayName}, ${formatVND(item.amount)}, ${share.toStringAsFixed(1)} phần trăm',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          child: Row(
            children: [
              Icon(item.category.icon, color: item.category.color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(item.category.displayName)),
              Text(formatVND(item.amount)),
              const SizedBox(width: 10),
              SizedBox(
                width: 42,
                child: Text('${share.round()}%', textAlign: TextAlign.end),
              ),
              if (selected)
                const SizedBox(width: 4, child: Icon(Icons.check, size: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.items,
    required this.total,
    required this.progress,
    required this.selectedIndex,
    required this.mutedColor,
  });

  final List<CategorySpending> items;
  final double total;
  final double progress;
  final int? selectedIndex;
  final Color mutedColor;

  int? segmentAt(Offset point, Size size) {
    if (total <= 0) return null;
    final center = Offset(size.width / 2, size.height / 2);
    final distance = (point - center).distance;
    final radius = math.min(size.width, size.height) * 0.38;
    if (distance < radius * 0.62 || distance > radius * 1.2) return null;

    var angle =
        math.atan2(point.dy - center.dy, point.dx - center.dx) + math.pi / 2;
    angle = (angle + math.pi * 2) % (math.pi * 2);
    var swept = 0.0;
    for (var index = 0; index < items.length; index++) {
      swept += items[index].amount / total * math.pi * 2;
      if (angle <= swept) return index;
    }
    return items.isEmpty ? null : items.length - 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.38;
    final strokeWidth = radius * 0.3;
    if (total <= 0) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = mutedColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
      return;
    }

    var startAngle = -math.pi / 2;
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final sweep = item.amount / total * math.pi * 2 * progress;
      final midAngle = startAngle + sweep / 2;
      final offset = index == selectedIndex
          ? Offset(math.cos(midAngle) * 5, math.sin(midAngle) * 5)
          : Offset.zero;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.max(0, sweep - 0.018),
        false,
        Paint()
          ..color = item.category.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.items != items ||
      oldDelegate.total != total ||
      oldDelegate.progress != progress ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.mutedColor != mutedColor;
}
