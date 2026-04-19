import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Handmade Feed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.handshake_outlined, size: 80, color: Colors.purple.shade200),
              const Gap(16),
              const Text('Handmade Creator Feed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Gap(8),
              const Text(
                'Social posts, likes, comments, and creator follows are coming in Phase 2!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const Gap(24),
              ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon in Phase 2!'))),
                icon: const Icon(Icons.add),
                label: const Text('Create Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
