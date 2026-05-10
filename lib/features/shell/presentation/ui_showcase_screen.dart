import 'package:flutter/material.dart';
import 'package:olmeg_connect/core/theme/app_theme.dart';
import 'package:olmeg_connect/features/posts/widgets/enhanced_post_card.dart';
import 'package:olmeg_connect/features/profile/presentation/screens/edit_profile_screen.dart';

class UIShowcaseScreen extends StatelessWidget {
  const UIShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F5F7);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('UI Showcase', style: TextStyle(color: textColor)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Edit Profile Preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profile Screen',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Open Edit Profile'),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.primary.withValues(alpha: 0.3)),
            // Enhanced Post Card Preview
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enhanced Post Card',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EnhancedPostCard(
                    authorName: 'Sarah Johnson',
                    authorAvatar: '👩',
                    postText:
                        'Beautiful vintage camera in excellent condition. Fully functional with original lens. Perfect for photography enthusiasts!',
                    priceTag: '\$150',
                    images: [
                      'https://via.placeholder.com/300x200?text=Camera+1',
                      'https://via.placeholder.com/300x200?text=Camera+2',
                    ],
                    likes: 234,
                    comments: 12,
                    shares: 5,
                    onLike: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liked!')),
                      );
                    },
                    onComment: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comment section opened')),
                      );
                    },
                    onShare: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shared!')),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  EnhancedPostCard(
                    authorName: 'Mike Chen',
                    authorAvatar: '👨',
                    postText:
                        'Selling my old laptop. Intel i7, 16GB RAM, 512GB SSD. Great for work or gaming. Asking \$600 OBO.',
                    priceTag: '\$600',
                    images: [
                      'https://via.placeholder.com/300x200?text=Laptop',
                    ],
                    likes: 89,
                    comments: 7,
                    shares: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
