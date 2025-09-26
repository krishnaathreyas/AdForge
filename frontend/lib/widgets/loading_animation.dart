import 'package:flutter/material.dart';
import 'dart:math' as math;

class InteractiveLoadingWidget extends StatefulWidget {
  final double progress; // Add this parameter

  const InteractiveLoadingWidget({Key? key, required this.progress})
      : super(key: key);

  @override
  State<InteractiveLoadingWidget> createState() =>
      _InteractiveLoadingWidgetState();
}

class _InteractiveLoadingWidgetState extends State<InteractiveLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _orbitAnimation;

  @override
  void initState() {
    super.initState();

    // Main rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Pulse animation for the center
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Orbit animation for particles
    _orbitController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _orbitAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _orbitController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 150,
          height: 150,
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_rotationController, _pulseController, _orbitController]),
            builder: (context, child) {
              return CustomPaint(
                painter: LoadingPainter(
                  rotationValue: _rotationAnimation.value,
                  pulseValue: _pulseAnimation.value,
                  orbitValue: _orbitAnimation.value,
                  progress: widget.progress, // Pass progress to painter
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Add progress bar below the animation
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F3A),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 200 * widget.progress,
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFA855F7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Progress percentage
        Text(
          '${(widget.progress * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class LoadingPainter extends CustomPainter {
  final double rotationValue;
  final double pulseValue;
  final double orbitValue;
  final double progress; // Add progress parameter

  LoadingPainter({
    required this.rotationValue,
    required this.pulseValue,
    required this.orbitValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1F1F3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius - 10, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6366F1).withOpacity(0.8),
          const Color(0xFF8B5CF6).withOpacity(0.8),
          const Color(0xFFA855F7).withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw progress arc based on actual progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Progress-based sweep
      false,
      progressPaint,
    );

    // Draw outer ring with gradient (rotating animation)
    final outerRingPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6366F1).withOpacity(0.3),
          const Color(0xFF8B5CF6).withOpacity(0.3),
          const Color(0xFFA855F7).withOpacity(0.3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationValue);
    canvas.translate(-center.dx, -center.dy);

    // Draw animated arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 5),
      0,
      math.pi * 1.5,
      false,
      outerRingPaint,
    );
    canvas.restore();

    // Draw pulsing center circle
    final centerPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      15 * pulseValue,
      centerPaint,
    );

    // Draw orbiting particles
    final particlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (orbitValue + (i * math.pi / 3));
      final particleRadius = radius - 25;
      final particleX = center.dx + particleRadius * math.cos(angle);
      final particleY = center.dy + particleRadius * math.sin(angle);

      // Vary particle size based on position
      final particleSize = 3 + 2 * math.sin(angle * 2);

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        particlePaint,
      );
    }

    // Draw inner rotating elements
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-rotationValue * 1.5);

    final innerPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 4; i++) {
      canvas.rotate(math.pi / 2);
      canvas.drawLine(
        const Offset(0, -30),
        const Offset(0, -20),
        innerPaint,
      );
    }
    canvas.restore();

    // Draw trailing effect
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationValue);

    final trailPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withOpacity(0.8),
          const Color(0xFF6366F1).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 40))
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path()
        ..moveTo(radius - 15, 0)
        ..lineTo(radius - 5, -5)
        ..lineTo(radius - 5, 5)
        ..close(),
      trailPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LoadingPainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.orbitValue != orbitValue ||
        oldDelegate.progress != progress;
  }
}

// Fixed Flying Character Animation
class FlyingCharacterWidget extends StatefulWidget {
  final double progress; // Fix the progress property

  const FlyingCharacterWidget({super.key, required this.progress});

  @override
  State<FlyingCharacterWidget> createState() => _FlyingCharacterWidgetState();
}

class _FlyingCharacterWidgetState extends State<FlyingCharacterWidget>
    with TickerProviderStateMixin {
  late AnimationController _flyController;
  late AnimationController _bobController;
  late Animation<double> _flyAnimation;
  late Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();

    _flyController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _bobController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _flyAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _flyController,
      curve: Curves.linear,
    ));

    _bobAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _bobController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _flyController.dispose();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: AnimatedBuilder(
            animation: Listenable.merge([_flyController, _bobController]),
            builder: (context, child) {
              return CustomPaint(
                painter: FlyingCharacterPainter(
                  flyValue: _flyAnimation.value,
                  bobValue: _bobAnimation.value,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Loading Bar
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F3A),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 200 * widget.progress,
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFA855F7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Percentage text
        Text(
          '${(widget.progress * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class FlyingCharacterPainter extends CustomPainter {
  final double flyValue;
  final double bobValue;

  FlyingCharacterPainter({
    required this.flyValue,
    required this.bobValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = 60.0;

    // Calculate character position
    final characterX = center.dx + orbitRadius * math.cos(flyValue);
    final characterY = center.dy + orbitRadius * math.sin(flyValue) + bobValue;
    final characterPos = Offset(characterX, characterY);

    // Draw trail
    final trailPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final trailRadius = orbitRadius + 5;
    canvas.drawCircle(center, trailRadius, trailPaint);

    // Draw character (rocket/plane)
    canvas.save();
    canvas.translate(characterPos.dx, characterPos.dy);
    canvas.rotate(flyValue + math.pi / 2); // Face forward in flight direction

    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    // Draw rocket body
    final bodyPath = Path()
      ..moveTo(0, -12)
      ..lineTo(-4, 8)
      ..lineTo(4, 8)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Draw rocket fins
    final finPath = Path()
      ..moveTo(-4, 8)
      ..lineTo(-8, 12)
      ..lineTo(-2, 10)
      ..close();
    canvas.drawPath(finPath, accentPaint);

    final finPath2 = Path()
      ..moveTo(4, 8)
      ..lineTo(8, 12)
      ..lineTo(2, 10)
      ..close();
    canvas.drawPath(finPath2, accentPaint);

    // Draw flame/exhaust
    final flamePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.orange.withOpacity(0.8),
          Colors.red.withOpacity(0.4),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(-3, 8, 6, 15))
      ..style = PaintingStyle.fill;

    final flamePath = Path()
      ..moveTo(-3, 8)
      ..lineTo(0, 20 + bobValue.abs())
      ..lineTo(3, 8)
      ..close();
    canvas.drawPath(flamePath, flamePaint);

    canvas.restore();

    // Draw central loading indicator
    final centerPaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 12),
      -math.pi / 2,
      flyValue,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(FlyingCharacterPainter oldDelegate) {
    return oldDelegate.flyValue != flyValue || oldDelegate.bobValue != bobValue;
  }
}
