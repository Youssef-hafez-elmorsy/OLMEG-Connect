import 'package:flutter/material.dart';
import 'package:olmeg_connect/features/posts/services/user_service.dart';

class AvatarWidget extends StatelessWidget {
  final String? name;
  final String avatarColor;
  final double radius;
  final bool showBorder;

  const AvatarWidget({
    super.key,
    this.name,
    required this.avatarColor,
    this.radius = 20,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final color = _parseColor(avatarColor);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return AvatarColors.fromHex(colorStr);
      }
      return Color(int.parse(colorStr));
    } catch (e) {
      return Colors.grey;
    }
  }
}