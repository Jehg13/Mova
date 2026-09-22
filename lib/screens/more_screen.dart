import 'package:flutter/material.dart';

import 'login_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const Color backgroundColor = Color(0xFFF1F5F9);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color subtitleGrey = Color(0xFF64748B);
  static const Color sectionHeaderColor = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TÍTULO Y SUBTÍTULO ---
              const Text(
                "Más",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: darkNavy,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Personaliza tu experiencia en MOVA",
                style: TextStyle(
                  fontSize: 13,
                  color: subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),

              // --- PERFIL DE USUARIO ---
              _buildCardContainer(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFCBD5E1),
                      radius: 20,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: const Text(
                      "Jesús",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: darkNavy,
                      ),
                    ),
                    subtitle: const Text(
                      "Mi cuenta",
                      style: TextStyle(fontSize: 12, color: subtitleGrey),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF94A3B8),
                    ),
                    onTap: () {},
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: FINANZAS ---
              _buildSectionTitle("FINANZAS"),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.monetization_on_outlined,
                      title: "Presupuesto",
                      subtitle: "Define cuánto quieres gastar",
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      icon: Icons.label_outline,
                      title: "Categorías",
                      subtitle: "Administra tus categorías de ingresos y gastos",
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: APLICACIÓN ---
              _buildSectionTitle("APLICACIÓN"),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.dark_mode_outlined,
                      title: "Apariencia",
                      subtitle: "Claro / Oscuro / Sistema",
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      icon: Icons.notifications_none_outlined,
                      title: "Notificaciones",
                      subtitle: "Gestiona tus recordatorios",
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      icon: Icons.lock_outline,
                      title: "Seguridad",
                      subtitle: "Protege tu información",
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: DATOS ---
              _buildSectionTitle("DATOS"),
              _buildCardContainer(
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.upload_outlined,
                      title: "Exportar datos",
                      subtitle: "Descarga tus movimientos",
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      icon: Icons.download_outlined,
                      title: "Importar datos",
                      subtitle: "Importa información existente",
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: INFORMACIÓN ---
              _buildSectionTitle("INFORMACIÓN"),
              _buildCardContainer(
                child: _buildOptionTile(
                  icon: Icons.info_outline,
                  title: "Acerca de MOVA",
                  subtitle: "Versión 1.0.0",
                  onTap: () {},
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: CUENTA (CERRAR SESIÓN) ---
              _buildSectionTitle("CUENTA"),
              _buildCardContainer(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      // Redirige al Login y borra las rutas anteriores de navegación
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Row(
                        children: const [
                          Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "Cerrar sesión",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: sectionHeaderColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, color: darkNavy, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: darkNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 52,
    );
  }
}