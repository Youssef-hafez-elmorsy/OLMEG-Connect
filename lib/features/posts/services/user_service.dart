import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';

class UserService {
  Future<UserIdentity?> getUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return null;

    String? profileImageUrl;
    String name = authUser.displayName ?? authUser.email?.split('@').first ?? 'User';

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();
      if (doc.exists) {
        profileImageUrl = doc.data()?['photoUrl'];
        name = doc.data()?['name'] ?? name;
      }
    } catch (_) {}

    return UserIdentity(
      userId: authUser.uid,
      displayName: name,
      profileImageUrl: profileImageUrl,
      avatarColor: '0xFF1E88E5',
    );
  }

  Future<bool> hasUser() async {
    return FirebaseAuth.instance.currentUser != null;
  }
}

class AvatarColors {
  static const List<Color> options = [
    Color(0xFFE53935),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF3949AB),
    Color(0xFF1E88E5),
    Color(0xFF00ACC1),
    Color(0xFF43A047),
    Color(0xFF7CB342),
    Color(0xFFFDD835),
    Color(0xFFFFB300),
    Color(0xFFFB8C00),
  ];

  static Color fromHex(String hex) {
    final value = hex.replaceAll('#', '0xFF');
    return Color(int.parse(value));
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}

class BackgroundGradients {
  static const Map<String, List<Color>> gradients = {
    'sunset': [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    'ocean': [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    'forest': [Color(0xFF134E5E), Color(0xFF71D280)],
    'purple': [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    'orange': [Color(0xFFF12711), Color(0xFFF5AF19)],
    'pink': [Color(0xFFEC008C), Color(0xFFFC6767)],
  };

  static List<Color> getGradient(String key) {
    return gradients[key] ?? gradients['sunset']!;
  }
}

class Feelings {
  static const List<Map<String, String>> options = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '🎉', 'label': 'Celebrating'},
    {'emoji': '😍', 'label': 'Loved'},
    {'emoji': '😡', 'label': 'Angry'},
    {'emoji': '🤔', 'label': 'Thinking'},
    {'emoji': '💪', 'label': 'Motivated'},
    {'emoji': '😴', 'label': 'Tired'},
  ];
}