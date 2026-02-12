import 'dart:math';
import 'package:flutter/material.dart';

/// Animated monster widget that displays a cute geometric creature
/// based on its element type with idle animations
class AnimatedMonster extends StatefulWidget {
  final MonsterType type;
  final double size;
  final bool isEgg;
  final double hatchProgress;
  final int rarityLevel; // 0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary

  const AnimatedMonster({
    super.key,
    required this.type,
    this.size = 100,
    this.isEgg = false,
    this.hatchProgress = 0,
    this.rarityLevel = 0,
  });

  @override
  State<AnimatedMonster> createState() => _AnimatedMonsterState();
}

class _AnimatedMonsterState extends State<AnimatedMonster>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _blinkController;
  late AnimationController _glowController;
  late Animation<double> _floatAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();

    // Floating/breathing animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Blink animation
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // Random blinking
    _startBlinkTimer();

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startBlinkTimer() {
    Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(3000)), () {
      if (mounted) {
        _blink();
        _startBlinkTimer();
      }
    });
  }

  void _blink() {
    if (!mounted) return;
    setState(() => _isBlinking = true);
    _blinkController.forward().then((_) {
      if (!mounted) return;
      _blinkController.reverse().then((_) {
        if (mounted) setState(() => _isBlinking = false);
      });
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _blinkController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEgg) {
      return _buildEgg();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _glowController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Rarity glow aura (for rare+)
                if (widget.rarityLevel >= 2)
                  Positioned.fill(
                    child: _buildRarityAura(),
                  ),
                _buildMonster(),
                // Sparkles for rare+ pets
                if (widget.rarityLevel >= 2)
                  ..._buildSparkles(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRarityAura() {
    final colors = _getRarityColors();
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.2 + _glowAnimation.value * 0.3),
            blurRadius: 20 + _glowAnimation.value * 10,
            spreadRadius: 5 + _glowAnimation.value * 5,
          ),
          if (widget.rarityLevel >= 4) // Legendary gets extra glow
            BoxShadow(
              color: colors.secondary.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 10,
            ),
        ],
      ),
    );
  }
  
  List<Widget> _buildSparkles() {
    final sparkles = <Widget>[];
    final sparkleCount = widget.rarityLevel >= 4 ? 6 : (widget.rarityLevel >= 3 ? 4 : 2);
    final colors = _getRarityColors();
    
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i / sparkleCount) * 2 * pi + _glowAnimation.value * pi;
      final distance = widget.size * 0.5 + sin(_glowAnimation.value * pi * 2 + i) * 5;
      final sparkleSize = 4.0 + (widget.rarityLevel - 2) * 2;
      
      sparkles.add(
        Positioned(
          left: widget.size / 2 + cos(angle) * distance - sparkleSize / 2,
          top: widget.size / 2 + sin(angle) * distance - sparkleSize / 2,
          child: Opacity(
            opacity: 0.5 + sin(_glowAnimation.value * pi * 2 + i * 0.5) * 0.5,
            child: Container(
              width: sparkleSize,
              height: sparkleSize,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return sparkles;
  }
  
  _RarityColors _getRarityColors() {
    switch (widget.rarityLevel) {
      case 2: // Rare - Blue
        return _RarityColors(
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFF64B5F6),
        );
      case 3: // Epic - Purple
        return _RarityColors(
          primary: const Color(0xFF9C27B0),
          secondary: const Color(0xFFCE93D8),
        );
      case 4: // Legendary - Gold
        return _RarityColors(
          primary: const Color(0xFFFFD700),
          secondary: const Color(0xFFFFA000),
        );
      default: // Common/Uncommon - no special colors
        return _RarityColors(
          primary: Colors.white,
          secondary: Colors.white70,
        );
    }
  }

  Widget _buildEgg() {
    final colors = _getTypeColors(widget.type);
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size * 1.2,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                colors.primary.withOpacity(0.3 + (_glowAnimation.value * widget.hatchProgress)),
                Colors.transparent,
              ],
              radius: 1.5,
            ),
          ),
          child: CustomPaint(
            painter: EggPainter(
              primaryColor: colors.primary,
              secondaryColor: colors.secondary,
              progress: widget.hatchProgress,
              wobble: widget.hatchProgress > 0.8 ? _floatAnimation.value / 8 : 0,
              rarityLevel: widget.rarityLevel,
            ),
            size: Size(widget.size, widget.size * 1.2),
          ),
        );
      },
    );
  }

  Widget _buildMonster() {
    final colors = _getTypeColors(widget.type);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(_glowAnimation.value * 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: CustomPaint(
        painter: MonsterPainter(
          type: widget.type,
          primaryColor: colors.primary,
          secondaryColor: colors.secondary,
          accentColor: colors.accent,
          isBlinking: _isBlinking,
          breathScale: _scaleAnimation.value,
        ),
        size: Size(widget.size, widget.size),
      ),
    );
  }

  _MonsterColors _getTypeColors(MonsterType type) {
    switch (type) {
      case MonsterType.fire:
        return _MonsterColors(
          primary: const Color(0xFFFF6B35),
          secondary: const Color(0xFFFFD93D),
          accent: const Color(0xFFFF3131),
        );
      case MonsterType.water:
        return _MonsterColors(
          primary: const Color(0xFF4ECDC4),
          secondary: const Color(0xFF44A3AA),
          accent: const Color(0xFF95E1D3),
        );
      case MonsterType.earth:
        return _MonsterColors(
          primary: const Color(0xFF8B7355),
          secondary: const Color(0xFFA0522D),
          accent: const Color(0xFF90EE90),
        );
      case MonsterType.air:
        return _MonsterColors(
          primary: const Color(0xFFB8D4E3),
          secondary: const Color(0xFFE8F4F8),
          accent: const Color(0xFF87CEEB),
        );
      case MonsterType.spirit:
        return _MonsterColors(
          primary: const Color(0xFFBA68C8),
          secondary: const Color(0xFF9C27B0),
          accent: const Color(0xFFE1BEE7),
        );
    }
  }
}

