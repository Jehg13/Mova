import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _orbitController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, .7, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: .72, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, .8, curve: Curves.easeOutBack),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, .18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(.25, 1, curve: Curves.easeOutCubic),
      ),
    );
    _entranceController.forward();
    _goToWelcome();
  }

  Future<void> _goToWelcome() async {
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const WelcomeScreen(),
        transitionDuration: const Duration(milliseconds: 650),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF07182D), Color(0xFF0C2340), Color(0xFF163B61)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _orbitController,
              builder: (_, _) => CustomPaint(
                painter: _SplashOrbitPainter(_orbitController.value),
              ),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _scale,
                          child: Container(
                            width: 142,
                            height: 142,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(42),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7DD3FC)
                                      .withValues(alpha: .2),
                                  blurRadius: 45,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(34),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'MOVA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu dinero, en movimiento.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: .6,
                          ),
                        ),
                        const SizedBox(height: 42),
                        SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.white.withValues(alpha: .9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Text(
                'CONTROL • CLARIDAD • TRANQUILIDAD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .44),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashOrbitPainter extends CustomPainter {
  final double progress;

  _SplashOrbitPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .36;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .08);
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius * .72, paint);
    final dot = Offset(
      center.dx + math.cos(progress * math.pi * 2) * radius,
      center.dy + math.sin(progress * math.pi * 2) * radius,
    );
    canvas.drawCircle(
      dot,
      3.5,
      Paint()..color = const Color(0xFF7DD3FC).withValues(alpha: .8),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
