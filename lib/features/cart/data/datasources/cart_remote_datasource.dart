import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_entity.dart';

abstract class CartRemoteDataSource {
  Future<void> addToCart(CartEntity cart);

  Future<List<CartEntity>> getUserCart(String oderId);

  Future<void> removeFromCart(String cartId);

  Future<void> updateQuantity(String cartId, int quantity);

  Future<void> clearCart(String oderId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final FirebaseFirestore firestore;

  CartRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> addToCart(CartEntity cart) async {
    await firestore.collection('carts').doc(cart.id).set({
      'id': cart.id,
      'oderId': cart.oderId,
      'productId': cart.productId,
      'productTitle': cart.productTitle,
      'price': cart.price,
      'imageUrl': cart.imageUrl,
      'sellerId': cart.sellerId,
      'sellerName': cart.sellerName,
      'quantity': cart.quantity,
      'addedAt': cart.addedAt.toIso8601String(),
    });
  }

  @override
  Future<List<CartEntity>> getUserCart(String oderId) async {
    final snapshot = await firestore
        .collection('carts')
        .where('oderId', isEqualTo: oderId)
        .get();

    return snapshot.docs.map((doc) {
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
    }).toList();
  }

  @override
  Future<void> removeFromCart(String cartId) async {
    await firestore.collection('carts').doc(cartId).delete();
  }

  @override
  Future<void> updateQuantity(String cartId, int quantity) async {
    await firestore.collection('carts').doc(cartId).update({'quantity': quantity});
  }

  @override
  Future<void> clearCart(String oderId) async {
    final snapshot = await firestore
        .collection('carts')
        .where('oderId', isEqualTo: oderId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}