class _MonsterColors {
  final Color primary;
  final Color secondary;
  final Color accent;

  _MonsterColors({
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

class _RarityColors {
  final Color primary;
  final Color secondary;

  _RarityColors({
    required this.primary,
    required this.secondary,
  });
}

enum MonsterType { fire, water, earth, air, spirit }

/// Custom painter for the monster body
class MonsterPainter extends CustomPainter {
  final MonsterType type;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final bool isBlinking;
  final double breathScale;

  MonsterPainter({
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.isBlinking,
    required this.breathScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    switch (type) {
      case MonsterType.fire:
        _paintFireMonster(canvas, center, radius);
        break;
      case MonsterType.water:
        _paintWaterMonster(canvas, center, radius);
        break;
      case MonsterType.earth:
        _paintEarthMonster(canvas, center, radius);
        break;
      case MonsterType.air:
        _paintAirMonster(canvas, center, radius);
        break;
      case MonsterType.spirit:
        _paintSpiritMonster(canvas, center, radius);
        break;
    }
  }

  void _paintFireMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Body - flame-shaped blob
    final bodyPath = Path();
    bodyPath.moveTo(center.dx, center.dy - radius);
    bodyPath.quadraticBezierTo(
      center.dx + radius * 1.2, center.dy - radius * 0.3,
      center.dx + radius * 0.8, center.dy + radius * 0.5,
    );
    bodyPath.quadraticBezierTo(
      center.dx + radius * 0.5, center.dy + radius,
      center.dx, center.dy + radius * 0.8,
    );
    bodyPath.quadraticBezierTo(
      center.dx - radius * 0.5, center.dy + radius,
      center.dx - radius * 0.8, center.dy + radius * 0.5,
    );
    bodyPath.quadraticBezierTo(
      center.dx - radius * 1.2, center.dy - radius * 0.3,
      center.dx, center.dy - radius,
    );

    // Gradient fill
    paint.shader = RadialGradient(
      colors: [secondaryColor, primaryColor],
      center: const Alignment(0, -0.3),
      radius: 1.2,
    ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(bodyPath, paint);

    // Inner glow
    paint.shader = null;
    paint.color = secondaryColor.withOpacity(0.5);
    canvas.drawCircle(center + const Offset(0, 5), radius * 0.5, paint);

    // Eyes
    _paintEyes(canvas, center, radius * 0.7, isAngry: true);

    // Flame tips on head
    paint.color = secondaryColor;
    for (int i = 0; i < 3; i++) {
      final tipPath = Path();
      final xOffset = (i - 1) * radius * 0.4;
      tipPath.moveTo(center.dx + xOffset - 8, center.dy - radius * 0.6);
      tipPath.quadraticBezierTo(
        center.dx + xOffset, center.dy - radius * 1.1 - (i == 1 ? 10 : 0),
        center.dx + xOffset + 8, center.dy - radius * 0.6,
      );
      canvas.drawPath(tipPath, paint);
    }
  }

  void _paintWaterMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Body - droplet/blob shape
    paint.shader = RadialGradient(
      colors: [accentColor, primaryColor, secondaryColor],
      stops: const [0.0, 0.5, 1.0],
      center: const Alignment(-0.3, -0.3),
      radius: 1.0,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final bodyPath = Path();
    bodyPath.addOval(Rect.fromCircle(center: center + const Offset(0, 5), radius: radius));
    canvas.drawPath(bodyPath, paint);

    // Shine/highlight
    paint.shader = null;
    paint.color = Colors.white.withOpacity(0.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * 0.3, -radius * 0.3),
        width: radius * 0.5,
        height: radius * 0.3,
      ),
      paint,
    );

    // Cute bubble cheeks
    paint.color = accentColor.withOpacity(0.5);
    canvas.drawCircle(center + Offset(-radius * 0.5, radius * 0.2), radius * 0.15, paint);
    canvas.drawCircle(center + Offset(radius * 0.5, radius * 0.2), radius * 0.15, paint);

    // Eyes
    _paintEyes(canvas, center, radius * 0.7, isCute: true);

    // Small water droplet on head
    paint.color = accentColor;
    final dropPath = Path();
    dropPath.moveTo(center.dx, center.dy - radius * 1.1);
    dropPath.quadraticBezierTo(
      center.dx + 8, center.dy - radius * 0.85,
      center.dx, center.dy - radius * 0.75,
    );
    dropPath.quadraticBezierTo(
      center.dx - 8, center.dy - radius * 0.85,
      center.dx, center.dy - radius * 1.1,
    );
    canvas.drawPath(dropPath, paint);
  }

  void _paintEarthMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Body - chunky rounded square
    paint.shader = LinearGradient(
      colors: [secondaryColor, primaryColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center + const Offset(0, 5), width: radius * 1.8, height: radius * 1.6),
      Radius.circular(radius * 0.4),
    );
    canvas.drawRRect(bodyRect, paint);

    // Rocky texture spots
    paint.shader = null;
    paint.color = secondaryColor.withOpacity(0.6);
    canvas.drawCircle(center + Offset(-radius * 0.4, -radius * 0.2), radius * 0.15, paint);
    canvas.drawCircle(center + Offset(radius * 0.3, radius * 0.3), radius * 0.12, paint);
    canvas.drawCircle(center + Offset(-radius * 0.2, radius * 0.4), radius * 0.1, paint);

    // Grass/plant tuft on head
    paint.color = accentColor;
    for (int i = 0; i < 3; i++) {
      final grassPath = Path();
      final xOffset = (i - 1) * 10.0;
      grassPath.moveTo(center.dx + xOffset, center.dy - radius * 0.6);
      grassPath.quadraticBezierTo(
        center.dx + xOffset + (i - 1) * 5, center.dy - radius * 1.0,
        center.dx + xOffset + (i - 1) * 3, center.dy - radius * 0.6,
      );
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 4;
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(grassPath, paint);
    }
    paint.style = PaintingStyle.fill;

    // Eyes
    _paintEyes(canvas, center, radius * 0.6, isGrouchy: true);
  }

  void _paintAirMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Body - fluffy cloud shape
    paint.shader = RadialGradient(
      colors: [secondaryColor, primaryColor],
      center: const Alignment(0, -0.5),
      radius: 1.2,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Main cloud body (multiple overlapping circles)
    canvas.drawCircle(center + const Offset(0, 10), radius * 0.7, paint);
    canvas.drawCircle(center + Offset(-radius * 0.4, 5), radius * 0.5, paint);
    canvas.drawCircle(center + Offset(radius * 0.4, 5), radius * 0.5, paint);
    canvas.drawCircle(center + const Offset(0, -5), radius * 0.55, paint);

    // Soft highlights
    paint.shader = null;
    paint.color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(center + Offset(-radius * 0.2, -radius * 0.1), radius * 0.2, paint);

    // Swirl marks
    paint.color = accentColor.withOpacity(0.4);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    final swirlPath = Path();
    swirlPath.moveTo(center.dx - radius * 0.3, center.dy + radius * 0.3);
    swirlPath.quadraticBezierTo(
      center.dx, center.dy + radius * 0.5,
      center.dx + radius * 0.3, center.dy + radius * 0.3,
    );
    canvas.drawPath(swirlPath, paint);
    paint.style = PaintingStyle.fill;

    // Eyes
    _paintEyes(canvas, center + const Offset(0, -5), radius * 0.5, isDreamy: true);
  }

  void _paintSpiritMonster(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Ghostly aura
    paint.color = accentColor.withOpacity(0.2);
    canvas.drawCircle(center, radius * 1.2, paint);

    // Body - ethereal teardrop/ghost shape
    paint.shader = RadialGradient(
      colors: [accentColor, primaryColor, secondaryColor],
      stops: const [0.0, 0.5, 1.0],
      center: const Alignment(0, -0.3),
      radius: 1.0,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final bodyPath = Path();
    bodyPath.moveTo(center.dx, center.dy - radius);
    bodyPath.quadraticBezierTo(
      center.dx + radius, center.dy - radius * 0.3,
      center.dx + radius * 0.6, center.dy + radius * 0.5,
    );
    bodyPath.quadraticBezierTo(
      center.dx + radius * 0.3, center.dy + radius,
      center.dx, center.dy + radius * 0.7,
    );
    bodyPath.quadraticBezierTo(
      center.dx - radius * 0.3, center.dy + radius,
      center.dx - radius * 0.6, center.dy + radius * 0.5,
    );
    bodyPath.quadraticBezierTo(
      center.dx - radius, center.dy - radius * 0.3,
      center.dx, center.dy - radius,
    );
    canvas.drawPath(bodyPath, paint);

    // Mystical sparkles
    paint.shader = null;
    paint.color = Colors.white;
    final sparklePositions = [
      Offset(center.dx - radius * 0.5, center.dy - radius * 0.5),
      Offset(center.dx + radius * 0.6, center.dy - radius * 0.3),
      Offset(center.dx + radius * 0.3, center.dy + radius * 0.4),
    ];
    for (final pos in sparklePositions) {
      _paintSparkle(canvas, pos, 4, paint);
    }

    // Eyes
    _paintEyes(canvas, center + const Offset(0, -5), radius * 0.6, isMystical: true);
  }

  void _paintSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _paintEyes(
    Canvas canvas,
    Offset center,
    double spacing, {
    bool isAngry = false,
    bool isCute = false,
    bool isGrouchy = false,
    bool isDreamy = false,
    bool isMystical = false,
  }) {
    final paint = Paint()..style = PaintingStyle.fill;
    final eyeRadius = spacing * 0.25;
    final leftEye = center + Offset(-spacing * 0.35, 0);
    final rightEye = center + Offset(spacing * 0.35, 0);

    if (isBlinking) {
      // Closed eyes - simple lines
      paint.color = Colors.black87;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;
      paint.strokeCap = StrokeCap.round;
      canvas.drawLine(
        leftEye + Offset(-eyeRadius, 0),
        leftEye + Offset(eyeRadius, 0),
        paint,
      );
      canvas.drawLine(
        rightEye + Offset(-eyeRadius, 0),
        rightEye + Offset(eyeRadius, 0),
        paint,
      );
      return;
    }

    // Eye whites
    paint.style = PaintingStyle.fill;
    paint.color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: leftEye, width: eyeRadius * 2.2, height: eyeRadius * 2.5),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: rightEye, width: eyeRadius * 2.2, height: eyeRadius * 2.5),
      paint,
    );

