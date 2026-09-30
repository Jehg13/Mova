import 'package:flutter/material.dart';

abstract final class MovaDesign {
  static const ink = Color(0xFF102A43);
  static const navy = Color(0xFF0C2340);
  static const deepBlue = Color(0xFF12365B);
  static const blue = Color(0xFF1D496B);
  static const softBlue = Color(0xFFE5F0F7);
  static const blueGlow = Color(0x6639B8C8);
  static const muted = Color(0xFF64748B);
  static const canvas = Color(0xFFF3F6FA);
  static const surface = Colors.white;
  static const elevatedSurface = Color(0xFFFBFCFE);
  static const border = Color(0xFFE3EAF1);
  static const borderHighlight = Color(0xFFB9DDE4);
  static const accent = Color(0xFF20A6B5);
  static const positive = Color(0xFF16845B);
  static const positiveSoft = Color(0xFFE7F3ED);
  static const negative = Color(0xFFB42318);
  static const negativeSoft = Color(0xFFFBECEB);
  static const warning = Color(0xFFB96A19);
  static const warningSoft = Color(0xFFFFF3E3);
  static const darkCanvas = Color(0xFF081A2B);
  static const darkSurface = Color(0xFF142B45);
  static const darkElevatedSurface = Color(0xFF1B3856);
  static const darkBorder = Color(0xFF29445E);
  static const darkText = Color(0xFFE6F4F8);

  static const primaryGradient = LinearGradient(
    colors: [navy, deepBlue, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const accentGradient = LinearGradient(
    colors: [deepBlue, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const cardShadow = [
    BoxShadow(color: Color(0x140C2340), blurRadius: 22, offset: Offset(0, 8)),
  ];
  static const radiusSmall = 12.0;
  static const radiusMedium = 18.0;
  static const radiusLarge = 24.0;
}

class MovaSurface extends StatelessWidget {
  const MovaSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = MovaDesign.radiusMedium,
    this.color = MovaDesign.surface,
    this.borderColor = MovaDesign.border,
    this.elevation = false,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color? borderColor;
  final bool elevation;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: clipBehavior,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor == null ? null : Border.all(color: borderColor!),
      boxShadow: elevation
          ? const [
              BoxShadow(
                color: Color(0x0C0C2340),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ]
          : null,
    ),
    child: child,
  );
}

class MovaSectionHeader extends StatelessWidget {
  const MovaSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: MovaDesign.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -.15,
          ),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class MovaProgressBar extends StatelessWidget {
  const MovaProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = MovaDesign.accent,
    this.backgroundColor = const Color(0xFFE7EDF3),
    this.duration = const Duration(milliseconds: 450),
  });

  final double value;
  final double height;
  final Color color;
  final Color backgroundColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(height),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: value.clamp(0, 1)),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) => Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * animatedValue,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.white, .18)!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(height),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .24),
                    blurRadius: 7,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class MovaAmbientGlow extends StatelessWidget {
  const MovaAmbientGlow({
    super.key,
    required this.size,
    this.color = MovaDesign.blueGlow,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    ),
  );
}

class MovaEmptyState extends StatelessWidget {
  const MovaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F3F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MovaDesign.accent, size: 29),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: MovaDesign.ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: MovaDesign.muted, height: 1.45),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
