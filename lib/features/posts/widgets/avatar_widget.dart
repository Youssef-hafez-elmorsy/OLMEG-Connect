import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum AvatarSizeType {
  small,   // radius: 14 (28px) - comments
  medium,   // radius: 20 (40px) - posts
  large,    // radius: 32 (64px) - profile
}

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final String avatarColor;
  final AvatarSizeType sizeType;
  final bool showBorder;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    required this.avatarColor,
    this.sizeType = AvatarSizeType.medium,
    this.showBorder = false,
  });

  double get radius {
    switch (sizeType) {
      case AvatarSizeType.small:
        return 14;
      case AvatarSizeType.medium:
        return 20;
      case AvatarSizeType.large:
        return 32;
    }
  }

  double get fontSize => radius * 0.8;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(avatarColor);
    final initials = _getInitials(name);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                placeholder: (context, url) => _buildInitials(color, initials),
                errorWidget: (context, url, error) => _buildInitials(color, initials),
                memCacheWidth: (radius * 2 * 2).toInt(),
                memCacheHeight: (radius * 2 * 2).toInt(),
              )
            : _buildInitials(color, initials),
      ),
    );
  }

  Widget _buildInitials(Color color, String initials) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
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

class AvatarColors {
  static const List<Color> palette = [
    Color(0xFF39FF14),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
  ];

  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static Color fromName(String name) {
    final hash = name.hashCode;
    return palette[hash.abs() % palette.length];
  }
}