    // Pupils
    paint.color = Colors.black87;
    final pupilOffset = isCute ? const Offset(0, 2) : Offset.zero;
    canvas.drawCircle(leftEye + pupilOffset, eyeRadius * 0.7, paint);
    canvas.drawCircle(rightEye + pupilOffset, eyeRadius * 0.7, paint);

    // Eye shine
    paint.color = Colors.white;
    canvas.drawCircle(leftEye + pupilOffset + Offset(-eyeRadius * 0.2, -eyeRadius * 0.2), eyeRadius * 0.25, paint);
    canvas.drawCircle(rightEye + pupilOffset + Offset(-eyeRadius * 0.2, -eyeRadius * 0.2), eyeRadius * 0.25, paint);

    // Expression-specific details
    if (isAngry) {
      paint.color = Colors.black87;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      // Angry eyebrows
      canvas.drawLine(
        leftEye + Offset(-eyeRadius, -eyeRadius * 1.5),
        leftEye + Offset(eyeRadius, -eyeRadius * 0.8),
        paint,
      );
      canvas.drawLine(
        rightEye + Offset(-eyeRadius, -eyeRadius * 0.8),
        rightEye + Offset(eyeRadius, -eyeRadius * 1.5),
        paint,
      );
    }

    if (isMystical) {
      // Third eye hint
      paint.color = secondaryColor.withOpacity(0.5);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(center + Offset(0, -spacing * 0.5), eyeRadius * 0.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MonsterPainter oldDelegate) {
    return oldDelegate.isBlinking != isBlinking ||
        oldDelegate.breathScale != breathScale;
  }
}

/// Custom painter for eggs with rarity-based visuals
class EggPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double progress;
  final double wobble;
  final int rarityLevel; // 0=common, 1=uncommon, 2=rare, 3=epic, 4=legendary

  EggPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.progress,
    required this.wobble,
    this.rarityLevel = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // Apply wobble rotation for hatching eggs
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(wobble * 0.1);
    canvas.translate(-center.dx, -center.dy);

    final w = size.width * 0.8;
    final h = size.height * 0.85;
    
    // Draw rarity glow for rare+ eggs
    if (rarityLevel >= 2) {
      final glowColor = _getRarityGlowColor();
      paint.color = glowColor.withOpacity(0.3);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      _drawEggShape(canvas, center, w * 1.1, h * 1.1, paint);
      paint.maskFilter = null;
    }

    // Egg base gradient - varies by rarity
    final colors = _getRarityColors();
    paint.shader = LinearGradient(
      colors: [colors.$1, colors.$2],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromCenter(center: center, width: size.width, height: size.height));

    _drawEggShape(canvas, center, w, h, paint);

    // Egg patterns based on rarity
    paint.shader = null;
    _drawRarityPattern(canvas, center, w, h, paint);

    // Shine highlight
    paint.color = Colors.white.withOpacity(0.4);
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(-w * 0.2, -h * 0.25), width: w * 0.2, height: h * 0.15),
      paint,
    );

    // Cracks for near-hatch eggs
    if (progress > 0.7) {
      _drawCracks(canvas, center, w, h, paint);
    }

    canvas.restore();
  }
  
  void _drawEggShape(Canvas canvas, Offset center, double w, double h, Paint paint) {
    final eggPath = Path();
    eggPath.moveTo(center.dx, center.dy - h / 2);
    eggPath.cubicTo(
      center.dx + w / 2, center.dy - h / 3,
      center.dx + w / 2, center.dy + h / 3,
      center.dx, center.dy + h / 2,
    );
    eggPath.cubicTo(
      center.dx - w / 2, center.dy + h / 3,
      center.dx - w / 2, center.dy - h / 3,
      center.dx, center.dy - h / 2,
    );
    canvas.drawPath(eggPath, paint);
  }
  
  (Color, Color) _getRarityColors() {
    switch (rarityLevel) {
      case 0: // Common - earthy brown
        return (const Color(0xFFD4A574), const Color(0xFFB8956E));
      case 1: // Uncommon - soft green
        return (const Color(0xFF98D4A0), const Color(0xFF6BBF7A));
      case 2: // Rare - sky blue
        return (const Color(0xFF7EC8E3), const Color(0xFF4FADD0));
      case 3: // Epic - royal purple
        return (const Color(0xFFB794D4), const Color(0xFF9B6DC6));
      case 4: // Legendary - golden
        return (const Color(0xFFFFD700), const Color(0xFFFFA500));
      default:
        return (primaryColor, secondaryColor);
    }
  }
  
  Color _getRarityGlowColor() {
    switch (rarityLevel) {
      case 2: return const Color(0xFF4FADD0);
      case 3: return const Color(0xFF9B6DC6);
      case 4: return const Color(0xFFFFD700);
      default: return Colors.transparent;
    }
  }
  
  void _drawRarityPattern(Canvas canvas, Offset center, double w, double h, Paint paint) {
    switch (rarityLevel) {
      case 0: // Common - simple spots
        paint.color = const Color(0xFFC49A6C).withOpacity(0.5);
        canvas.drawOval(
          Rect.fromCenter(center: center + Offset(-w * 0.15, -h * 0.1), width: w * 0.2, height: h * 0.12),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: center + Offset(w * 0.12, h * 0.15), width: w * 0.15, height: h * 0.1),
          paint,
        );
        break;
        
      case 1: // Uncommon - leaf pattern
        paint.color = const Color(0xFF4A9F5B).withOpacity(0.4);
        // Draw small leaf shapes
        for (int i = 0; i < 3; i++) {
          final yOffset = -h * 0.2 + i * h * 0.2;
          final xOffset = (i % 2 == 0 ? -1 : 1) * w * 0.15;
          _drawLeaf(canvas, center + Offset(xOffset, yOffset), w * 0.12, paint);
        }
        break;
        
      case 2: // Rare - wave pattern
        paint.color = const Color(0xFF2E8BC0).withOpacity(0.4);
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        for (int i = 0; i < 3; i++) {
          final yOffset = -h * 0.15 + i * h * 0.15;
          final wavePath = Path();
          wavePath.moveTo(center.dx - w * 0.3, center.dy + yOffset);
          wavePath.quadraticBezierTo(
            center.dx - w * 0.1, center.dy + yOffset - 5,
            center.dx, center.dy + yOffset,
          );
          wavePath.quadraticBezierTo(
            center.dx + w * 0.1, center.dy + yOffset + 5,
            center.dx + w * 0.3, center.dy + yOffset,
          );
          canvas.drawPath(wavePath, paint);
        }
        paint.style = PaintingStyle.fill;
        break;
        
      case 3: // Epic - star/sparkle pattern
        paint.color = const Color(0xFFE0C0F0).withOpacity(0.6);
        _drawSparkle(canvas, center + Offset(-w * 0.15, -h * 0.15), 6, paint);
        _drawSparkle(canvas, center + Offset(w * 0.18, h * 0.1), 5, paint);
        _drawSparkle(canvas, center + Offset(-w * 0.05, h * 0.2), 4, paint);
        break;
        
      case 4: // Legendary - crown/gem pattern
        paint.color = Colors.white.withOpacity(0.5);
        // Draw a small crown shape at top
        final crownPath = Path();
        crownPath.moveTo(center.dx - w * 0.15, center.dy - h * 0.15);
        crownPath.lineTo(center.dx - w * 0.1, center.dy - h * 0.25);
        crownPath.lineTo(center.dx, center.dy - h * 0.18);
        crownPath.lineTo(center.dx + w * 0.1, center.dy - h * 0.25);
        crownPath.lineTo(center.dx + w * 0.15, center.dy - h * 0.15);
        canvas.drawPath(crownPath, paint);
        
        // Draw gem shapes
        paint.color = const Color(0xFFFF6B6B).withOpacity(0.6);
        _drawGem(canvas, center + Offset(0, h * 0.1), w * 0.12, paint);
        break;
    }
  }
  
  void _drawLeaf(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size / 2);
    path.quadraticBezierTo(center.dx + size / 2, center.dy, center.dx, center.dy + size / 2);
    path.quadraticBezierTo(center.dx - size / 2, center.dy, center.dx, center.dy - size / 2);
    canvas.drawPath(path, paint);
  }
  
  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawGem(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.7, center.dy - size * 0.3);
    path.lineTo(center.dx + size * 0.5, center.dy + size);
    path.lineTo(center.dx - size * 0.5, center.dy + size);
    path.lineTo(center.dx - size * 0.7, center.dy - size * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }
  
  void _drawCracks(Canvas canvas, Offset center, double w, double h, Paint paint) {
    paint.color = Colors.black.withOpacity(0.3);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    
    final crackPath = Path();
    crackPath.moveTo(center.dx - 5, center.dy - h * 0.2);
    crackPath.lineTo(center.dx + 3, center.dy - h * 0.1);
    crackPath.lineTo(center.dx - 2, center.dy);
    crackPath.lineTo(center.dx + 5, center.dy + h * 0.1);
    
    canvas.drawPath(crackPath, paint);

    if (progress > 0.9) {
      final crack2 = Path();
      crack2.moveTo(center.dx + 10, center.dy - h * 0.15);
      crack2.lineTo(center.dx + 5, center.dy - h * 0.05);
      crack2.lineTo(center.dx + 12, center.dy + h * 0.05);
      canvas.drawPath(crack2, paint);
    }
    
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(covariant EggPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.wobble != wobble ||
           oldDelegate.rarityLevel != rarityLevel;
  }
}

