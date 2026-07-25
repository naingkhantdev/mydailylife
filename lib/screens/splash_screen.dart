import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import '../providers/firestore_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dark_hero_card.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
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

    final isSignedIn = FirebaseAuth.instance.currentUser != null;
    if (isSignedIn) {
      ref.read(currentUserIdProvider.notifier).state = 'local-user';
    }

    final destinationRoute = isSignedIn ? AppRoutes.home : AppRoutes.login;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: destinationRoute),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, secondaryAnimation) =>
            isSignedIn ? const HomeScreen() : const LoginScreen(),
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
                          child: const DarkHeroBadge(
                            icon: Icons.wb_twilight_rounded,
                            label: 'A BETTER DAILY RHYTHM',
                          ),
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
                                    color: AppColors.onInkMuted,
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
                colors: [Color(0xFFC4B5FD), AppColors.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
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
                  color: AppColors.onInkFaint,
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
      AppColors.onInkAccent,
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
