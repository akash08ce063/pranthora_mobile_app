import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularAudioVisualizer extends StatefulWidget {
  final double amplitude; // 0.0 to 1.0
  final double size;
  final Color color;

  const CircularAudioVisualizer({
    super.key,
    required this.amplitude,
    this.size = 180,
    this.color = Colors.white,
  });

  @override
  State<CircularAudioVisualizer> createState() =>
      _CircularAudioVisualizerState();
}

class _CircularAudioVisualizerState extends State<CircularAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        _time += 0.05;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _SiriWavePainter(
        amplitude: widget.amplitude,
        time: _time,
        color: widget.color,
      ),
    );
  }
}

class _SiriWavePainter extends CustomPainter {
  final double amplitude;
  final double time;
  final Color color;

  _SiriWavePainter({
    required this.amplitude,
    required this.time,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height * 0.6;

    // Draw multiple waves with different properties for Siri effect
    _drawWave(
      canvas,
      center,
      width,
      height,
      amplitude: amplitude * 30 + 5,
      frequency: 2.5,
      phase: time * 1.2,
      opacity: 0.15,
      strokeWidth: 3.0,
    );

    _drawWave(
      canvas,
      center,
      width,
      height,
      amplitude: amplitude * 25 + 8,
      frequency: 3.0,
      phase: time * 1.5,
      opacity: 0.25,
      strokeWidth: 2.5,
    );

    _drawWave(
      canvas,
      center,
      width,
      height,
      amplitude: amplitude * 35 + 10,
      frequency: 2.0,
      phase: time * 1.0,
      opacity: 0.35,
      strokeWidth: 3.5,
    );

    _drawWave(
      canvas,
      center,
      width,
      height,
      amplitude: amplitude * 40 + 12,
      frequency: 1.5,
      phase: time * 0.8,
      opacity: 0.5,
      strokeWidth: 4.0,
    );

    _drawWave(
      canvas,
      center,
      width,
      height,
      amplitude: amplitude * 45 + 15,
      frequency: 1.2,
      phase: time * 0.6,
      opacity: 0.7,
      strokeWidth: 4.5,
    );

    // Main prominent wave
    _drawWave(
      canvas,
      center,
      width,
      height,
      amplitude: amplitude * 50 + 18,
      frequency: 1.0,
      phase: time * 0.5,
      opacity: 0.9,
      strokeWidth: 5.0,
    );
  }

  void _drawWave(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    {
    required double amplitude,
    required double frequency,
    required double phase,
    required double opacity,
    required double strokeWidth,
  }) {
    final path = Path();
    final points = 200;
    bool firstPoint = true;

    for (int i = 0; i < points; i++) {
      final x = (i / points) * width;
      final normalizedX = (x - width / 2) / (width / 2);

      // Create smooth wave using multiple sine waves
      final wave1 = math.sin(normalizedX * math.pi * frequency + phase);
      final wave2 = math.sin(normalizedX * math.pi * frequency * 1.5 + phase * 1.3) * 0.5;
      final wave3 = math.sin(normalizedX * math.pi * frequency * 0.7 + phase * 0.8) * 0.3;
      
      final combinedWave = wave1 + wave2 + wave3;

      // Apply envelope to make waves fade at edges
      final envelope = math.exp(-math.pow(normalizedX, 2) * 2);
      
      final y = center.dy + combinedWave * amplitude * envelope;

      if (firstPoint) {
        path.moveTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SiriWavePainter oldDelegate) {
    return oldDelegate.amplitude != amplitude || oldDelegate.time != time;
  }
}

