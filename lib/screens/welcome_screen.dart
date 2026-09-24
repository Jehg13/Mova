import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';
import '../services/mova_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  static Color primaryTeal = Color(0xFF0C2340);
  static Color darkBlue = Color(0xFF0C2340);
  static Color subtitleGrey = Color(0xFF64748B);
  static Color lightBlueBg = Color(0xFFEBF3F6);
  static Color backgroundColor = Color(0xFFF7F9FA);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _contentSlide;
  late final Animation<Offset> _imageSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1100),
    )..forward();
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(0, .8, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(begin: Offset(0, .12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(.18, 1, curve: Curves.easeOutCubic),
          ),
        );
    _imageSlide = Tween<Offset>(begin: Offset(0, -.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(0, .75, curve: Curves.easeOutBack),
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
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: WelcomeScreen.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;
            final titleSize = compact ? 23.0 : 27.0;
            return Stack(
              children: [
                _WelcomeDecorations(),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    compact ? 10 : 16,
                    24,
                    compact ? 12 : 18,
                  ),
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fade,
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: WelcomeScreen.lightBlueBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: WelcomeScreen.darkBlue,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              movaText("MOVA"),
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: WelcomeScreen.darkBlue,
                                letterSpacing: 2.2,
                              ),
                            ),
                            Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                l10n.text('finance'),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                  color: WelcomeScreen.subtitleGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SlideTransition(
                          position: _imageSlide,
                          child: FadeTransition(
                            opacity: _fade,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: compact ? 8 : 16,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFEAF2F8),
                                      Color(0xFFF7FAFC),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: Color(0xFFDCE7F2)),
                                ),
                                child: Image.asset(
                                  'assets/images/image.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SlideTransition(
                        position: _contentSlide,
                        child: FadeTransition(
                          opacity: _fade,
                          child: Column(
                            children: [
                              Text(
                                l10n.text('your_money'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  color: WelcomeScreen.darkBlue,
                                  height: 1.12,
                                ),
                              ),
                              SizedBox(height: compact ? 8 : 12),
                              Text(
                                l10n.text('welcome_subtitle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: WelcomeScreen.subtitleGrey,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: compact ? 14 : 20),
                              SizedBox(
                                width: double.infinity,
                                height: compact ? 48 : 52,
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterScreen(),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.rocket_launch_rounded,
                                    size: 19,
                                  ),
                                  label: Text(l10n.text('create_account')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WelcomeScreen.primaryTeal,
                                    foregroundColor: Colors.white,
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 9),
                              SizedBox(
                                width: double.infinity,
                                height: compact ? 46 : 50,
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LoginScreen(),
                                    ),
                                  ),
                                  icon: Icon(Icons.login_rounded, size: 19),
                                  label: Text(l10n.text('already_account')),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: WelcomeScreen.primaryTeal,
                                    side: BorderSide(color: Color(0xFFB9C9DB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 8 : 12),
                              Text(
                                l10n.text('home_summary'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: WelcomeScreen.subtitleGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeDecorations extends StatelessWidget {
  const _WelcomeDecorations();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -55,
            right: -45,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Color(0xFFE3EDF6).withValues(alpha: .7),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: -75,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                color: Color(0xFFEAF2F8).withValues(alpha: .8),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 45,
            right: 20,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Color(0xFFDCE7F2).withValues(alpha: .65),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
