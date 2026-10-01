import 'package:flutter/material.dart';

abstract final class MovaDesign {
  static const ink = Color(0xFF101828);
  static const navy = Color(0xFF0B1F3A);
  static const deepBlue = Color(0xFF102B4E);
  static const blue = Color(0xFF203957);
  static const softBlue = Color(0xFFF2F2F2);
  static const blueGlow = Color(0x55344B68);
  static const muted = Color(0xFF6F6F6F);
  static const canvas = Color(0xFFF5F6F8);
  static const surface = Colors.white;
  static const elevatedSurface = Color(0xFFFCFCFD);
  static const border = Color(0xFFE7E7E7);
  static const borderHighlight = Color(0xFFA1A1A1);
  static const accent = navy;
  static const positive = Color(0xFF182B46);
  static const positiveSoft = Color(0xFFF2F2F2);
  static const negative = Color(0xFF101828);
  static const negativeSoft = Color(0xFFEEEEEE);
  static const warning = Color(0xFF3F3F3F);
  static const warningSoft = Color(0xFFF4F4F4);
  static const darkCanvas = Color(0xFF0D0D0D);
  static const darkSurface = Color(0xFF111B2B);
  static const darkElevatedSurface = Color(0xFF1A2638);
  static const darkBorder = Color(0xFF3F3F3F);
  static const darkText = Color(0xFFF4F4F4);

  static const primaryGradient = LinearGradient(
    colors: [navy, deepBlue, blue],
    stops: [0, .58, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const accentGradient = LinearGradient(
    colors: [navy, Color(0xFF263B57)],
    stops: [0, 1],
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
    this.color,
    this.borderColor,
    this.elevation = false,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool elevation;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: clipBehavior,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? (isDark ? MovaDesign.darkSurface : MovaDesign.surface),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              (isDark ? MovaDesign.darkBorder : MovaDesign.border),
        ),
        boxShadow: elevation
            ? [
                BoxShadow(
                  color: isDark
                      ? const Color(0x44000000)
                      : const Color(0x0C0C2340),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
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
            color: Theme.of(context).colorScheme.onSurface,
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
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 450),
  });

  final double value;
  final double height;
  final Color color;
  final Color? backgroundColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor =
        backgroundColor ??
        (isDark ? MovaDesign.darkElevatedSurface : const Color(0xFFECECEC));
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor,
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

class MovaRadialHighlight extends StatelessWidget {
  const MovaRadialHighlight({super.key, this.color = MovaDesign.accent});

  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.85, -0.9),
          radius: 1.25,
          colors: [
            color.withValues(alpha: .2),
            color.withValues(alpha: .07),
            color.withValues(alpha: 0),
          ],
          stops: const [0, .42, 1],
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
              color: MovaDesign.softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: MovaDesign.accent, size: 29),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
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
