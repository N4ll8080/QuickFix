import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphismTheme {
  // Color Palette - Clean Blue and White
  static const Color primaryBlue = Color(0xFF0B84FF);
  static const Color darkBlue = Color(0xFF1E6FFF);
  static const Color lightBlue = Color(0xFF4DA3FF);
  static const Color softBlue = Color(0xFFE3F2FD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color glassWhite = Color(0xFFFFFFFF);
  static const Color darkOverlay = Color(0x80000000);

  // Glassmorphism Container Widget
  static Widget glassContainer({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16,
    double blur = 10,
    double opacity = 0.2,
    Color borderColor = Colors.white,
    double borderWidth = 1.5,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor.withOpacity(0.3),
          width: borderWidth,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      glassWhite.withOpacity(opacity),
                      glassWhite.withOpacity(opacity * 0.8),
                    ],
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // Glassmorphic Button
  static Widget glassButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 12,
    EdgeInsetsGeometry? padding,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        child: glassContainer(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          borderRadius: borderRadius,
          borderColor: backgroundColor ?? primaryBlue,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: textColor ?? white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor ?? white,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Glassmorphic Search Bar
  static Widget glassSearchBar({
    required String hintText,
    VoidCallback? onTap,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      child: Row(
        children: [
          Icon(Icons.search, color: primaryBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap != null ? () => onTap() : null,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glassmorphic Card with Hover Animation
  static Widget glassCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16,
    bool animateOnHover = true,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, childWidget) {
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: onTap,
            child: glassContainer(
              padding: padding ?? const EdgeInsets.all(16),
              margin: margin ?? const EdgeInsets.only(bottom: 16),
              borderRadius: borderRadius,
              child: childWidget ?? child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  // Animated Service Category Card
  static Widget animatedServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: GestureDetector(
              onTap: onTap,
              child: glassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (iconColor ?? primaryBlue).withOpacity(0.2),
                            (iconColor ?? primaryBlue).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: iconColor ?? primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Status Badge with Glassmorphism
  static Widget glassStatusBadge({
    required String text,
    required Color color,
  }) {
    return glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 20,
      opacity: 0.3,
      borderColor: color,
      borderWidth: 1,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Rating Widget with Stars
  static Widget glassRating({
    required double rating,
    required int reviewCount,
    double starSize = 16,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor()
                ? Icons.star
                : (index < rating ? Icons.star_half : Icons.star_border),
            color: Colors.amber,
            size: starSize,
          );
        }),
        const SizedBox(width: 6),
        Text(
          "${rating.toStringAsFixed(1)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        if (reviewCount > 0)
          Text(
            " ($reviewCount)",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
      ],
    );
  }

  // Animated Card with Hover Effect and Glow
  static Widget animatedGlassCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 16,
    bool enableGlow = true,
  }) {
    return _AnimatedGlassCardWidget(
      child: child,
      onTap: onTap,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      enableGlow: enableGlow,
    );
  }
}

// Helper widget for animated glass card with state
class _AnimatedGlassCardWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool enableGlow;

  const _AnimatedGlassCardWidget({
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.enableGlow = true,
  });

  @override
  State<_AnimatedGlassCardWidget> createState() => _AnimatedGlassCardWidgetState();
}

class _AnimatedGlassCardWidgetState extends State<_AnimatedGlassCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        child: GlassmorphismTheme.glassContainer(
          padding: widget.padding ?? const EdgeInsets.all(16),
          margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
          borderRadius: widget.borderRadius,
          boxShadow: widget.enableGlow && _isPressed
              ? [
                  BoxShadow(
                    color: GlassmorphismTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
          child: widget.child,
        ),
      ),
    );
  }

  // Floating Action Button with Glassmorphism
  static Widget glassFloatingActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    String? label,
    Color? backgroundColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(label != null ? 28 : 28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (backgroundColor ?? GlassmorphismTheme.primaryBlue).withOpacity(0.9),
                (backgroundColor ?? GlassmorphismTheme.darkBlue).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(label != null ? 28 : 28),
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? GlassmorphismTheme.primaryBlue).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(label != null ? 28 : 28),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: label != null ? 24 : 16,
                  vertical: label != null ? 16 : 16,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    if (label != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Glassmorphic App Bar
  static Widget glassAppBar({
    required String title,
    Widget? leading,
    List<Widget>? actions,
    double height = 120,
  }) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                GlassmorphismTheme.primaryBlue.withOpacity(0.9),
                GlassmorphismTheme.darkBlue.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (leading != null) leading,
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (actions != null) ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Shimmer Loading Effect
  static Widget shimmerLoader({
    double width = double.infinity,
    double height = 20,
    double borderRadius = 8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
      },
    );
  }
}

