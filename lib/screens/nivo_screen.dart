import 'package:flutter/material.dart';
import 'package:mova/models/nivo_response.dart';
import 'package:mova/models/receipt_scan_draft.dart';
import 'package:mova/services/nivo_engine.dart';
import 'package:mova/services/mova_localizations.dart';

class NivoScreen extends StatefulWidget {
  const NivoScreen({
    super.key,
    this.engine,
    this.onAsk,
    this.initialReceiptDraft,
  });

  final NivoEngine? engine;
  final Future<NivoResponse> Function(String question)? onAsk;
  final ReceiptScanDraft? initialReceiptDraft;

  @override
  State<NivoScreen> createState() => _NivoScreenState();
}

class _NivoScreenState extends State<NivoScreen> {
  static const _navy = Color(0xFF0C2340);
  static const _suggestions = [
    '¿Cuánto gasté este mes?',
    '¿Cuánto tengo disponible?',
    '¿Cómo van mis metas?',
    '¿Qué pagos tengo próximos?',
  ];

  final _scrollController = ScrollController();
  late final NivoEngine _engine;
  late final Future<NivoResponse> Function(String) _ask;
  final List<_ChatMessage> _messages = [];
  bool _processing = false;
  bool _completedAction = false;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? NivoEngine();
    _ask = widget.onAsk ?? _engine.ask;
    if (widget.initialReceiptDraft != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _proposeReceipt());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String question) async {
    if (_processing) return;
    final selectedQuestion = question.trim();
    if (selectedQuestion.isEmpty) return;
    setState(() {
      for (var index = 0; index < _messages.length; index++) {
        if (!_messages[index].isUser &&
            _messages[index].suggestions.isNotEmpty) {
          _messages[index] = _messages[index].withoutSuggestions();
        }
      }
      _messages.add(_ChatMessage(text: selectedQuestion, isUser: true));
      _processing = true;
    });
    _scrollToLatest();

    try {
      final response = await _ask(selectedQuestion);
      if (!mounted) return;
      List<String> suggestions = const [];
      String? suggestionsError;
      try {
        suggestions = await _engine.suggestedQuestions(response);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Nivo presentation',
            context: ErrorDescription('while loading contextual suggestions'),
          ),
        );
        suggestionsError = 'No pude cargar más opciones por ahora.';
      }
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            response: response,
            isUser: false,
            suggestions: suggestions,
            suggestionsError: suggestionsError,
          ),
        );
        _completedAction |= response.data['transaction_id'] is int;
        _processing = false;
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Nivo presentation',
          context: ErrorDescription('while generating a local response'),
        ),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'No pude consultar tus datos en este momento. Inténtalo de nuevo.',
            isUser: false,
            isError: true,
          ),
        );
        _processing = false;
      });
    }

    _scrollToLatest();
  }

  Future<void> _proposeReceipt() async {
    if (!mounted || widget.initialReceiptDraft == null) return;
    setState(() {
      _messages.add(
        const _ChatMessage(
          text:
              'Preparé el comprobante analizado para que revises el registro.',
          isUser: true,
        ),
      );
      _processing = true;
    });
    try {
      final response = await _engine.proposeReceipt(
        widget.initialReceiptDraft!,
      );
      if (!mounted) return;
      List<String> suggestions = const [];
      String? suggestionsError;
      try {
        suggestions = await _engine.suggestedQuestions(response);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'Nivo presentation',
            context: ErrorDescription('while loading contextual suggestions'),
          ),
        );
        suggestionsError = 'No pude cargar más opciones por ahora.';
      }
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            response: response,
            isUser: false,
            suggestions: suggestions,
            suggestionsError: suggestionsError,
          ),
        );
        _completedAction |= response.data['transaction_id'] is int;
        _processing = false;
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'Nivo presentation',
          context: ErrorDescription('while preparing a local receipt proposal'),
        ),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: 'No pude preparar el comprobante: $error',
            isUser: false,
            isError: true,
          ),
        );
        _processing = false;
      });
    }
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_completedAction);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4F7FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Volver',
            onPressed: () => Navigator.maybePop(context, _completedAction),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _navy,
              side: const BorderSide(color: Color(0xFFE4EBF2)),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              const _NivoMark(size: 42),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nivo',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.l10n.nivoText('Tu asistente financiero local'),
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 18),
              child: _LocalStatusMark(),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        key: const Key('nivo-conversation'),
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                        itemCount: _messages.length + (_processing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const _ProcessingIndicator();
                          }
                          return _MessageBubble(
                            message: _messages[index],
                            onSuggestionTap: _processing ? null : _send,
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

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeCard(
                title: context.l10n.nivoText('Hola, soy Nivo'),
                description: context.l10n.nivoText(
                  'Puedo ayudarte a entender tus finanzas. Pregúntame sobre tus movimientos, metas o próximos pagos.',
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.touch_app_rounded,
                      color: Color(0xFF16899B),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    context.l10n.nivoText('Prueba preguntando'),
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ..._suggestions.map((suggestion) {
                final index = _suggestions.indexOf(suggestion);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SuggestionButton(
                    text: context.l10n.nivoText(suggestion),
                    icon: switch (index) {
                      0 => Icons.trending_down_rounded,
                      1 => Icons.account_balance_wallet_rounded,
                      2 => Icons.flag_rounded,
                      _ => Icons.event_available_rounded,
                    },
                    onPressed: () => _send(suggestion),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0C2340), Color(0xFF1D496B), Color(0xFF197D8D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x260C2340),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Stack(
      children: [
        const Positioned(
          top: -44,
          right: -22,
          child: _GlowOrb(size: 150, opacity: .09),
        ),
        const Positioned(
          bottom: -64,
          left: 90,
          child: _GlowOrb(size: 170, opacity: .07),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _NivoMark(size: 52, prominent: true),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF8CE1E8),
                    size: 23,
                  ),
                ],
              ),
              const SizedBox(height: 19),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFFE1F0F5),
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
              const _LocalPill(),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

class _LocalPill extends StatelessWidget {
  const _LocalPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_rounded, color: Color(0xFF8CE1E8), size: 14),
        const SizedBox(width: 6),
        Text(
          context.l10n.nivoText('Tu asistente financiero local'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _LocalStatusMark extends StatelessWidget {
  const _LocalStatusMark();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFE2F4F6),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.lock_outline_rounded,
        color: Color(0xFF16899B),
        size: 18,
      ),
    ),
  );
}

class _NivoMark extends StatelessWidget {
  const _NivoMark({this.size = 38, this.prominent = false});

  final double size;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: prominent
            ? const [Color(0xFF8CE1E8), Color(0xFF39B8C8)]
            : const [Color(0xFFE2F4F6), Color(0xFFD5EAF0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(size * .34),
      boxShadow: prominent
          ? const [
              BoxShadow(
                color: Color(0x3339B8C8),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ]
          : null,
    ),
    child: Icon(
      Icons.insights_rounded,
      color: prominent ? const Color(0xFF0C2340) : const Color(0xFF16899B),
      size: size * .53,
    ),
  );
}

class _SuggestionButton extends StatelessWidget {
  const _SuggestionButton({
    required this.text,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Material(
    color: onPressed == null ? const Color(0xFFF8FAFC) : Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(19),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: onPressed == null
                ? const Color(0xFFE8EDF2)
                : const Color(0xFFDCE8ED),
          ),
          borderRadius: BorderRadius.circular(19),
          boxShadow: onPressed == null
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x090C2340),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5F5F6), Color(0xFFDDF0F3)],
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFF16899B), size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF1E334A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF36577D),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    this.text,
    this.response,
    this.isError = false,
    this.suggestions = const [],
    this.suggestionsError,
  });

  final bool isUser;
  final String? text;
  final NivoResponse? response;
  final bool isError;
  final List<String> suggestions;
  final String? suggestionsError;

  String get content => response?.text ?? text ?? '';

  _ChatMessage withoutSuggestions() => _ChatMessage(
    isUser: isUser,
    text: text,
    response: response,
    isError: isError,
    suggestionsError: suggestionsError,
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onSuggestionTap});

  final _ChatMessage message;
  final ValueChanged<String>? onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _NivoMark(size: 23),
                    const SizedBox(width: 7),
                    const Text(
                      'Nivo',
                      style: TextStyle(
                        color: Color(0xFF36577D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * .82,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              decoration: BoxDecoration(
                color: isUser
                    ? null
                    : message.isError
                    ? const Color(0xFFFFF7ED)
                    : Colors.white,
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF12365B), Color(0xFF0C2340)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: message.isError
                            ? const Color(0xFFFED7AA)
                            : const Color(0xFFE3EBF0),
                      ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0C2340),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                context.l10n.nivoText(message.content),
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : message.isError
                      ? const Color(0xFF9A3412)
                      : const Color(0xFF1E293B),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
            if (!isUser && message.suggestionsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 4),
                child: Text(
                  context.l10n.nivoText(message.suggestionsError!),
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 12,
                  ),
                ),
              ),
            if (!isUser && message.suggestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 9, left: 4, bottom: 2),
                child: Text(
                  context.l10n.nivoText('Puedes consultar también:'),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...message.suggestions.map(
                (question) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _SuggestionButton(
                    text: context.l10n.nivoText(question),
                    onPressed: onSuggestionTap == null
                        ? null
                        : () => onSuggestionTap!(question),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  const _ProcessingIndicator();

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      label: context.l10n.nivoText('Nivo está preparando una respuesta'),
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _NivoMark(size: 28),
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3EBF0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0C2340),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF16899B),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    context.l10n.nivoText('Nivo está pensando…'),
                    style: const TextStyle(
                      color: Color(0xFF36577D),
                      fontSize: 13,
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
  );
}
