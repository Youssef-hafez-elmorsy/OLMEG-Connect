import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/presentation/widgets/category_filter.dart';
import '../../../products/presentation/widgets/product_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(productsStreamProvider(selectedCategory));
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${user?.name.split(' ').first ?? 'there'} 👋', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.normal)),
            const Text('Olmeg Connect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const CategoryFilter(),
          const SizedBox(height: 12),
          Expanded(
            child: productsAsync.when(
              loading: () => const ShimmerGrid(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No products found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Be the first to list in this category!', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => ProductCard(product: products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
