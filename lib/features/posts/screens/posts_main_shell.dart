import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/posts/screens/feed_screen.dart';
import 'package:olmeg_connect/features/posts/screens/create_post_screen.dart';
import 'package:olmeg_connect/features/posts/screens/profile_screen.dart';

class PostsMainShell extends ConsumerStatefulWidget {
  const PostsMainShell({super.key});

  @override
  ConsumerState<PostsMainShell> createState() => _PostsMainShellState();
}

class _PostsMainShellState extends ConsumerState<PostsMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const SizedBox.shrink(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 1 ? 0 : _currentIndex,
        children: [
          const FeedScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
          } else {
            setState(() => _currentIndex = index);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}