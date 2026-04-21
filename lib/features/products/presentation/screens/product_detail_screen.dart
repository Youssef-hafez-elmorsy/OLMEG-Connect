import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/product_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/models/chat_model.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart' show authStateProvider;

class ProductDetailScreen extends ConsumerWidget {
  final ProductEntity product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isOwner = user?.id == product.sellerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())),
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(product.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(product.category, style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(product.price),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                  ),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(product.description, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF6C63FF),
                          radius: 24,
                          child: Text(
                            product.sellerName.isNotEmpty ? product.sellerName[0].toUpperCase() : 'S',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sold by', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(product.sellerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                              Text('ID: ${product.sellerId.substring(0, 8)}...', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment coming in Phase 2!'))),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Buy Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: isOwner
                        ? OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('This is your product!')),
                              );
                            },
                            icon: const Icon(Icons.store_outlined),
                            label: const Text('Your Product', style: TextStyle(fontSize: 16)),
                          )
                        : OutlinedButton.icon(
                            onPressed: user != null
                                ? () => _startChat(context, ref)
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please sign in to contact seller')),
                                    );
                                  },
                            icon: const Icon(Icons.chat_outlined),
                            label: const Text('Contact Seller', style: TextStyle(fontSize: 16)),
                          ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Image not available', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to contact seller')),
      );
      return;
    }

    if (user.id == product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your product!')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting chat...')),
    );

    final chatId = await ref.read(chatNotifierProvider.notifier).createChat(
      productId: product.id,
      productTitle: product.title,
      buyerId: user.id,
      buyerName: user.name,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (chatId != null && chatId.startsWith('Error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(chatId), backgroundColor: Colors.red),
        );
      } else if (chatId != null) {
        // Get the chat and navigate
        final ds = ref.read(chatRemoteDataSourceProvider);
        final chat = await ds.getChatById(chatId);
        if (chat != null && context.mounted) {
          context.push('/chat/$chatId', extra: chat);
        }
      }
    }
  }
}