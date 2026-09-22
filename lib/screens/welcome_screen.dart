import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color primaryTeal = Color(0xFF3398B1);
  static const Color darkBlue = Color(0xFF0C2340);
  static const Color subtitleGrey = Color(0xFF64748B);
  static const Color lightBlueBg = Color(0xFFEBF3F6);
  static const Color backgroundColor = Color(0xFFF7F9FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // LOGO
                        const Text(
                          "MOVA",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                            letterSpacing: 2.0,
                          ),
                        ),

                        // IMAGEN
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Image.asset(
                              'assets/images/image.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // TÍTULO
                        const Text(
                          'Tu dinero.\nTus metas.\nTu control.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: darkBlue,
                            height: 1.25,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SUBTÍTULO
                        const Text(
                          "Organiza tus finanzas, controla tus gastos y\n"
                          "alcanza tus objetivos con MOVA.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: subtitleGrey,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // BOTÓN: CREAR CUENTA
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // BOTÓN: YA TENGO UNA CUENTA
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              'Ya tengo una cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // FOOTER
                        const Text(
                          'Administra tu dinero de forma sencilla.',
                          style: TextStyle(fontSize: 12, color: subtitleGrey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}