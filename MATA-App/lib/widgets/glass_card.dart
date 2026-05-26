import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final bool borderGlow;
  final VoidCallback? onTap;

  const GlassCard({
    Key? key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.04,
    this.radius,
    this.padding,
    this.margin,
    this.gradient,
    this.borderGlow = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final br = radius ?? BorderRadius.circular(24.0);

    Widget content = ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? Colors.white.withOpacity(opacity) : null,
            gradient: gradient,
            borderRadius: br,
            border: Border.all(
              color: borderGlow ? AppColors.borderGlow : AppColors.border,
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
