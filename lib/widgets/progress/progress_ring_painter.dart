import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom painter for animated circular progress ring
/// 动画环形进度条的自定义画笔
class ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;
  final bool showGlow;

  /// Creates a progress ring painter with configurable colors, width, and glow
  /// 创建可配置颜色、宽度和发光效果的进度环画笔
  ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 14.0,
    this.showGlow = true,
  });

  /// Paints the background circle, optional glow, and progress arc
  /// 绘制背景圆环、可选发光效果和进度弧
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Add glow effect
    if (showGlow) {
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final glowRect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        glowRect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
    }

    // Draw progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  /// Returns true if any visual property changed, triggering a repaint
  /// 当任何视觉属性变化时返回 true，触发重绘
  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showGlow != showGlow;
  }
}
