import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:typed_data';

import 'dart:convert';

import 'package:mova/database/database_helper.dart';
import 'package:mova/services/biometric_auth.dart';
import 'package:mova/services/notification_service.dart';
import 'package:mova/services/currency_controller.dart';
import 'package:mova/widgets/user_avatar.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';
import 'shopping_screen.dart';

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
    if (saved)
      Navigator.pop(context, true);
    else
      setState(() => _saving = false);
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: _loading
              ? const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEF5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.manage_accounts_rounded,
                            color: Color(0xFF0C2340),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mi cuenta',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Administra tu información personal',
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
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFFE8EEF5),
                            backgroundImage: _image == null
                                ? null
                                : MemoryImage(_image!),
                            child: _image == null
                                ? const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF0C2340),
                                    size: 48,
                                  )
                                : null,
                          ),
                          Material(
                            color: const Color(0xFF0C2340),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _pickImage,
                              customBorder: const CircleBorder(),
                              child: const Padding(
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
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _pickImage,
                        child: Text(
                          _image == null
                              ? 'Agregar foto de perfil'
                              : 'Cambiar foto de perfil',
                        ),
                      ),
                    ),
                    if (_image != null)
                      Center(
                        child: TextButton(
                          onPressed: _removeImage,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFB42318),
                          ),
                          child: const Text('Quitar foto'),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _ProfileField(
                      label: 'Nombre',
                      icon: Icons.person_outline_rounded,
                      child: TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu nombre',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ProfileField(
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      child: TextField(
                        enabled: false,
                        controller: _email,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0C2340),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Guardar cambios'),
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
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(icon, color: const Color(0xFF0C2340), size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
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

  static const Color backgroundColor = Color(0xFFF1F5F9);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color subtitleGrey = Color(0xFF64748B);
  static const Color sectionHeaderColor = Color(0xFF475569);

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMoreHeader(context),
              const SizedBox(height: 22),

              FutureBuilder<Map<String, dynamic>?>(
                future: DatabaseHelper().getCurrentUser(),
                builder: (context, snapshot) {
                  final name =
                      (snapshot.data?['name'] as String?) ?? 'Mi perfil';
                  final email =
                      (snapshot.data?['email'] as String?) ?? 'Mi cuenta';
                  return _buildProfileCard(context, name, email);
                },
              ),
              const SizedBox(height: 24),

              // --- SECCIÓN: FINANZAS ---
              _buildSectionTitle("FINANZAS"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.monetization_on_outlined,
                      title: "Presupuesto",
                      subtitle: "Define cuánto quieres gastar",
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => const _BudgetDialog(),
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.label_outline,
                      title: "Categorías",
                      subtitle:
                          "Administra tus categorías de ingresos y gastos",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _CategoriesScreen(),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.shopping_cart_outlined,
                      title: "Listas de compras",
                      subtitle:
                          "Organiza productos, calcula y registra tus compras",
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ShoppingScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: APLICACIÓN ---
              _buildSectionTitle("APLICACIÓN"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.notifications_none_outlined,
                      title: "Notificaciones",
                      subtitle: "Gestiona tus recordatorios",
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => const _NotificationsDialog(),
                      ),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.lock_outline,
                      title: "Seguridad",
                      subtitle: "Protege tu información",
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => const _SecurityDialog(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: DATOS ---
              _buildSectionTitle("DATOS"),
              _buildCardContainer(
                context: context,
                child: Column(
                  children: [
                    _buildOptionTile(
                      context: context,
                      icon: Icons.upload_outlined,
                      title: "Exportar datos",
                      subtitle: "Descarga tus movimientos",
                      onTap: () => _exportData(context),
                    ),
                    _buildDivider(),
                    _buildOptionTile(
                      context: context,
                      icon: Icons.download_outlined,
                      title: "Importar datos",
                      subtitle: "Importa información existente",
                      onTap: () => _importData(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: INFORMACIÓN ---
              _buildSectionTitle("INFORMACIÓN"),
              _buildCardContainer(
                context: context,
                child: _buildOptionTile(
                  context: context,
                  icon: Icons.info_outline,
                  title: "Acerca de MOVA",
                  subtitle: "Versión 1.0.0",
                  onTap: () => _showAbout(context),
                ),
              ),
              const SizedBox(height: 20),

              // --- SECCIÓN: CUENTA (CERRAR SESIÓN) ---
              _buildSectionTitle("CUENTA"),
              _buildCardContainer(
                context: context,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFEF4444),
                            size: 22,
                          ),
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
      padding: const EdgeInsets.only(left: 3.0, bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 15,
            decoration: BoxDecoration(
              color: const Color(0xFF0C2340),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
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
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
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
              gradient: const LinearGradient(
                colors: [Color(0xFF0C2340), Color(0xFF36577D)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Más',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: MoreScreen.darkNavy,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Todo lo que necesitas para controlar MOVA',
                  style: TextStyle(
                    fontSize: 12,
                    color: MoreScreen.subtitleGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
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
            builder: (_) => const _ProfileDialog(),
          );
          if (mounted) setState(() {});
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0C2340), Color(0xFF1E3A5F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0C2340).withOpacity(.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const UserAvatar(radius: 29),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFFCBD5E1),
                      size: 17,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.12)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Editar información de tu cuenta',
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
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(
                  context,
                  icon: Icons.cloud_done_rounded,
                  title: 'Copia lista',
                  subtitle: 'Tu información está preparada para guardarse',
                  color: const Color(0xFF0C2340),
                ),
                const SizedBox(height: 18),
                _infoPanel(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'Respaldo local',
                  text: 'El archivo se copió al portapapeles. Pégalo en un lugar seguro para conservarlo.',
                  color: const Color(0xFFE8F5F0),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _dataStat(
                      context,
                      Icons.receipt_long_outlined,
                      '$transactionCount',
                      'movimientos',
                    ),
                    _dataStat(
                      context,
                      Icons.flag_outlined,
                      '$goalCount',
                      'metas',
                    ),
                    _dataStat(
                      context,
                      Icons.shopping_bag_outlined,
                      '$shoppingCount',
                      'listas',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: encoded));
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar de nuevo'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendido'),
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
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dialogHeader(
                  context,
                  icon: Icons.file_download_outlined,
                  title: 'Importar respaldo',
                  subtitle: 'Agrega información de otra copia de MOVA',
                  color: const Color(0xFF007C91),
                ),
                const SizedBox(height: 18),
                _infoPanel(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'Antes de continuar',
                  text: 'Pega aquí el JSON exportado desde MOVA. Tus datos actuales no se eliminarán.',
                  color: const Color(0xFFEAF6FA),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E3E8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 12, 15, 0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.data_object_rounded,
                              size: 19,
                              color: Color(0xFF007C91),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Contenido de la copia',
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
                        decoration: const InputDecoration(
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
                const SizedBox(height: 8),
                Text(
                  'Solo se importan movimientos válidos. La información existente se conserva.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, controller.text),
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Importar'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$count movimientos importados')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El archivo no tiene un formato válido')),
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
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(fontSize: 12, height: 1.35)),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: MoreScreen.subtitleGrey,
            ),
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
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(.18), accent.withOpacity(.07)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: MoreScreen.darkNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.2,
                        color: MoreScreen.subtitleGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: accent.withOpacity(.7),
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
        return const Color(0xFF0C2340);
      case 'Categorías':
        return const Color(0xFF36577D);
      case 'Listas de compras':
        return const Color(0xFF526D8D);
      case 'Notificaciones':
        return const Color(0xFF1E3A5F);
      case 'Seguridad':
        return const Color(0xFF263F61);
      case 'Exportar datos':
        return const Color(0xFF315A80);
      case 'Importar datos':
        return const Color(0xFF3E6C91);
      case 'Acerca de MOVA':
        return const Color(0xFF587A9B);
      default:
        return const Color(0xFF0C2340);
    }
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

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog();

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
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
      title: const Text('Notificaciones'),
      content: _loading
          ? const SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activar notificaciones'),
                  subtitle: const Text('Permite recibir recordatorios de Mova'),
                  value: _enabled,
                  onChanged: (value) async {
                    setState(() => _enabled = value);
                    await _set('notifications_enabled', value);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Presupuesto'),
                  subtitle: const Text(
                    'Avisos relacionados con tu límite mensual',
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
                  title: const Text('Metas'),
                  subtitle: const Text(
                    'Recordatorios para avanzar en tus metas',
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
                  title: const Text('Lista de compras'),
                  subtitle: const Text('Recordatorios de listas pendientes'),
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
          child: const Text('Cerrar'),
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
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
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'MOVA',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                'Versión 1.0.0  ·  Finanzas personales',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
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
                        'MOVA está diseñada con un enfoque offline-first. Tus datos principales se mantienen en tu dispositivo.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Organiza ingresos, gastos, metas y compras en un solo espacio, de forma clara y sencilla.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showLicensePage(
                          context: context,
                          applicationName: 'MOVA',
                          applicationVersion: '1.0.0',
                        );
                      },
                      icon: const Icon(Icons.article_outlined, size: 18),
                      label: const Text('Licencias'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
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
      if (mounted)
        setState(() {
          _mode = mode;
          _loading = false;
        });
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
        if (mounted)
          _message('La biometría no está disponible en este dispositivo.');
        return;
      }
      if (result != BiometricResult.authenticated) {
        if (mounted) _message('No se pudo verificar la biometría.');
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

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seguridad'),
      content: _loading
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Elige cómo proteger tu sesión.'),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'biometric',
                  groupValue: _mode,
                  title: const Text('Huella o biometría'),
                  subtitle: const Text('Usa el sensor del dispositivo'),
                  secondary: const Icon(Icons.fingerprint),
                  onChanged: (value) => _choose(value!),
                ),
                RadioListTile<String>(
                  value: 'pin',
                  groupValue: _mode,
                  title: const Text('Números (PIN)'),
                  subtitle: const Text('Crea un código de 4 a 8 dígitos'),
                  secondary: const Icon(Icons.pin_outlined),
                  onChanged: (value) => _choose(value!),
                ),
                if (_mode != null)
                  TextButton(
                    onPressed: () async {
                      await _database.setSecurity(mode: 'none');
                      if (mounted) setState(() => _mode = 'none');
                    },
                    child: const Text('Desactivar protección'),
                  ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
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
      title: const Text('Crear PIN'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        maxLength: 8,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'PIN de 4 a 8 dígitos'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value = _controller.text.trim();
            if (!RegExp(r'^\d{4,8}$').hasMatch(value)) return;
            Navigator.pop(context, value);
          },
          child: const Text('Guardar'),
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
        const SnackBar(content: Text('Ingresa un presupuesto válido')),
      );
      return;
    }
    setState(() => _saving = true);
    await _database.setMonthlyBudget(amount);
    await appCurrencyController.setCurrency(_currency);
    if (amount != null &&
        await _database.getNotificationsEnabled() &&
        await _database.getNotificationOption('notification_budget')) {
      await NotificationService.show(
        id: 100,
        title: 'Presupuesto actualizado',
        body: 'Tu límite mensual quedó en ${_formatMoney(amount)}.',
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Presupuesto mensual', style: TextStyle(fontSize: 19)),
                SizedBox(height: 3),
                Text(
                  'Controla tus gastos sin perder de vista tu límite',
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
          final spent = (snapshot.data ?? [])
              .where((row) {
                final date = DateTime.tryParse(row['date'] as String? ?? '');
                return row['is_income'] == 0 &&
                    date != null &&
                    date.year == now.year &&
                    date.month == now.month;
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
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
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
                                exceeded ? 'Presupuesto excedido' : 'Este mes',
                                style: TextStyle(
                                  color: exceeded
                                      ? Colors.red.shade800
                                      : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_formatMoney(spent)} $_currency',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'gastado hasta hoy',
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
                            backgroundColor: Colors.white.withOpacity(.75),
                            color: exceeded
                                ? Colors.red
                                : const Color(0xFF0C2340),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Límite mensual (${currency.code})',
                      hintText: 'Ej. 8,000.00',
                      prefixIcon: const Icon(Icons.savings_outlined),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Quitar límite',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer
                          .withOpacity(.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary
                            .withOpacity(.25),
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
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Moneda general de MOVA',
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
                        const SizedBox(height: 5),
                        Text(
                          'Se aplicará a ingresos, gastos, metas, compras y presupuesto. No convierte cantidades existentes.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _currency,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Moneda de la aplicación',
                            prefixIcon: Icon(Icons.currency_exchange),
                            border: OutlineInputBorder(),
                          ),
                          items: movaCurrencies
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.code,
                                  child: Text(
                                    '${item.code} · ${item.name} (${item.symbol})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => _currency = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Configuración independiente: cambiar la moneda no modifica el límite mensual.',
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
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
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
      builder: (_) => const _CategoryDialog(),
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
        const SnackBar(content: Text('Esa categoría ya existe para ese tipo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoreScreen.backgroundColor,
      appBar: AppBar(
        title: const Text('Categorías'),
        backgroundColor: MoreScreen.backgroundColor,
        foregroundColor: MoreScreen.darkNavy,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: const Color(0xFF0C2340),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categories,
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(
              child: Text('Aún no tienes categorías personalizadas'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  leading: Text(
                    category['emoji'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(category['name'] as String),
                  subtitle: Text(
                    category['type'] == 'income' ? 'Ingreso' : 'Gasto',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB42318),
                    ),
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

  const _CategoryInput(this.name, this.type, this.emoji);
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
    final accent = isIncome ? const Color(0xFF0C2340) : const Color(0xFF007C91);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _categoryHeader(accent),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la categoría',
                  hintText: 'Ej. Comida, transporte o freelance',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Qué tipo de movimiento será?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _typeOption(
                      'expense',
                      'Gasto',
                      Icons.arrow_downward_rounded,
                      const Color(0xFF007C91),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeOption(
                      'income',
                      'Ingreso',
                      Icons.arrow_upward_rounded,
                      const Color(0xFF0C2340),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                maxLength: 2,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Icono o emoji',
                  hintText: '📦',
                  prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      widthFactor: 1,
                      child: Text(_emoji, style: const TextStyle(fontSize: 23)),
                    ),
                  ),
                ),
                onChanged: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) setState(() => _emoji = trimmed);
                },
              ),
              const SizedBox(height: 4),
              Text(
                'Puedes usar un emoji para identificarla más rápido.',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      if (_name.text.trim().isEmpty) return;
                      Navigator.pop(
                        context,
                        _CategoryInput(_name.text.trim(), _type, _emoji),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Crear categoría'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva categoría',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Personaliza tus movimientos para encontrarlos fácilmente',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: .1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFFD7E3E8),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? color : const Color(0xFF64748B),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
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
