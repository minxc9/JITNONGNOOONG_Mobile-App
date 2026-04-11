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
