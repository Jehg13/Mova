import 'package:flutter/material.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/biometric_auth.dart';
import 'package:mova/screens/analytics_screen.dart';
import 'package:mova/screens/goals_screen.dart';
import 'package:mova/screens/more_screen.dart';
import 'home_screen.dart';
import 'transaction_screen.dart';
import '../widgets/mova_loading_overlay.dart';
import '../widgets/mova_feedback_dialog.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  final _database = DatabaseHelper();
  bool _locked = false;
  bool _checkingLock = true;
  bool _isSwitchingSection = false;
  int _selectedIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<AddTransactionScreenState> _transactionKey =
      GlobalKey<AddTransactionScreenState>();

  late final List<Widget> _screens = [
    HomeScreen(key: _homeKey), // Índice 0: Inicio
    const AnalyticsScreen(), // Índice 1
    AddTransactionScreen(key: _transactionKey), // Índice 2: Agregar
    const GoalsScreen(), // Índice 3
    const MoreScreen(), // Índice 4
  ];

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final mode = await _database.getSecurityMode();
    if (!mounted) return;
    setState(() {
      _locked = mode == 'pin' || mode == 'biometric';
      _checkingLock = false;
    });
    if (_locked) await _unlock(mode!);
  }

  Future<void> _unlock(String mode) async {
    if (mode == 'biometric') {
      final result = await BiometricAuth().authenticate();
      if (!mounted) return;
      if (result == BiometricResult.authenticated) {
        setState(() => _locked = false);
      }
      return;
    }
    final pin = await _database.getSecurityPin();
    if (!mounted || pin == null) return;
    final entered = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UnlockPinDialog(),
    );
    if (!mounted) return;
    if (entered == pin) {
      setState(() => _locked = false);
    } else {
      await showMovaError(
        context,
        'El PIN ingresado no es correcto.',
        title: 'PIN incorrecto',
      );
      await _unlock(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLock) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      // --- CAMBIO CLAVE AQUÍ: IndexedStack permite cambiar al instante al presionar ---
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          if (_locked)
            const ModalBarrier(dismissible: false, color: Color(0xDDFFFFFF)),
          if (_isSwitchingSection)
            const MovaLoadingOverlay(message: 'Cargando tu sección'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: IgnorePointer(
          ignoring: _isSwitchingSection || _locked,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF1E3A5F),
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedIndex,
            onTap: (index) async {
              if (index == _selectedIndex) return;
              setState(() {
                _isSwitchingSection = true;
                _selectedIndex = index;
              });
              if (index == 0) {
                _homeKey.currentState?.refresh();
              }

              if (index == 2) {
                _transactionKey.currentState?.refreshCategories();
              }
              await Future<void>.delayed(const Duration(milliseconds: 360));
              if (mounted) setState(() => _isSwitchingSection = false);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: "Análisis",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle, size: 40),
                label: "Agregar",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.track_changes),
                label: "Metas",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Más"),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockPinDialog extends StatefulWidget {
  const _UnlockPinDialog();

  @override
  State<_UnlockPinDialog> createState() => _UnlockPinDialogState();
}

class _UnlockPinDialogState extends State<_UnlockPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Desbloquear MOVA'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 8,
        decoration: const InputDecoration(labelText: 'Ingresa tu PIN'),
        onSubmitted: (_) => Navigator.pop(context, _controller.text),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Desbloquear'),
        ),
      ],
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
