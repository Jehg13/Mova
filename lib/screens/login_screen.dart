import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/biometric_auth.dart';
import 'package:mova/widgets/mova_feedback_dialog.dart';
import 'package:mova/services/mova_localizations.dart';

import 'navigation_wrapper.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static Color primaryTeal = Color(0xFF0C2340);
  static Color darkNavy = Color(0xFF0C2340);
  static Color subtitleGrey = Color(0xFF64748B);
  static const Color inputBorderGrey = Color(0xFFE2E8F0);
  static Color backgroundColor = Color(0xFFF1F5F9);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 850),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMovaError(
        context,
        context.l10n.text('complete_fields'),
        title: context.l10n.text('missing_data'),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final usuario = await _databaseHelper.loginUser(
        email,
        password,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;
      if (usuario != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationWrapper()),
        );
      } else {
        setState(() => _isLoading = false);
        showMovaError(
          context,
          movaText('Revisa tu correo y contraseña e inténtalo nuevamente.'),
          title: context.l10n.text('incorrect_data'),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showMovaError(
        context,
        movaText('No fue posible iniciar sesión.'),
        title: movaText('Error de acceso'),
      );
    }
  }

  OutlineInputBorder _buildBorder({Color color = LoginScreen.inputBorderGrey}) {
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _buildBorder(),
      enabledBorder: _buildBorder(),
      focusedBorder: _buildBorder(color: LoginScreen.primaryTeal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: LoginScreen.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: constraints.maxHeight >= 720
                    ? NeverScrollableScrollPhysics()
                    : AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- CABECERA: IMAGEN LOGO MOVA ---
                      Container(
                        margin: EdgeInsets.only(top: 8.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                              color: LoginScreen.darkNavy.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 15,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.asset(
                            'assets/images/logo.png', // Ruta de tu imagen
                            height: 110,
                            width: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // --- TARJETA DE LOGIN ELEVADA ---
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.0),
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
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFEAF1F7),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    color: LoginScreen.primaryTeal,
                                    size: 15,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    l10n.text('login_access'),
                                    style: TextStyle(
                                      color: LoginScreen.primaryTeal,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: .8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              l10n.text('welcome_back'),
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: LoginScreen.darkNavy,
                                letterSpacing: -0.8,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              l10n.text('continue_finances'),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: LoginScreen.subtitleGrey,
                              ),
                            ),
                            SizedBox(height: 28),

                            // CAMPO CORREO
                            _buildLabel(l10n.text('email')),
                            SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration(
                                hintText: l10n.text('email'),
                                prefixIcon: Icons.email_outlined,
                              ),
                            ),
                            SizedBox(height: 20),

                            // CAMPO CONTRASEÑA
                            _buildLabel(l10n.text('password')),
                            SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: _inputDecoration(
                                hintText: l10n.text('password'),
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
                            SizedBox(height: 16),

                            // RECORDARME Y OLVIDASTE CONTRASEÑA
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: LoginScreen.primaryTeal,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: Color(0xFFCBD5E1),
                                          width: 1.5,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      l10n.text('remember_me'),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: LoginScreen.darkNavy,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: _mostrarRecuperacion,
                                  child: Text(
                                    l10n.text('forgot_password'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: LoginScreen.primaryTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 28),

                            // BOTÓN INICIAR SESIÓN CON SOMBRA
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: LoginScreen.primaryTeal.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _iniciarSesion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LoginScreen.primaryTeal,
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
                                            l10n.text('login'),
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

                      // --- FOOTER ---
                      Column(
                        children: [
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.text('no_account'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: LoginScreen.subtitleGrey,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.text('create_account'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: LoginScreen.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: LoginScreen.subtitleGrey,
                              ),
                              SizedBox(width: 6),
                              Text(
                                movaText("Tus datos están protegidos"),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LoginScreen.subtitleGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
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

  Future<void> _mostrarRecuperacion() async {
    final recovered = await showDialog<bool>(
      context: context,
      builder: (_) => _PasswordRecoveryDialog(
        databaseHelper: _databaseHelper,
        initialEmail: _emailController.text.trim(),
      ),
    );

    if (!mounted || recovered != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          movaText('Contraseña actualizada. Ya puedes iniciar sesión.'),
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
          color: LoginScreen.darkNavy,
        ),
      ),
    );
  }
}

class _PasswordRecoveryDialog extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final String initialEmail;

  const _PasswordRecoveryDialog({
    required this.databaseHelper,
    required this.initialEmail,
  });

  @override
  State<_PasswordRecoveryDialog> createState() =>
      _PasswordRecoveryDialogState();
}

class _PasswordRecoveryDialogState extends State<_PasswordRecoveryDialog> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  bool _identityVerified = false;
  bool _checkingIdentity = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: LoginScreen.primaryTeal, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: LoginScreen.primaryTeal, width: 1.5),
      ),
    );
  }

  Future<void> _save() async {
    if (!_identityVerified) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = await widget.databaseHelper.updatePassword(
      _emailController.text,
      _passwordController.text,
    );
    if (!mounted) return;

    if (!updated) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movaText('No existe una cuenta con ese correo')),
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _verifyIdentity() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _formKey.currentState!.validate();
      return;
    }
    setState(() => _checkingIdentity = true);
    final exists = await widget.databaseHelper.userExists(email);
    if (!mounted) return;
    if (!exists) {
      setState(() => _checkingIdentity = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movaText('No existe una cuenta con ese correo')),
        ),
      );
      return;
    }

    final result = await BiometricAuth().authenticate();
    if (!mounted) return;
    setState(() {
      _checkingIdentity = false;
      _identityVerified = result == BiometricResult.authenticated;
    });

    if (result == BiometricResult.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            movaText(
              'La huella no está disponible en este dispositivo. En Chrome debes usar la app móvil.',
            ),
          ),
        ),
      );
    } else if (result != BiometricResult.authenticated &&
        result != BiometricResult.canceled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(movaText('No se pudo verificar tu identidad'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 430),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: LoginScreen.darkNavy.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(24, 24, 20, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0C2340), Color(0xFF0C2340)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movaText('Recupera tu acceso'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                movaText(
                                  'Crea una nueva contraseña para volver a entrar a Mova.',
                                ),
                                style: TextStyle(
                                  color: Color(0xFFD9F3EF),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context, false),
                          icon: Icon(Icons.close_rounded),
                          color: Colors.white70,
                          tooltip: movaText('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 22, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: Color(0xFFEFF8F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF0C2340),
                                  size: 19,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    movaText(
                                      'Primero confirma tu correo y tu identidad con la huella.',
                                    ),
                                    style: TextStyle(
                                      color: Color(0xFF28645D),
                                      fontSize: 12.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _decoration(
                              label: movaText('Correo electrónico'),
                              icon: Icons.alternate_email_rounded,
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? movaText('Escribe tu correo electrónico')
                                : null,
                          ),
                          SizedBox(height: 14),
                          if (!_identityVerified)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _checkingIdentity
                                    ? null
                                    : _verifyIdentity,
                                icon: _checkingIdentity
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.fingerprint_rounded),
                                label: Text(
                                  _checkingIdentity
                                      ? movaText('Verificando...')
                                      : movaText('Verificar con huella'),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Color(0xFF0C2340),
                                  minimumSize: Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          if (_identityVerified) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFEFF8F7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF0C2340),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    movaText('Identidad verificada'),
                                    style: TextStyle(
                                      color: Color(0xFF28645D),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                label: movaText('Nueva contraseña'),
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.length < 8
                                  ? 'Usa mínimo 8 caracteres'
                                  : null,
                            ),
                            SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _saving ? null : _save(),
                              decoration: _decoration(
                                label: movaText('Confirmar contraseña'),
                                icon: Icons.verified_user_outlined,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? movaText('Las contraseñas no coinciden')
                                  : null,
                            ),
                          ],
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(color: Color(0xFFD7E0E8)),
                                  ),
                                  child: Text(movaText('Cancelar')),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: _saving
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(Icons.check_rounded, size: 19),
                                  label: Text(
                                    _saving
                                        ? movaText('Guardando...')
                                        : movaText('Actualizar'),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: LoginScreen.primaryTeal,
                                    minimumSize: Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
