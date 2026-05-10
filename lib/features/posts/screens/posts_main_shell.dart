import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/posts/screens/feed_screen.dart';

class PostsMainShell extends ConsumerWidget {
  const PostsMainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: FeedScreen(),
    );
  }
}