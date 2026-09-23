import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../database/database_helper.dart';
import '../widgets/mova_feedback_dialog.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const Color primaryTeal = Color(0xFF0C2340);
  static const Color darkNavy = Color(0xFF0C2340);
  static const Color subtitleGrey = Color(0xFF64748B);
  static const Color inputBorderGrey = Color(0xFFE2E8F0);
  static const Color backgroundColor = Color(0xFFF1F5F9);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  int get _passwordScore {
    final password = _passwordController.text;
    var score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    return score;
  }

  bool get _validEmail =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
          .hasMatch(_emailController.text.trim());

  Future<void> _showTerms(String title, String message) {
    final isPrivacy = title.toLowerCase().contains('privacidad');
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: RegisterScreen.darkNavy.withValues(alpha: .58),
      builder: (context) => _LegalDocumentSheet(
        title: title,
        subtitle: message,
        icon: isPrivacy ? Icons.privacy_tip_rounded : Icons.gavel_rounded,
        sections: isPrivacy ? _privacySections : _termsSections,
      ),
    );
  }

  static const _termsSections = <_LegalSection>[
    _LegalSection(
      title: '1. Aceptación del servicio',
      body: 'Al crear una cuenta y utilizar MOVA confirmas que leíste, comprendiste y aceptas estos términos. Si no estás de acuerdo, no debes completar el registro ni utilizar la aplicación.',
    ),
    _LegalSection(
      title: '2. Uso de MOVA',
      body: 'MOVA es una herramienta de organización financiera personal. Puedes registrar ingresos, gastos, metas, presupuestos y listas para tu propio control. La información que ingreses debe ser verdadera y corresponder a tu actividad.',
    ),
    _LegalSection(
      title: '3. Tu cuenta',
      body: 'Eres responsable de mantener la confidencialidad de tu correo y contraseña, así como de toda actividad realizada desde tu cuenta. Si detectas un acceso no autorizado, cambia tu contraseña y deja de utilizar el dispositivo comprometido.',
    ),
    _LegalSection(
      title: '4. Información financiera',
      body: 'Los cálculos, resúmenes y análisis de MOVA son orientativos y dependen de los datos que registres. La aplicación no sustituye asesoría financiera, contable, fiscal o legal profesional.',
    ),
    _LegalSection(
      title: '5. Uso responsable',
      body: 'No debes intentar alterar la aplicación, acceder a cuentas ajenas, introducir información maliciosa ni utilizar MOVA para actividades ilegales. El uso indebido puede ocasionar la suspensión del acceso.',
    ),
    _LegalSection(
      title: '6. Cambios y disponibilidad',
      body: 'Podemos mejorar, actualizar o modificar funciones de MOVA para mantener una experiencia segura y útil. Procuraremos conservar tus datos y avisarte cuando un cambio sea relevante para el servicio.',
    ),
  ];

  static const _privacySections = <_LegalSection>[
    _LegalSection(
      title: '1. Qué información guardamos',
      body: 'MOVA puede guardar tu nombre, correo electrónico, contraseña, foto de perfil, movimientos, metas, presupuestos, categorías, listas de compras y preferencias necesarias para ofrecerte sus funciones.',
    ),
    _LegalSection(
      title: '2. Para qué la utilizamos',
      body: 'Utilizamos esta información para crear y proteger tu cuenta, mostrar tus finanzas, generar resúmenes y análisis, personalizar la aplicación y conservar tus configuraciones.',
    ),
    _LegalSection(
      title: '3. Almacenamiento local',
      body: 'La información financiera de MOVA se almacena localmente en el dispositivo para que puedas utilizar la aplicación. Si desinstalas la aplicación, cambias de dispositivo o borras sus datos, podrías perder la información que no hayas respaldado.',
    ),
    _LegalSection(
      title: '4. Protección de tus datos',
      body: 'Aplicamos medidas razonables para proteger la información dentro de la aplicación. Aun así, ninguna aplicación o dispositivo es completamente invulnerable; por eso te recomendamos usar un bloqueo de pantalla y no compartir tus credenciales.',
    ),
    _LegalSection(
      title: '5. Tus decisiones',
      body: 'Puedes editar o eliminar la información disponible desde las funciones de MOVA. También puedes eliminar tu foto de perfil, actualizar tu contraseña y desactivar opciones de seguridad o notificaciones desde la sección Más.',
    ),
    _LegalSection(
      title: '6. Compartir información',
      body: 'MOVA no vende tu información personal. No compartimos tus datos financieros con terceros salvo que sea necesario para cumplir una obligación legal o que tú decidas exportar o compartir información mediante una función de la aplicación.',
    ),
    _LegalSection(
      title: '7. Actualizaciones',
      body: 'Podemos actualizar este aviso para reflejar cambios en MOVA o en la forma en que tratamos la información. La versión más reciente estará disponible desde el registro.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  OutlineInputBorder _buildBorder({
    Color color = RegisterScreen.inputBorderGrey,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 1.2),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: _buildBorder(),
      enabledBorder: _buildBorder(),
      focusedBorder: _buildBorder(color: RegisterScreen.primaryTeal),
    );
  }

  Future<void> _registrarUsuario() async {
    final nombre = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (nombre.length < 2 || email.isEmpty || password.isEmpty) {
      showMovaError(
        context,
        'Revisa tu nombre, correo y contraseña.',
        title: 'Faltan datos',
      );
      return;
    }

    if (!_validEmail) {
      showMovaError(context, 'Ingresa un correo electrónico válido.');
      return;
    }

    if (password.length < 8 || _passwordScore < 2) {
      showMovaError(
        context,
        'Usa al menos 8 caracteres, una mayúscula, un número o un símbolo.',
        title: 'Contraseña débil',
      );
      return;
    }

    if (password != confirmPassword) {
      showMovaError(context, 'Las contraseñas no coinciden.');
      return;
    }

    if (!_acceptTerms) {
      showMovaError(
        context,
        'Debes aceptar los términos y condiciones.',
        title: 'Aceptación requerida',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _databaseHelper.insertUser(nombre, email, password);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      showMovaError(
        context,
        'El correo electrónico ya está registrado.',
        title: 'Cuenta existente',
      );
    }
  }

  /*
  class _LegalSection {
    final String title;
    final String body;

    const _LegalSection({required this.title, required this.body});
  }

  class _LegalDocumentSheet extends StatelessWidget {
    final String title;
    final String subtitle;
    final IconData icon;
    final List<_LegalSection> sections;

    const _LegalDocumentSheet({
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.sections,
    });

    @override
    Widget build(BuildContext context) {
      return FractionallySizedBox(
        heightFactor: .9,
        child: Material(
          color: const Color(0xFFF7FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D466F), Color(0xFF0C2340)],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: RegisterScreen.darkNavy,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Actualizado el 23 de septiembre de 2026',
                              style: TextStyle(
                                color: RegisterScreen.subtitleGrey,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFEAF0F5),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: RegisterScreen.darkNavy,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8E5F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: RegisterScreen.primaryTeal,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            color: RegisterScreen.darkNavy,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                    itemCount: sections.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE3EBF2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: const TextStyle(
                                color: RegisterScreen.darkNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              section.body,
                              style: const TextStyle(
                                color: RegisterScreen.subtitleGrey,
                                fontSize: 12,
                                height: 1.48,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RegisterScreen.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Entendido',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegisterScreen.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 730;
            final bottomInset =
                MediaQuery.viewPaddingOf(context).bottom +
                MediaQuery.viewInsetsOf(context).bottom;
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 16 : 20,
                  vertical: compact ? 8 : 16,
                ).copyWith(bottom: (compact ? 8 : 16) + bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                        (compact ? 16 : 32) -
                        bottomInset,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: compact ? 2 : 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: RegisterScreen.darkNavy.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: compact ? 58 : 82,
                            width: compact ? 58 : 82,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(compact ? 16 : 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _stepBadge('1', true),
                                _stepLine(),
                                _stepBadge('2', true),
                                _stepLine(),
                                _stepBadge('3', true),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Crea tu cuenta",
                              style: TextStyle(
                                fontSize: compact ? 20 : 22,
                                fontWeight: FontWeight.bold,
                                color: RegisterScreen.darkNavy,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Empieza a tomar el control de tus finanzas.",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: RegisterScreen.subtitleGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: compact ? 12 : 24),
                            _buildLabel("Nombre"),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                hintText: "Ingresa tu nombre",
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                            SizedBox(height: compact ? 9 : 16),
                            _buildLabel("Correo electrónico"),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => setState(() {
                                _emailTouched = true;
                              }),
                              decoration: _inputDecoration(
                                hintText: "Ingresa tu correo",
                                prefixIcon: Icons.email_outlined,
                                suffixIcon: _emailTouched
                                    ? Icon(
                                        _validEmail
                                            ? Icons.check_circle_rounded
                                            : Icons.error_outline_rounded,
                                        color: _validEmail
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFDC2626),
                                        size: 19,
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(height: compact ? 9 : 16),
                            _buildLabel("Contraseña"),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {
                                _passwordTouched = true;
                              }),
                              decoration: _inputDecoration(
                                hintText: "Crea una contraseña",
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      minHeight: 6,
                                      value: _passwordTouched
                                          ? _passwordScore / 4
                                          : 0,
                                      backgroundColor: const Color(0xFFE8EEF4),
                                      valueColor: AlwaysStoppedAnimation(
                                        _passwordScore >= 3
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _passwordTouched
                                      ? (_passwordScore >= 3
                                            ? 'Segura'
                                            : 'Mejorable')
                                      : 'Mínimo 8 caracteres',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: _passwordScore >= 3
                                        ? const Color(0xFF16A34A)
                                        : RegisterScreen.subtitleGrey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 9 : 16),
                            _buildLabel("Confirmar contraseña"),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: _inputDecoration(
                                hintText: "Repite tu contraseña",
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _acceptTerms,
                                    activeColor: RegisterScreen.primaryTeal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _acceptTerms = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: "Acepto los ",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: RegisterScreen.darkNavy,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "términos y condiciones",
                                          style: TextStyle(
                                            color: RegisterScreen.primaryTeal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showTerms(
                                              'Términos y condiciones',
                                              'Usa MOVA de forma responsable y conserva tus datos de acceso en un lugar seguro.',
                                            ),
                                        ),
                                        const TextSpan(text: " y el "),
                                        TextSpan(
                                          text: "aviso de privacidad",
                                          style: TextStyle(
                                            color: RegisterScreen.primaryTeal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showTerms(
                                              'Aviso de privacidad',
                                              'Tus datos se almacenan localmente en este dispositivo para que puedas administrar tu información.',
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: RegisterScreen.primaryTeal
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _registrarUsuario,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: RegisterScreen.primaryTeal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 21,
                                        height: 21,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Crear cuenta",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "¿Ya tienes una cuenta? ",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: RegisterScreen.subtitleGrey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Iniciar sesión",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: RegisterScreen.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: RegisterScreen.darkNavy,
        ),
      ),
    );
  }

  Widget _stepBadge(String label, bool active) {
    return Container(
      width: 25,
      height: 25,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? RegisterScreen.primaryTeal : const Color(0xFFE8EEF4),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : RegisterScreen.subtitleGrey,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _stepLine() {
    return Container(
      width: 26,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: const Color(0xFFD7E1EB),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});
}

class _LegalDocumentSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_LegalSection> sections;

  const _LegalDocumentSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .9,
      child: Material(
        color: const Color(0xFFF7FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D466F), Color(0xFF0C2340)],
                        ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: RegisterScreen.darkNavy,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Actualizado el 23 de septiembre de 2026',
                            style: TextStyle(
                              color: RegisterScreen.subtitleGrey,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF0F5),
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: RegisterScreen.darkNavy,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8E5F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: RegisterScreen.primaryTeal,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: RegisterScreen.darkNavy,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                  itemCount: sections.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return Container(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE3EBF2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              color: RegisterScreen.darkNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            section.body,
                            style: const TextStyle(
                              color: RegisterScreen.subtitleGrey,
                              fontSize: 12,
                              height: 1.48,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RegisterScreen.primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
