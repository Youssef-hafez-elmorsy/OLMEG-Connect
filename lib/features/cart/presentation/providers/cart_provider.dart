import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_entity.dart';
import 'package:olmeg_connect/features/cart/data/datasources/cart_remote_datasource.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  return CartRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final cartItemsProvider = StreamProvider.family<List<CartEntity>, String>((ref, oderId) {
  return FirebaseFirestore.instance
      .collection('carts')
      .where('oderId', isEqualTo: oderId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
        final data = doc.data();
        return CartEntity(
          id: data['id'] ?? '',
          oderId: data['oderId'] ?? '',
          productId: data['productId'] ?? '',
          productTitle: data['productTitle'] ?? '',
          price: (data['price'] ?? 0).toDouble(),
          imageUrl: data['imageUrl'] ?? '',
          sellerId: data['sellerId'] ?? '',
          sellerName: data['sellerName'] ?? '',
          quantity: data['quantity'] ?? 1,
          addedAt: data['addedAt'] != null
              ? DateTime.parse(data['addedAt'])
              : DateTime.now(),
        );
      }).toList());
});

final addToCartProvider = FutureProvider.family<void, CartEntity>((ref, cart) async {
  final dataSource = ref.watch(cartRemoteDataSourceProvider);
  await dataSource.addToCart(cart);
});

final removeFromCartProvider = FutureProvider.family<void, String>((ref, cartId) async {
  final dataSource = ref.watch(cartRemoteDataSourceProvider);
  await dataSource.removeFromCart(cartId);
});

final clearCartProvider = FutureProvider.family<void, String>((ref, oderId) async {
  final dataSource = ref.watch(cartRemoteDataSourceProvider);
  await dataSource.clearCart(oderId);
});

final cartTotalProvider = Provider.family<double, List<CartEntity>>((ref, items) {
  return items.fold(0, (sum, item) => sum + (item.total));
});