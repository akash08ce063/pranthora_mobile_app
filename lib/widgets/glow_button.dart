import 'package:flutter/material.dart';

class GlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final double size;
  final Color color;
  final Color glowColor;
  final bool isGlowing;

  const GlowButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.size = 80,
    this.color = Colors.white,
    this.glowColor = const Color(0xFF0A84FF),
    this.isGlowing = false,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isGlowing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGlowing != oldWidget.isGlowing) {
      if (widget.isGlowing) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _isPressed = false;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return AnimatedScale(
                scale: _isPressed ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated glow rings
                    if (widget.isGlowing) ...[
                      Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: widget.size + 40,
                          height: widget.size + 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.glowColor.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.5,
                        child: Container(
                          width: widget.size + 20,
                          height: widget.size + 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.glowColor.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Main button with rotating glow
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color,
                        boxShadow: widget.isGlowing
                            ? [
                                BoxShadow(
                                  color: widget.glowColor.withValues(alpha: 0.6),
                                  blurRadius: 20 * _pulseAnimation.value,
                                  spreadRadius: 5 * _pulseAnimation.value,
                                ),
                                BoxShadow(
                                  color: widget.glowColor.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: widget.size * 0.45,
                          color: widget.color == Colors.white
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

