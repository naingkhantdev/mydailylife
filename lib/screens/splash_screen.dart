import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_screen.dart';
import '../widgets/app_drawer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entranceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addStatusListener(_handleAnimationStatus);
    _entranceAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.38, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.home),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101229),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _DayCycleBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Semantics(
                    label: 'RoutineSync is preparing your day',
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _entranceAnimation,
                          child: const _RoutineBadge(),
                        ),
                        const Spacer(),
                        FadeTransition(
                          opacity: _entranceAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(_entranceAnimation),
                            child: Column(
                              children: [
                                _OrbitLogo(progress: _controller.value),
                                const SizedBox(height: 38),
                                const _AppTitle(),
                                const SizedBox(height: 12),
                                const Text(
                                  'Your day, in rhythm.',
                                  style: TextStyle(
                                    color: Color(0xFFC7CBE7),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        _LoadingStatus(progress: _controller.value),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineBadge extends StatelessWidget {
  const _RoutineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_twilight_rounded, color: Color(0xFFA5B4FC), size: 16),
          SizedBox(width: 8),
          Text(
            'A BETTER DAILY RHYTHM',
            style: TextStyle(
              color: Color(0xFFE4E7F7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitLogo extends StatelessWidget {
  const _OrbitLogo({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final size = (screenWidth * 0.56).clamp(210.0, 270.0).toDouble();

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _OrbitPainter(progress),
        child: Center(
          child: Container(
            width: size * 0.56,
            height: size * 0.56,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC4B5FD), Color(0xFF5B5BD6)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x665B5BD6),
                  blurRadius: 44,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/app_icon/app_icon.png',
                fit: BoxFit.cover,
                cacheWidth: 512,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Routine'),
          TextSpan(
            text: 'Sync',
            style: TextStyle(color: Color(0xFF8B8CF8)),
          ),
        ],
      ),
      style: TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
    );
  }
}

class _LoadingStatus extends StatelessWidget {
  const _LoadingStatus({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preparing your day',
                style: TextStyle(
                  color: Color(0xFF9AA1BD),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                progress > 0.78
                    ? Icons.check_circle_rounded
                    : Icons.auto_awesome_rounded,
                color: const Color(0xFF8B8CF8),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF252848),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF8B8CF8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCycleBackground extends StatelessWidget {
  const _DayCycleBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF101229),
                Color(0xFF202556),
                Color(0xFF191D40),
              ],
            ),
          ),
        ),
        CustomPaint(painter: _RhythmLinesPainter()),
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = size.width * 0.43;
    final innerRadius = size.width * 0.36;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    linePaint.color = const Color(0x338B8CF8);
    canvas.drawCircle(center, outerRadius, linePaint);
    linePaint.color = const Color(0x22FFFFFF);
    canvas.drawCircle(center, innerRadius, linePaint);

    final movingAngle = (-math.pi / 2) + (progress * math.pi * 2);
    final movingPoint = center + Offset(
      math.cos(movingAngle) * outerRadius,
      math.sin(movingAngle) * outerRadius,
    );
    canvas.drawCircle(
      movingPoint,
      7,
      Paint()
        ..color = const Color(0xFF8B8CF8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(movingPoint, 4, Paint()..color = Colors.white);

    const nodeColors = [
      Color(0xFFFFC857),
      Color(0xFF8B8CF8),
      Color(0xFFA5B4FC),
      Color(0xFFF2F1FF),
    ];
    for (var index = 0; index < nodeColors.length; index++) {
      final angle = (-math.pi / 2) + (index * math.pi / 2);
      final point = center + Offset(
        math.cos(angle) * innerRadius,
        math.sin(angle) * innerRadius,
      );
      canvas.drawCircle(point, 3, Paint()..color = nodeColors[index]);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RhythmLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0C8B8CF8)
      ..strokeWidth = 1;
    const gap = 46.0;

    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
