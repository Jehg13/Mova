import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import 'package:mova/database/database_helper.dart';
import 'package:mova/services/biometric_auth.dart';
import 'package:mova/widgets/mova_feedback_dialog.dart';
import 'package:mova/services/notification_service.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/services/language_controller.dart';
import 'package:mova/services/mova_localizations.dart';
import 'package:mova/widgets/user_avatar.dart';
import 'package:mova/widgets/mova_notifications_dialog.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';
import 'shopping_screen.dart';

const _termsTitle = 'Términos y condiciones';
const _privacyTitle = 'Aviso de privacidad';

final _termsSections = <({String title, String body})>[
  (
    title: '1. Aceptación del servicio',
    body: 'Al crear una cuenta y utilizar MOVA confirmas que leíste, comprendiste y aceptas estos términos.',
  ),
  (
    title: '2. Uso de MOVA',
    body: 'MOVA es una herramienta de organización financiera personal para registrar ingresos, gastos, metas, presupuestos y listas.',
  ),
  (
    title: '3. Tu cuenta',
    body: 'Eres responsable de mantener la confidencialidad de tu correo y contraseña, así como de la actividad realizada desde tu dispositivo.',
  ),
  (
    title: '4. Información financiera',
    body: 'Los cálculos y análisis son orientativos y dependen de los datos que registres. MOVA no sustituye asesoría financiera profesional.',
  ),
  (
    title: '5. Uso responsable',
    body: 'No debes acceder a cuentas ajenas, alterar la aplicación ni utilizar MOVA para actividades ilegales.',
  ),
];

final _privacySections = <({String title, String body})>[
  (
    title: '1. Información que guardamos',
    body: 'MOVA puede guardar tu nombre, correo, contraseña, foto de perfil, movimientos, metas, presupuestos, categorías y listas.',
  ),
  (
    title: '2. Para qué la utilizamos',
    body: 'Utilizamos esta información para proteger tu cuenta, mostrar tus finanzas, generar resúmenes y conservar tus preferencias.',
  ),
  (
    title: '3. Almacenamiento local',
    body: 'La información financiera se almacena localmente en tu dispositivo. Si desinstalas la aplicación o borras sus datos, podrías perder información no respaldada.',
  ),
  (
    title: '4. Protección de tus datos',
    body: 'Aplicamos medidas razonables para proteger tu información. Te recomendamos usar bloqueo de pantalla y no compartir tus credenciales.',
  ),
  (
    title: '5. Tus decisiones',
    body: 'Puedes editar o eliminar la información desde las funciones disponibles de MOVA, incluida la eliminación de tu cuenta.',
  ),
];

