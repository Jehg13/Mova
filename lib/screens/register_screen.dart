import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../database/database_helper.dart';
import '../widgets/mova_feedback_dialog.dart';
import 'login_screen.dart';
import '../services/mova_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static Color primaryTeal = Color(0xFF0C2340);
  static Color darkNavy = Color(0xFF0C2340);
  static Color subtitleGrey = Color(0xFF64748B);
  static const Color inputBorderGrey = Color(0xFFE2E8F0);
  static Color backgroundColor = Color(0xFFF1F5F9);

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

  static final _termsSections = <_LegalSection>[
    _LegalSection(
      title: movaText('1. Aceptación del servicio'),
      body: 'Al crear una cuenta y utilizar MOVA confirmas que leíste, comprendiste y aceptas estos términos. Si no estás de acuerdo, no debes completar el registro ni utilizar la aplicación.',
    ),
    _LegalSection(
      title: movaText('2. Uso de MOVA'),
      body: 'MOVA es una herramienta de organización financiera personal. Puedes registrar ingresos, gastos, metas, presupuestos y listas para tu propio control. La información que ingreses debe ser verdadera y corresponder a tu actividad.',
    ),
    _LegalSection(
      title: movaText('3. Tu cuenta'),
      body: 'Eres responsable de mantener la confidencialidad de tu correo y contraseña, así como de toda actividad realizada desde tu cuenta. Si detectas un acceso no autorizado, cambia tu contraseña y deja de utilizar el dispositivo comprometido.',
    ),
    _LegalSection(
      title: movaText('4. Información financiera'),
      body: 'Los cálculos, resúmenes y análisis de MOVA son orientativos y dependen de los datos que registres. La aplicación no sustituye asesoría financiera, contable, fiscal o legal profesional.',
    ),
    _LegalSection(
      title: movaText('5. Uso responsable'),
      body: 'No debes intentar alterar la aplicación, acceder a cuentas ajenas, introducir información maliciosa ni utilizar MOVA para actividades ilegales. El uso indebido puede ocasionar la suspensión del acceso.',
    ),
    _LegalSection(
      title: movaText('6. Cambios y disponibilidad'),
      body: 'Podemos mejorar, actualizar o modificar funciones de MOVA para mantener una experiencia segura y útil. Procuraremos conservar tus datos y avisarte cuando un cambio sea relevante para el servicio.',
    ),
  ];

  static final _privacySections = <_LegalSection>[
    _LegalSection(
      title: movaText('1. Qué información guardamos'),
      body: 'MOVA puede guardar tu nombre, correo electrónico, contraseña, foto de perfil, movimientos, metas, presupuestos, categorías, listas de compras y preferencias necesarias para ofrecerte sus funciones.',
    ),
    _LegalSection(
      title: movaText('2. Para qué la utilizamos'),
      body: 'Utilizamos esta información para crear y proteger tu cuenta, mostrar tus finanzas, generar resúmenes y análisis, personalizar la aplicación y conservar tus configuraciones.',
    ),
    _LegalSection(
      title: movaText('3. Almacenamiento local'),
      body: 'La información financiera de MOVA se almacena localmente en el dispositivo para que puedas utilizar la aplicación. Si desinstalas la aplicación, cambias de dispositivo o borras sus datos, podrías perder la información que no hayas respaldado.',
    ),
    _LegalSection(
      title: movaText('4. Protección de tus datos'),
      body: 'Aplicamos medidas razonables para proteger la información dentro de la aplicación. Aun así, ninguna aplicación o dispositivo es completamente invulnerable; por eso te recomendamos usar un bloqueo de pantalla y no compartir tus credenciales.',
    ),
    _LegalSection(
      title: movaText('5. Tus decisiones'),
      body: 'Puedes editar o eliminar la información disponible desde las funciones de MOVA. También puedes eliminar tu foto de perfil, actualizar tu contraseña y desactivar opciones de seguridad o notificaciones desde la sección Más.',
    ),
    _LegalSection(
      title: movaText('6. Compartir información'),
      body: 'MOVA no vende tu información personal. No compartimos tus datos financieros con terceros salvo que sea necesario para cumplir una obligación legal o que tú decidas exportar o compartir información mediante una función de la aplicación.',
    ),
    _LegalSection(
      title: movaText('7. Actualizaciones'),
      body: 'Podemos actualizar este aviso para reflejar cambios en MOVA o en la forma en que tratamos la información. La versión más reciente estará disponible desde el registro.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
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
      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Color(0xFF94A3B8), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
        movaText('Revisa tu nombre, correo y contraseña.'),
        title: movaText('Faltan datos'),
      );
      return;
    }

    if (!_validEmail) {
      showMovaError(context, movaText('Ingresa un correo electrónico válido.'));
      return;
    }

    if (password.length < 8 || _passwordScore < 2) {
      showMovaError(
        context,
        movaText(
          'Usa al menos 8 caracteres, una mayúscula, un número o un símbolo.',
        ),
        title: movaText('Contraseña débil'),
      );
      return;
    }

    if (password != confirmPassword) {
      showMovaError(context, movaText('Las contraseñas no coinciden.'));
      return;
    }

    if (!_acceptTerms) {
      showMovaError(
        context,
        movaText('Debes aceptar los términos y condiciones.'),
        title: movaText('Aceptación requerida'),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _databaseHelper.insertUser(nombre, email, password);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      showMovaError(
        context,
        movaText('El correo electrónico ya está registrado.'),
        title: movaText('Cuenta existente'),
      );
    }
  }

  /*
  class _LegalSection {
    final String title;
    final String body;

    _LegalSection({required this.title, required this.body});
  }

  class _LegalDocumentSheet extends StatelessWidget {
    final String title;
    final String subtitle;
    final IconData icon;
    final List<_LegalSection> sections;

    _LegalDocumentSheet({
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.sections,
    });

    @override
    Widget build(BuildContext context) {
      final l10n = context.l10n;
      return FractionallySizedBox(
        heightFactor: .9,
        child: Material(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22, 20, 16, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1D466F), Color(0xFF0C2340)],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Icon(icon, color: Colors.white, size: 26),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: RegisterScreen.darkNavy,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(movaText('Actualizado el 23 de septiembre de 2026'),
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
                          backgroundColor: Color(0xFFEAF0F5),
                        ),
                        icon: Icon(
                          Icons.close_rounded,
                          color: RegisterScreen.darkNavy,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 22),
                  padding: EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Color(0xFFEAF2F8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFD8E5F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: RegisterScreen.primaryTeal,
                        size: 19,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: RegisterScreen.darkNavy,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(22, 8, 22, 22),
                    itemCount: sections.length,
                    separatorBuilder: (_, index) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Container(
                        padding: EdgeInsets.fromLTRB(16, 15, 16, 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Color(0xFFE3EBF2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: TextStyle(
                                color: RegisterScreen.darkNavy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              movaText(section.body),
                              style: TextStyle(
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
                  padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
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
                      child: Text(movaText('Entendido'),
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
            final l10n = context.l10n;
            final compact = constraints.maxHeight < 730;
            final bottomInset =
                MediaQuery.viewPaddingOf(context).bottom +
                MediaQuery.viewInsetsOf(context).bottom;
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: AlwaysScrollableScrollPhysics(),
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
                              offset: Offset(0, 6),
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
                              color: Color(0xFF0F172A).withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Color(0xFF0F172A).withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: Offset(0, 2),
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
                            SizedBox(height: 12),
                            Text(
                              l10n.text('create_your_account'),
                              style: TextStyle(
                                fontSize: compact ? 20 : 22,
                                fontWeight: FontWeight.bold,
                                color: RegisterScreen.darkNavy,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              l10n.text('take_control'),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: RegisterScreen.subtitleGrey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: compact ? 12 : 24),
                            _buildLabel(l10n.text('name')),
                            SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                hintText: l10n.text('enter_name'),
                                prefixIcon: Icons.person_outline,
                              ),
                            ),
                            SizedBox(height: compact ? 9 : 16),
                            _buildLabel(l10n.text('email')),
                            SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => setState(() {
                                _emailTouched = true;
                              }),
                              decoration: _inputDecoration(
                                hintText: l10n.text('enter_email'),
                                prefixIcon: Icons.email_outlined,
                                suffixIcon: _emailTouched
                                    ? Icon(
                                        _validEmail
                                            ? Icons.check_circle_rounded
                                            : Icons.error_outline_rounded,
                                        color: _validEmail
                                            ? Color(0xFF16A34A)
                                            : Color(0xFFDC2626),
                                        size: 19,
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(height: compact ? 9 : 16),
                            _buildLabel(l10n.text('password')),
                            SizedBox(height: 6),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {
                                _passwordTouched = true;
                              }),
                              decoration: _inputDecoration(
                                hintText: l10n.text('create_password'),
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Color(0xFF94A3B8),
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
                            SizedBox(height: 7),
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
                                      backgroundColor: Color(0xFFE8EEF4),
                                      valueColor: AlwaysStoppedAnimation(
                                        _passwordScore >= 3
                                            ? Color(0xFF16A34A)
                                            : Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
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
                                        ? Color(0xFF16A34A)
                                        : RegisterScreen.subtitleGrey,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compact ? 9 : 16),
                            _buildLabel(l10n.text('repeat_password')),
                            SizedBox(height: 6),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: _inputDecoration(
                                hintText: l10n.text('repeat_password'),
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Color(0xFF94A3B8),
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
                            SizedBox(height: 16),
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
                                    side: BorderSide(
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
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: movaText("Acepto los "),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: RegisterScreen.darkNavy,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: movaText(
                                            "términos y condiciones",
                                          ),
                                          style: TextStyle(
                                            color: RegisterScreen.primaryTeal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showTerms(
                                              movaText(
                                                'Términos y condiciones',
                                              ),
                                              'Usa MOVA de forma responsable y conserva tus datos de acceso en un lugar seguro.',
                                            ),
                                        ),
                                        TextSpan(text: movaText(" y el ")),
                                        TextSpan(
                                          text: movaText("aviso de privacidad"),
                                          style: TextStyle(
                                            color: RegisterScreen.primaryTeal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => _showTerms(
                                              movaText('Aviso de privacidad'),
                                              'Tus datos se almacenan localmente en este dispositivo para que puedas administrar tu información.',
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
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
                                    offset: Offset(0, 4),
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
                                    ? SizedBox(
                                        width: 21,
                                        height: 21,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            movaText("Crear cuenta"),
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
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                movaText("¿Ya tienes una cuenta? "),
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
                                      builder: (context) => LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  movaText("Iniciar sesión"),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: RegisterScreen.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
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
        style: TextStyle(
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
        color: active ? RegisterScreen.primaryTeal : Color(0xFFE8EEF4),
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
      margin: EdgeInsets.symmetric(horizontal: 5),
      color: Color(0xFFD7E1EB),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;

  _LegalSection({required this.title, required this.body});
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
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(22, 20, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1D466F), Color(0xFF0C2340)],
                        ),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: RegisterScreen.darkNavy,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            movaText('Actualizado el 23 de septiembre de 2026'),
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
                        backgroundColor: Color(0xFFEAF0F5),
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: RegisterScreen.darkNavy,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 22),
                padding: EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Color(0xFFEAF2F8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFD8E5F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: RegisterScreen.primaryTeal,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: RegisterScreen.darkNavy,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(22, 8, 22, 22),
                  itemCount: sections.length,
                  separatorBuilder: (_, index) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    return Container(
                      padding: EdgeInsets.fromLTRB(16, 15, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Color(0xFFE3EBF2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: TextStyle(
                              color: RegisterScreen.darkNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            movaText(section.body),
                            style: TextStyle(
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
                padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
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
                    child: Text(
                      movaText('Entendido'),
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
