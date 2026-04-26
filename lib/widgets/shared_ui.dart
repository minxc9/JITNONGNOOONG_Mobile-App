import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.orange),
    );
  }
}

class DashboardTabBarContainer extends StatelessWidget {
  final Widget child;

  const DashboardTabBarContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Container(
        height: 54,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      ),
    );
  }
}

class AppMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const AppMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
          foregroundColor: Colors.orange,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class AppRemoteImageBox extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double fallbackIconSize;

  const AppRemoteImageBox({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.fallbackIconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _fallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: Colors.orange.withValues(alpha: 0.08),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.orange.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: fallbackIconSize,
          color: Colors.orange,
        ),
      ),
    );
  }
}

class AppOutlinedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final double elevation;
  final Color backgroundColor;
  final double shadowAlpha;

  const AppOutlinedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 18,
    this.borderColor = const Color(0xFFE5E7EB),
    this.borderWidth = 1,
    this.elevation = 0,
    this.backgroundColor = Colors.white,
    this.shadowAlpha = 0.04,
  });

  @override
  Widget build(BuildContext context) {
    final contents = padding == null
        ? child
        : Padding(
            padding: padding!,
            child: child,
          );

    return Card(
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      color: backgroundColor,
      elevation: elevation,
      surfaceTintColor: backgroundColor,
      shadowColor: Colors.black.withValues(alpha: shadowAlpha),
      child: contents,
    );
  }
}

class AppDashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final double iconContainerSize;
  final double iconSize;
  final double valueFontSize;
  final EdgeInsetsGeometry padding;

  const AppDashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.iconContainerSize = 46,
    this.iconSize = 26,
    this.valueFontSize = 24,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return AppOutlinedCard(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.blueGrey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: iconSize),
          ),
        ],
      ),
    );
  }
}

class AppPrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double minHeight;

  const AppPrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF07031A),
    this.foregroundColor = Colors.white,
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: Size.fromHeight(minHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
