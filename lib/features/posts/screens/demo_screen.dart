// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:olmeg_connect/features/posts/models/post_model.dart';
import 'package:olmeg_connect/features/posts/widgets/post_card.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Demo - تجربة'),
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Demo content refreshed.')),
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(context),
          const SizedBox(height: 16),
          _buildDemoPostsSection(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text('🎮 وضع التجربة',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'هذا وضع محاكاة لتجربة التطبيق.\nالمنشورات أدناه هي بيانات وهمية للعرض فقط.',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(context, '✅ Share Button', Colors.green),
                _buildChip(context, '✅ X Close Button', Colors.green),
                _buildChip(context, '✅ Remove Photo', Colors.green),
                _buildChip(context, '✅ Reactions', Colors.green),
                _buildChip(context, '✅ Comments', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
    );
  }

  Widget _buildDemoPostsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📝 منشورات تجريبية',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        // Post 1 - Simple text
        _buildDemoPost(
          context,
          authorName: 'أحمد محمد',
          authorColor: '0xFFE53935',
          text:
              'مرحباً! هذا منشور تجريبي يوضح كيف يعمل التطبيق. يمكنك رؤية زر المشاركة في أعلى المنشور بجانب القائمة! 👆',
          feeling: '😊 Happy',
          hoursAgo: 2,
          audience: 'public',
          likes: 24,
          comments: 8,
        ),

        const SizedBox(height: 16),

        // Post 2 - With image
        _buildDemoPost(
          context,
          authorName: 'سارة علي',
          authorColor: '0xFF5E35B1',
          text: 'منظر جميل من الأعلى! 🌄',
          imageUrl:
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
          hoursAgo: 5,
          audience: 'friends',
          likes: 156,
          comments: 23,
        ),

        const SizedBox(height: 16),

        // Post 3 - With background
        _buildDemoPost(
          context,
          authorName: 'محمد خالد',
          authorColor: '0xFF1E88E5',
          text: 'يوم جميل للتفكير الإيجابي! ✨',
          bgColor: 'sunset',
          hoursAgo: 8,
          audience: 'public',
          likes: 89,
          comments: 12,
        ),

        const SizedBox(height: 16),

        // Post 4 - Multiple images
        _buildDemoPost(
          context,
          authorName: 'فاطمة عمر',
          authorColor: '0xFF43A047',
          text: 'عائلة سعيدة! ❤️',
          imageUrls: [
            'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=400',
            'https://images.unsplash.com/photo-1516627145497-ae6968895b74?w=400',
            'https://images.unsplash.com/photo-1504439468489-c8920d796a29?w=400',
          ],
          hoursAgo: 12,
          audience: 'friends',
          likes: 234,
          comments: 45,
        ),

        const SizedBox(height: 16),

        // Post 5 - With location
        _buildDemoPost(
          context,
          authorName: 'عمر حسن',
          authorColor: '0xFFFFB300',
          text: 'إجازة رائعة في海滨! 🏖️',
          location: 'جدة، السعودية',
          hoursAgo: 1,
          audience: 'public',
          likes: 67,
          comments: 15,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDemoPost(
    BuildContext context, {
    required String authorName,
    required String authorColor,
    required String text,
    String? feeling,
    String? imageUrl,
    List<String>? imageUrls,
    String? bgColor,
    String? location,
    required int hoursAgo,
    required String audience,
    required int likes,
    required int comments,
  }) {
    final images = <String>[];
    if (imageUrl != null) images.add(imageUrl);
    if (imageUrls != null) images.addAll(imageUrls);

    final post = PostModel(
      id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'demo_user',
      authorName: authorName,
      authorAvatarColor: authorColor,
      text: text,
      bgColor: bgColor,
      feeling: feeling,
      location: location,
      imageURLs: images,
      audience: audience,
      createdAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
      reactions: {
        'like': ['user1', 'user2', 'user3'],
        'love': ['user4']
      },
      commentCount: comments,
    );

    return PostCard(
      post: post,
      onDelete: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🗑️ تم حذف المنشور: $authorName')),
        );
      },
      onCommentTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('💬 فتح التعليقات')),
        );
      },
    );
  }
}
