import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mova/database/database_helper.dart';
import 'package:mova/services/biometric_auth.dart';
import 'package:mova/screens/analytics_screen.dart';
import 'package:mova/screens/goals_screen.dart';
import 'package:mova/screens/more_screen.dart';
import 'package:mova/screens/subscriptions_screen.dart';
import 'package:mova/screens/accounts_screen.dart';
import 'package:mova/screens/upcoming_payments_screen.dart';

import 'home_screen.dart';
import 'transaction_screen.dart';
import '../widgets/mova_feedback_dialog.dart';
import '../widgets/mova_design_system.dart';

class NavigationWrapper extends StatefulWidget {
  const NavigationWrapper({super.key});

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  static const _androidLifecycleChannel = MethodChannel(
    'com.example.mova/app_lifecycle',
  );
  final _database = DatabaseHelper();
  bool _locked = false;
  bool _checkingLock = true;
  int _selectedIndex = 0;
  final Set<int> _visitedSections = {0};
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<AddTransactionScreenState> _transactionKey =
      GlobalKey<AddTransactionScreenState>();

  Widget _screenForIndex(int index) {
    if (!_visitedSections.contains(index)) return const SizedBox.shrink();
    return switch (index) {
      0 => HomeScreen(
        key: _homeKey,
        onOpenSubscriptions: _openSubscriptions,
        onOpenAccounts: _openAccounts,
        onOpenPayments: _openPayments,
      ),
      1 => const AnalyticsScreen(),
      2 => AddTransactionScreen(key: _transactionKey),
      3 => const GoalsScreen(),
      4 => const MoreScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _openSubscriptions() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
    );
    if (mounted) _homeKey.currentState?.refresh();
  }

  Future<void> _openAccounts() async {
    await Navigator.of(context)
        .push<void>(MaterialPageRoute(builder: (_) => const AccountsScreen()));
    if (mounted) _homeKey.currentState?.refresh();
  }

  Future<void> _openPayments() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const UpcomingPaymentsScreen()),
    );
    if (mounted) _homeKey.currentState?.refresh();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navigationSurface = isDark ? MovaDesign.darkSurface : Colors.white;
    final navigationBorder = isDark ? MovaDesign.darkBorder : MovaDesign.border;
    return Scaffold(
      // --- CAMBIO CLAVE AQUÍ: IndexedStack permite cambiar al instante al presionar ---
      body: PopScope<Object?>(
        canPop: defaultTargetPlatform != TargetPlatform.android,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && defaultTargetPlatform == TargetPlatform.android) {
            unawaited(
              _androidLifecycleChannel.invokeMethod<bool>('moveTaskToBack'),
            );
          }
        },
        child: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: List<Widget>.generate(5, (index) {
                final selected = index == _selectedIndex;
                final duration = MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180);
                return TickerMode(
                  enabled: selected,
                  child: IgnorePointer(
                    ignoring: !selected,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: _screenForIndex(index),
                    ),
                  ),
                );
              }),
            ),
            if (_locked)
              const ModalBarrier(dismissible: false, color: Color(0xDDFFFFFF)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: navigationBorder)),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x55000000)
                    : const Color(0x080C2340),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ColoredBox(
            color: navigationSurface,
            child: IgnorePointer(
              ignoring: _locked,
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: isDark
                    ? MovaDesign.darkText
                    : MovaDesign.navy,
                unselectedItemColor: isDark
                    ? const Color(0xFFA4A4A4)
                    : MovaDesign.muted,
                selectedFontSize: 11,
                unselectedFontSize: 10,
                iconSize: 22,
                currentIndex: _selectedIndex,
                onTap: (index) {
                  if (index == _selectedIndex) return;
                  HapticFeedback.selectionClick();
                  final wasVisited = _visitedSections.contains(index);
                  setState(() {
                    _visitedSections.add(index);
                    _selectedIndex = index;
                  });
                  if (index == 0) {
                    _homeKey.currentState?.refresh();
                  }

                  if (index == 2 && wasVisited) {
                    _transactionKey.currentState?.refreshCategories();
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: "Inicio",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.insights_outlined),
                    activeIcon: Icon(Icons.insights_rounded),
                    label: "Análisis",
                  ),
                  BottomNavigationBarItem(
                    icon: _AddNavigationIcon(),
                    activeIcon: _AddNavigationIcon(selected: true),
                    label: "Agregar",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.flag_outlined),
                    activeIcon: Icon(Icons.flag_rounded),
                    label: "Metas",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_outlined),
                    activeIcon: Icon(Icons.grid_view_rounded),
                    label: "Más",
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

class _AddNavigationIcon extends StatelessWidget {
  const _AddNavigationIcon({this.selected = false});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 42,
      height: 34,
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: selected
            ? MovaDesign.navy
            : isDark
            ? MovaDesign.darkElevatedSurface
            : const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.add_rounded,
        size: 25,
        color: selected ? Colors.white : MovaDesign.accent,
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