Future<void> _showLegalDocument(
  BuildContext context,
  String title,
  List<({String title, String body})> sections,
  IconData icon,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * .86,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, 22, 16, 12),
              child: Row(
                children: [
                  Icon(icon, color: Color(0xFF0C2340), size: 25),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      movaText(title),
                      style: TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Text(
                movaText(
                  title == _termsTitle
                      ? 'Lee estas condiciones para conocer el uso responsable de MOVA.'
                      : 'Consulta qué información se guarda y cómo puedes administrar tus datos.',
                ),
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 28),
                itemCount: sections.length,
                separatorBuilder: (_, _) => SizedBox(height: 18),
                itemBuilder: (_, index) {
                  final section = sections[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movaText(section.title),
                        style: TextStyle(
                          color: Color(0xFF102A43),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        movaText(section.body),
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog();

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _database = DatabaseHelper();
  final _name = TextEditingController();
  final _email = TextEditingController();
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _saving = false;
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _database.getCurrentUser().then((user) {
      if (!mounted) return;
      _user = user;
      _name.text = user?['name'] as String? ?? '';
      _email.text = user?['email'] as String? ?? '';
      final raw = user?['profile_image'];
      _image = raw is Uint8List
          ? raw
          : raw is List
          ? Uint8List.fromList(raw.cast<int>())
          : null;
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = _user;
    final name = _name.text.trim();
    if (user == null || name.isEmpty) return;
    setState(() => _saving = true);
    final saved = await _database.updateUserName(user['id'] as int, name);
    if (saved) {
      await _database.updateUserProfileImage(user['id'] as int, _image);
    }
    if (!mounted) return;
    if (saved) profileChanged.value++;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _image = bytes);
  }

  void _removeImage() {
    setState(() => _image = null);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: _loading
              ? SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFE8EEF5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.manage_accounts_rounded,
                            color: Color(0xFF0C2340),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movaText('Mi cuenta'),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                movaText('Administra tu información personal'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.pop(context),
                          icon: Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    SizedBox(height: 22),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF1F6FB), Color(0xFFE7F5F3)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Color(0xFFD8E5EC)),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF0C2340),
                                      Color(0xFF00A6A6),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Color(0xFFE8EEF5),
                                  backgroundImage: _image == null
                                      ? null
                                      : MemoryImage(_image!),
                                  child: _image == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF0C2340),
                                          size: 50,
                                        )
                                      : null,
                                ),
                              ),
                              Material(
                                color: Color(0xFF0C2340),
                                elevation: 4,
                                shadowColor: Color(0x550C2340),
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: _pickImage,
                                  customBorder: CircleBorder(),
                                  child: Padding(
                                    padding: EdgeInsets.all(9),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            movaText(
                              _image == null
                                  ? 'Agrega una foto para personalizar tu cuenta'
                                  : 'Tu foto de perfil',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334E68),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(
                                  Icons.photo_library_outlined,
                                  size: 17,
                                ),
                                label: Text(
                                  movaText(
                                    _image == null
                                        ? 'Agregar foto de perfil'
                                        : 'Cambiar foto de perfil',
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Color(0xFF0C2340),
                                  side: BorderSide(color: Color(0xFF9CB7C7)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 11,
                                  ),
                                ),
                              ),
                              if (_image != null)
                                TextButton.icon(
                                  onPressed: _removeImage,
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 17,
                                  ),
                                  label: Text(movaText('Quitar foto')),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Color(0xFFB42318),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    _ProfileField(
                      label: 'Nombre',
                      icon: Icons.person_outline_rounded,
                      child: TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: movaText('Escribe tu nombre'),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    _ProfileField(
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      child: TextField(
                        enabled: false,
                        controller: _email,
                        decoration: InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF334E68),
                              side: BorderSide(color: Color(0xFFD0DCE5)),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(movaText('Cancelar')),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: Color(0xFF0C2340),
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _saving
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_rounded, size: 18),
                                      SizedBox(width: 6),
                                      Text(movaText('Guardar')),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const _ProfileField({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 8, 14, 2),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(icon, color: Color(0xFF0C2340), size: 21),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movaText(label),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  static Color backgroundColor = Color(0xFFF1F5F9);
  static Color darkNavy = Color(0xFF0F172A);
  static Color subtitleGrey = Color(0xFF64748B);
  static Color sectionHeaderColor = Color(0xFF475569);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMoreHeader(context),
              SizedBox(height: 22),

              FutureBuilder<Map<String, dynamic>?>(
                future: DatabaseHelper().getCurrentUser(),
                builder: (context, snapshot) {
                  final name =
                      (snapshot.data?['name'] as String?) ??
                      l10n.text('my_profile');
                  final email =
                      (snapshot.data?['email'] as String?) ??
                      l10n.text('my_account');
                  return _buildProfileCard(context, name, email);
                },
              ),
              SizedBox(height: 24),

              // --- SECCIÓN: FINANZAS ---
              _buildSectionTitle("FINANZAS"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.monetization_on_outlined,
                      title: l10n.text('personal_budget'),
                      subtitle: movaText("Define cuánto quieres gastar"),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => _BudgetDialog(),
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.label_outline,
                      title: l10n.text('categories'),
                      subtitle: movaText(
                        "Administra tus categorías de ingresos y gastos",
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => _CategoriesScreen()),
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.shopping_cart_outlined,
                      title: l10n.text('shopping_lists'),
                      subtitle: movaText(
                        "Organiza productos, calcula y registra tus compras",
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShoppingScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // --- SECCIÓN: APLICACIÓN ---
              _buildSectionTitle("APLICACIÓN"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.notifications_none_outlined,
                      title: l10n.text('notifications'),
                      subtitle: movaText("Gestiona tus recordatorios"),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => MovaNotificationsDialog(),
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.lock_outline,
                      title: l10n.text('security'),
                      subtitle: movaText("Protege tu información"),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => _SecurityDialog(),
                      ),
                    ),
                    _buildDivider(),
                    AnimatedBuilder(
                      animation: appLanguageController,
                      builder: (context, _) => _buildOptionTile(
                        context: context,
                        icon: Icons.language_outlined,
                        title: l10n.text('language'),
                        subtitle: appLanguageController.language.nativeLabel,
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => _LanguageDialog(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // --- SECCIÓN: DATOS ---
              _buildSectionTitle("DATOS"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.upload_outlined,
                      title: movaText("Exportar datos"),
                      subtitle: movaText("Descarga tus movimientos"),
                      onTap: () => _exportData(context),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.download_outlined,
                      title: movaText("Importar datos"),
                      subtitle: movaText("Importa información existente"),
                      onTap: () => _importData(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // --- SECCIÓN: INFORMACIÓN ---
              _buildSectionTitle("INFORMACIÓN"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.info_outline,
                      title: movaText("Acerca de MOVA"),
                      subtitle: movaText("Versión 1.0.0"),
                      onTap: () => _showAbout(context),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.gavel_outlined,
                      title: l10n.text('terms'),
                      subtitle: movaText("Consulta las condiciones de uso"),
                      onTap: () => _showLegalDocument(
                        context,
                        movaText(_termsTitle),
                        _termsSections,
                        Icons.gavel_outlined,
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.text('privacy'),
                      subtitle: movaText("Consulta cómo se tratan tus datos"),
                      onTap: () => _showLegalDocument(
                        context,
                        movaText(_privacyTitle),
                        _privacySections,
                        Icons.privacy_tip_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // --- SECCIÓN: CUENTA (CERRAR SESIÓN) ---
              _buildSectionTitle("CUENTA"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: movaText("Cerrar sesión"),
                      subtitle: movaText(
                        "Sal de tu cuenta en este dispositivo",
                      ),
                      onTap: () => _logout(context),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.delete_forever_outlined,
                      title: movaText("Eliminar cuenta"),
                      subtitle: movaText("Borra tu cuenta y todos sus datos"),
                      onTap: () => _deleteAccount(context),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await DatabaseHelper().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titlePadding: EdgeInsets.fromLTRB(24, 24, 18, 8),
        contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 8),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.delete_forever_outlined,
                color: Color(0xFFB42318),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                movaText('Eliminar cuenta'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              movaText('Esta acción es permanente.'),
              style: TextStyle(
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              movaText(
                'Se eliminarán tu cuenta, movimientos, metas, listas y configuraciones. No podrás recuperar estos datos.',
              ),
              style: TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(movaText('Cancelar')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Color(0xFFB42318)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(movaText('Eliminar cuenta')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await DatabaseHelper().deleteAccount();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!context.mounted) return;
      showMovaError(
        context,
        'No se pudo eliminar la cuenta. Intenta nuevamente.',
        title: movaText('No se pudo completar'),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 3.0, bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 15,
            decoration: BoxDecoration(
              color: Color(0xFF0C2340),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 8),
          Text(
            movaText(title),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: MoreScreen.sectionHeaderColor,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x080C2340),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0C2340), Color(0xFF36577D)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.tune_rounded, color: Colors.white, size: 25),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movaText('Más'),
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: MoreScreen.darkNavy,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  movaText('Todo lo que necesitas para controlar MOVA'),
                  style: TextStyle(
                    fontSize: 12,
                    color: MoreScreen.subtitleGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFE8EEF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: MoreScreen.darkNavy,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String name, String email) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () async {
          await showDialog<bool>(
            context: context,
            builder: (_) => _ProfileDialog(),
          );
          if (mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0C2340), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF0C2340).withValues(alpha: .18),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 14, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    UserAvatar(radius: 29),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFCBD5E1),
                      size: 17,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        movaText('Editar información de tu cuenta'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final data = await DatabaseHelper().exportData();
    final encoded = jsonEncode(data);
    final transactionCount = (data['transactions'] as List).length;
    final goalCount = (data['goals'] as List).length;
    final shoppingCount = (data['shopping_lists'] as List).length;
    await Clipboard.setData(ClipboardData(text: encoded));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(
                  context,
                  icon: Icons.cloud_done_rounded,
                  title: movaText('Copia lista'),
                  subtitle: movaText(
                    'Tu información está preparada para guardarse',
                  ),
                  color: Color(0xFF0C2340),
                ),
                SizedBox(height: 18),
                _infoPanel(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: movaText('Respaldo local'),
                  text: movaText(
                    'El archivo se copió al portapapeles. Pégalo en un lugar seguro para conservarlo.',
                  ),
                  color: Color(0xFFE8F5F0),
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    _dataStat(
                      context,
                      Icons.receipt_long_outlined,
                      '$transactionCount',
                      movaText('movimientos'),
                    ),
                    _dataStat(
                      context,
                      Icons.flag_outlined,
                      '$goalCount',
                      movaText('metas'),
                    ),
                    _dataStat(
                      context,
                      Icons.shopping_bag_outlined,
                      '$shoppingCount',
                      movaText('listas'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: encoded));
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(Icons.copy_rounded, size: 18),
                      label: Text(movaText('Copiar de nuevo')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(movaText('Entendido')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importData(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(
                  context,
                  icon: Icons.file_download_outlined,
                  title: movaText('Importar respaldo'),
                  subtitle: movaText(
                    'Agrega información de otra copia de MOVA',
                  ),
                  color: Color(0xFF007C91),
                ),
                SizedBox(height: 18),
                _infoPanel(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: movaText('Antes de continuar'),
                  text: movaText(
                    'Pega aquí el JSON exportado desde MOVA. Tus datos actuales no se eliminarán.',
                  ),
                  color: Color(0xFFEAF6FA),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFD7E3E8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(15, 12, 15, 0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.data_object_rounded,
                              size: 19,
                              color: Color(0xFF007C91),
                            ),
                            SizedBox(width: 8),
                            Text(
                              movaText('Contenido de la copia'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextField(
                        controller: controller,
                        minLines: 3,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: '{ "version": 1, "transactions": [...] }',
                          hintStyle: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.fromLTRB(15, 8, 15, 14),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  movaText(
                    'Solo se importan movimientos válidos. La información existente se conserva.',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(movaText('Cancelar')),
                    ),
                    SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, controller.text),
                      icon: Icon(Icons.file_upload_outlined, size: 18),
                      label: Text(movaText('Importar')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    try {
      final decoded = jsonDecode(text);
      final transactions = decoded is Map ? decoded['transactions'] : null;
      final count = transactions is List
          ? await DatabaseHelper().importTransactions(transactions)
          : 0;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(movaText('$count movimientos importados'))),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movaText('El archivo no tiene un formato válido')),
        ),
      );
    }
  }

  Widget _dialogHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoPanel(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 3),
                Text(text, style: TextStyle(fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: MoreScreen.subtitleGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0C2340),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final accent = _optionAccent(title);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 45,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: .18),
                      accent.withValues(alpha: .07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MoreScreen.darkNavy,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: MoreScreen.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withValues(alpha: .7),
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _optionAccent(String title) {
    switch (title) {
      case 'Presupuesto':
        return Color(0xFF0C2340);
      case 'Categorías':
        return Color(0xFF36577D);
      case 'Listas de compras':
        return Color(0xFF526D8D);
      case 'Notificaciones':
        return Color(0xFF1E3A5F);
      case 'Seguridad':
        return Color(0xFF263F61);
      case 'Exportar datos':
        return Color(0xFF315A80);
      case 'Importar datos':
        return Color(0xFF3E6C91);
      case 'Acerca de MOVA':
        return Color(0xFF587A9B);
      default:
        return Color(0xFF0C2340);
    }
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 52,
    );
  }
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog();

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _LanguageDialog extends StatelessWidget {
  const _LanguageDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: AnimatedBuilder(
          animation: appLanguageController,
          builder: (context, _) {
            final selected = appLanguageController.code;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _DialogIcon(
                        icon: Icons.translate_rounded,
                        color: const Color(0xFF0C2340),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.text('language'),
                              style: const TextStyle(
                                color: Color(0xFF102A43),
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              l10n.text('select_language'),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...movaLanguages.map(
                    (language) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LanguageOption(
                        language: language,
                        selected: selected == language.code,
                        onTap: () =>
                            appLanguageController.setLanguage(language.code),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0C2340),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(l10n.text('done')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DialogIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _DialogIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: .72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 25),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final MovaLanguage language;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  String _label(BuildContext context) {
    switch (language.code) {
      case 'en':
        return context.l10n.text('english');
      case 'pt':
        return context.l10n.text('portuguese');
      default:
        return context.l10n.text('spanish');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF0C2340);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2F9) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              language.code == 'es'
                  ? 'ES'
                  : language.code == 'en'
                  ? 'EN'
                  : 'PT',
              style: TextStyle(
                color: selected ? color : const Color(0xFF64748B),
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nativeLabel,
                    style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _label(context),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? Icon(
                      Icons.check_circle_rounded,
                      key: const ValueKey(true),
                      color: color,
                    )
                  : const Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: ValueKey(false),
                      color: Color(0xFFCBD5E1),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsDialog extends StatefulWidget {
  const _NotificationsDialog();

  @override
  State<_NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<_NotificationsDialog> {
  final _database = DatabaseHelper();
  bool _enabled = true;
  bool _budget = true;
  bool _goals = true;
  bool _shopping = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.wait([
      _database.getNotificationsEnabled(),
      _database.getNotificationOption('notification_budget'),
      _database.getNotificationOption('notification_goals'),
      _database.getNotificationOption('notification_shopping'),
    ]).then((values) {
      if (!mounted) return;
      setState(() {
        _enabled = values[0];
        _budget = values[1];
        _goals = values[2];
        _shopping = values[3];
        _loading = false;
      });
    });
  }

  Future<void> _set(String key, bool value) async {
    await _database.setNotificationOption(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 8),
      scrollable: true,
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFE8EEF5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF1E3A5F),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movaText('Notificaciones'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 3),
                Text(
                  movaText('Elige qué recordatorios quieres recibir'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: _loading
          ? SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Color(0xFF0C2340),
                  title: Text(movaText('Activar notificaciones')),
                  subtitle: Text(
                    movaText('Permite recibir recordatorios de Mova'),
                  ),
                  value: _enabled,
                  onChanged: (value) async {
                    setState(() => _enabled = value);
                    await _set('notifications_enabled', value);
                  },
                ),
                Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(movaText('Presupuesto')),
                  subtitle: Text(
                    movaText('Avisos relacionados con tu límite mensual'),
                  ),
                  value: _budget,
                  onChanged: !_enabled
                      ? null
                      : (value) async {
                          setState(() => _budget = value);
                          await _set('notification_budget', value);
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(movaText('Metas')),
                  subtitle: Text(
                    movaText('Recordatorios para avanzar en tus metas'),
                  ),
                  value: _goals,
                  onChanged: !_enabled
                      ? null
                      : (value) async {
                          setState(() => _goals = value);
                          await _set('notification_goals', value);
                        },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(movaText('Lista de compras')),
                  subtitle: Text(
                    movaText('Recordatorios de listas pendientes'),
                  ),
                  value: _shopping,
                  onChanged: !_enabled
                      ? null
                      : (value) async {
                          setState(() => _shopping = value);
                          await _set('notification_shopping', value);
                        },
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(movaText('Cerrar')),
        ),
      ],
    );
  }
}

Future<void> _showAbout(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: .25),
                      blurRadius: 18,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              SizedBox(height: 15),
              Text(
                movaText('MOVA'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 3),
              Text(
                movaText('Versión 1.0.0  ·  Finanzas personales'),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFEAF6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: Color(0xFF007C91),
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        movaText(
                          'MOVA está diseñada con un enfoque offline-first. Tus datos principales se mantienen en tu dispositivo.',
                        ),
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),
              Text(
                movaText(
                  'Organiza ingresos, gastos, metas y compras en un solo espacio, de forma clara y sencilla.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4),
              ),
              SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showLicensePage(
                        context: context,
                        applicationName: 'MOVA',
                        applicationVersion: '1.0.0',
                      );
                    },
                    icon: Icon(Icons.article_outlined, size: 18),
                    label: Text(movaText('Licencias')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(movaText('Cerrar')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SecurityDialog extends StatefulWidget {
  const _SecurityDialog();

  @override
  State<_SecurityDialog> createState() => _SecurityDialogState();
}

class _SecurityDialogState extends State<_SecurityDialog> {
  final _database = DatabaseHelper();
  final _pin = TextEditingController();
  String? _mode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _database.getSecurityMode().then((mode) {
      if (mounted) {
        setState(() {
          _mode = mode;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _choose(String mode) async {
    if (mode == 'biometric') {
      final result = await BiometricAuth().authenticate();
      if (result == BiometricResult.unavailable) {
        if (mounted) {
          showMovaError(
            context,
            'La biometría no está disponible o no está configurada en este dispositivo.',
            title: movaText('Biometría no disponible'),
          );
        }
        return;
      }
      if (result != BiometricResult.authenticated) {
        if (mounted) {
          showMovaError(
            context,
            result == BiometricResult.canceled
                ? 'La verificación fue cancelada.'
                : biometricLastError == null
                ? 'No se pudo verificar tu identidad. Confirma que tienes una huella o rostro registrado en los ajustes del teléfono.'
                : 'El sistema biométrico devolvió un error. Verifica la biometría configurada en tu teléfono e inténtalo nuevamente.',
            title: movaText('Verificación no completada'),
          );
        }
        return;
      }
      await _database.setSecurity(mode: mode);
    } else {
      final value = await showDialog<String>(
        context: context,
        builder: (_) => _PinDialog(),
      );
      if (value == null) return;
      await _database.setSecurity(mode: mode, pin: value);
    }
    if (mounted) setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _DialogIcon(
                    icon: Icons.shield_rounded,
                    color: Color(0xFF0C2340),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.text('security'),
                          style: const TextStyle(
                            color: Color(0xFF102A43),
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l10n.text('security_intro'),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD4EEF3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF007C91),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.text('security_exclusive_note'),
                        style: const TextStyle(
                          color: Color(0xFF28645D),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 38),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _SecurityOption(
                  icon: Icons.fingerprint_rounded,
                  title: movaText('Huella o biometría'),
                  subtitle: movaText('Usa el sensor del dispositivo'),
                  selected: _mode == 'biometric',
                  onTap: () => _choose('biometric'),
                ),
                const SizedBox(height: 10),
                _SecurityOption(
                  icon: Icons.pin_rounded,
                  title: movaText('Números (PIN)'),
                  subtitle: movaText('Crea un código de 4 a 8 dígitos'),
                  selected: _mode == 'pin',
                  onTap: () => _choose('pin'),
                ),
                if (_mode != null && _mode != 'none') ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await _database.setSecurity(mode: 'none');
                      if (mounted) setState(() => _mode = 'none');
                    },
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(movaText('Desactivar protección')),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0C2340),
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: Color(0xFFD7E0EA)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(l10n.text('Cerrar')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SecurityOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0C2340);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2F9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? navy : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? navy : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF526D8D),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF102A43),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? navy : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinDialog extends StatefulWidget {
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(movaText('Crear PIN')),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        maxLength: 8,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: movaText('PIN de 4 a 8 dígitos'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(movaText('Cancelar')),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (!RegExp(r'^\d{4,8}$').hasMatch(value)) return;
            Navigator.pop(context, value);
          },
          child: Text(movaText('Guardar')),
        ),
      ],
    );
  }
}

class _BudgetDialogState extends State<_BudgetDialog> {
  final _database = DatabaseHelper();
  final _controller = TextEditingController();
  late Future<List<Map<String, dynamic>>> _transactions;
  String _currency = 'MXN';
  String _budgetPeriod = 'monthly';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _transactions = _database.getTransactions();
    _database.getCurrency().then((value) {
      if (mounted && movaCurrencies.any((currency) => currency.code == value)) {
        setState(() => _currency = value);
      }
    });
    _database.getMonthlyBudget().then((value) {
      if (mounted && value != null) {
        _controller.text = value.toStringAsFixed(2);
      }
    });
    _database.getBudgetPeriod().then((value) {
      if (mounted) setState(() => _budgetPeriod = value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final rawAmount = _controller.text.trim();
    final amount = rawAmount.isEmpty
        ? null
        : double.tryParse(rawAmount.replaceAll(',', '.'));
    if (rawAmount.isNotEmpty && (amount == null || amount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(movaText('Ingresa un presupuesto válido'))),
      );
      return;
    }
    setState(() => _saving = true);
    await _database.setMonthlyBudget(amount);
    await _database.setBudgetPeriod(_budgetPeriod);
    await appCurrencyController.setCurrency(_currency);
    if (amount != null &&
        await _database.getNotificationsEnabled() &&
        await _database.getNotificationOption('notification_budget')) {
      final notificationPrefix = _budgetPeriod == 'weekly'
          ? movaText('Tu límite semanal quedó en')
          : movaText('Tu límite mensual quedó en');
      await NotificationService.show(
        id: 100,
        title: movaText('Presupuesto actualizado'),
        body: '$notificationPrefix ${_formatMoney(amount)}.',
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currency = movaCurrencies.firstWhere(
      (item) => item.code == _currency,
      orElse: () => movaCurrencies.first,
    );
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: EdgeInsets.fromLTRB(24, 0, 24, 8),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movaText('Presupuesto'), style: TextStyle(fontSize: 19)),
                SizedBox(height: 3),
                Text(
                  movaText('Controla tus gastos sin perder de vista tu límite'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ],
      ),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactions,
        builder: (context, snapshot) {
          final now = DateTime.now();
          final start = _budgetPeriod == 'weekly'
              ? now.subtract(Duration(days: now.weekday - 1))
              : DateTime(now.year, now.month, 1);
          final end = _budgetPeriod == 'weekly'
              ? start.add(Duration(days: 7))
              : DateTime(now.year, now.month + 1, 1);
          final spent = (snapshot.data ?? [])
              .where((row) {
                final date = DateTime.tryParse(row['date'] as String? ?? '');
                return row['is_income'] == 0 &&
                    !DatabaseHelper.isSavingsDeposit(row) &&
                    date != null &&
                    !date.isBefore(start) &&
                    date.isBefore(end);
              })
              .fold<double>(
                0,
                (sum, row) => sum + (row['amount'] as num).toDouble(),
              );
          final budget =
              double.tryParse(_controller.text.trim().replaceAll(',', '.')) ??
              0;
          final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
          final exceeded = budget > 0 && spent > budget;
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: exceeded
                            ? [Colors.red.shade50, Colors.orange.shade50]
                            : [
                                Theme.of(context).colorScheme.primaryContainer,
                                Theme.of(context).colorScheme.surface,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exceeded
                                    ? movaText('Presupuesto excedido')
                                    : _budgetPeriod == 'weekly'
                                    ? movaText('Esta semana')
                                    : movaText('Este mes'),
                                style: TextStyle(
                                  color: exceeded
                                      ? Colors.red.shade800
                                      : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '${_formatMoney(spent)} $_currency',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                movaText('gastado hasta hoy'),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 7,
                            backgroundColor: Colors.white.withValues(
                              alpha: .75,
                            ),
                            color: exceeded ? Colors.red : Color(0xFF0C2340),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'weekly',
                        label: Text(movaText('Semanal')),
                        icon: Icon(Icons.view_week_outlined),
                      ),
                      ButtonSegment(
                        value: 'monthly',
                        label: Text(movaText('Mensual')),
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                    selected: {_budgetPeriod},
                    onSelectionChanged: (selection) {
                      setState(() => _budgetPeriod = selection.first);
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    _budgetPeriod == 'weekly'
                        ? movaText(
                            'Se reinicia cada lunes y considera tus gastos de esta semana.',
                          )
                        : movaText('Se reinicia el primer día de cada mes.'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: movaText('Límite mensual (${currency.code})'),
                      hintText: movaText('Ej. 8,000.00'),
                      prefixIcon: Icon(Icons.savings_outlined),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: movaText('Quitar límite'),
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer
                          .withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary
                            .withValues(alpha: .25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.public,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                movaText('Moneda general de MOVA'),
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              currency.code,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          movaText(
                            movaText(
                              'Se aplicará a ingresos, gastos, metas, compras y presupuesto. No convierte cantidades existentes.',
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _currency,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: movaText('Moneda de la aplicación'),
                            prefixIcon: Icon(Icons.currency_exchange),
                            border: OutlineInputBorder(),
                          ),
                          items: movaCurrencies
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.code,
                                  child: Text(
                                    movaText(
                                      '${item.code} · ${item.name} (${item.symbol})',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _currency = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    movaText(
                      'Cambiar la moneda no modifica el límite configurado.',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(movaText('Cancelar')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(movaText('Guardar')),
        ),
      ],
    );
  }

  String _formatMoney(double value) {
    final currency = movaCurrencies.firstWhere(
      (item) => item.code == _currency,
      orElse: () => movaCurrencies.first,
    );
    return '${currency.symbol}${value.toStringAsFixed(2)}';
  }
}

class _CategoriesScreen extends StatefulWidget {
  const _CategoriesScreen();

  @override
  State<_CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<_CategoriesScreen> {
  final _database = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _categories;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _categories = _database.getCustomCategories();
  }

  Future<void> _add() async {
    final result = await showDialog<_CategoryInput>(
      context: context,
      builder: (_) => _CategoryDialog(),
    );
    if (result == null) return;
    try {
      await _database.addCustomCategory(
        name: result.name,
        type: result.type,
        emoji: result.emoji,
      );
      if (mounted) setState(_load);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(movaText('Esa categoría ya existe para ese tipo')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoreScreen.backgroundColor,
      appBar: AppBar(
        title: Text(movaText('Categorías')),
        backgroundColor: MoreScreen.backgroundColor,
        foregroundColor: MoreScreen.darkNavy,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: Color(0xFF0C2340),
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text(movaText('Nueva categoría')),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categories,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Text(movaText('Aún no tienes categorías personalizadas')),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  leading: Text(
                    category['emoji'] as String,
                    style: TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    context.l10n.translate(category['name'] as String),
                  ),
                  subtitle: Text(
                    category['type'] == 'income'
                        ? context.l10n.text('income_singular')
                        : context.l10n.text('expense'),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Color(0xFFB42318)),
                    onPressed: () async {
                      await _database.deleteCustomCategory(
                        category['id'] as int,
                      );
                      if (mounted) setState(_load);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryInput {
  final String name;
  final String type;
  final String emoji;

  _CategoryInput(this.name, this.type, this.emoji);
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog();

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _name = TextEditingController();
  String _type = 'expense';
  String _emoji = '📦';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _type == 'income';
    final accent = isIncome ? Color(0xFF0C2340) : Color(0xFF36577D);
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 430,
            maxHeight: MediaQuery.sizeOf(context).height - 48,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _categoryHeader(accent),
                SizedBox(height: 18),
                _inputLabel(
                  'Nombre de la categoría',
                  Icons.label_outline_rounded,
                ),
                SizedBox(height: 7),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Color(0xFFD8E1EB)),
                  ),
                  child: TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: movaText('Ej. Comida, transporte o freelance'),
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.edit_rounded, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 17),
                Text(
                  movaText('¿Qué tipo de movimiento será?'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _typeOption(
                        'expense',
                        'Gasto',
                        Icons.arrow_downward_rounded,
                        Color(0xFF36577D),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _typeOption(
                        'income',
                        'Ingreso',
                        Icons.arrow_upward_rounded,
                        Color(0xFF0C2340),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 17),
                _inputLabel('Icono o emoji', Icons.emoji_emotions_outlined),
                SizedBox(height: 7),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Color(0xFFD8E1EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_emoji, style: TextStyle(fontSize: 24)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          maxLength: 2,
                          onChanged: (value) {
                            final trimmed = value.trim();
                            if (trimmed.isNotEmpty) {
                              setState(() => _emoji = trimmed);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: movaText('Elige un emoji'),
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_rounded,
                        color: Color(0xFF94A3B8),
                        size: 19,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  movaText(
                    'Puedes usar un emoji para identificarla más rápido.',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(movaText('Cancelar')),
                    ),
                    SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        if (_name.text.trim().isEmpty) return;
                        Navigator.pop(
                          context,
                          _CategoryInput(_name.text.trim(), _type, _emoji),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Color(0xFF0C2340),
                        padding: EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: Icon(Icons.add_rounded, size: 18),
                      label: Text(movaText('Crear categoría')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Color(0xFF0C2340)),
        SizedBox(width: 7),
        Text(
          movaText(text),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF334E68),
          ),
        ),
      ],
    );
  }

  Widget _categoryHeader(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(Icons.category_outlined, color: accent, size: 25),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movaText('Nueva categoría'),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                movaText(
                  'Personaliza tus movimientos para encontrarlos fácilmente',
                ),
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _typeOption(String value, String label, IconData icon, Color color) {
    final selected = _type == value;
    return InkWell(
      onTap: () => setState(() => _type = value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .12) : Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Color(0xFFD7E3E8),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .14),
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Color(0xFF64748B), size: 20),
            SizedBox(height: 4),
            Text(
              movaText(label),
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
