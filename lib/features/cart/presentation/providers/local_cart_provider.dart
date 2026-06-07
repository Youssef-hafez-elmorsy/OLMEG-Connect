import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olmeg_connect/features/cart/domain/entities/cart_item.dart';
import 'package:olmeg_connect/features/auth/presentation/providers/auth_provider.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    ref.listen(authStateProvider, (_, next) {
      final user = next.value;
      if (user != null) {
        loadFromCloud(user.id);
      }
    });
    return const [];
  }

  void addItem(CartItem item) {
    if (!item.isAvailable) return;

    final index = state.indexWhere(
      (cartItem) =>
          cartItem.id == item.id &&
          cartItem.selectedVariant == item.selectedVariant &&
          !cartItem.savedForLater,
    );

    if (index == -1) {
      state = [...state, _clampQuantity(item)];
      _persist();
      return;
    }

    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index)
          _clampQuantity(
            state[i].copyWith(quantity: state[i].quantity + item.quantity),
          )
        else
          state[i],
    ];
    _persist();
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
    _persist();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    state = [
      for (final item in state)
        if (item.id == itemId)
          _clampQuantity(item.copyWith(quantity: quantity))
        else
          item,
    ];
    _persist();
  }

  void toggleSaveForLater(String itemId) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(savedForLater: !item.savedForLater)
        else
          item,
    ];
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  CartItem _clampQuantity(CartItem item) {
    final maxQuantity = item.stockQuantity < 1 ? 1 : item.stockQuantity;
    final quantity = item.quantity.clamp(1, maxQuantity);
    return item.copyWith(quantity: quantity);
  }

  Future<void> loadFromCloud(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('user_carts')
        .doc(userId)
        .get();
    final rawItems = doc.data()?['items'];
    if (rawItems is! List) return;
    state = rawItems.whereType<Map>().map((raw) {
      final data = Map<String, dynamic>.from(raw);
      return CartItem(
        id: data['id']?.toString() ?? '',
        title: data['title']?.toString() ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0,
        imageUrl: data['imageUrl']?.toString() ?? '',
        sellerId: data['sellerId']?.toString() ?? '',
        sellerName: data['sellerName']?.toString() ?? '',
        selectedVariant: data['selectedVariant'] as String?,
        stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 1,
        savedForLater: data['savedForLater'] == true,
        quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();
  }

  Future<void> _persist() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('user_carts').doc(user.id).set({
      'userId': user.id,
      'items': [
        for (final item in state)
          {
            'id': item.id,
            'title': item.title,
            'price': item.price,
            'imageUrl': item.imageUrl,
            'sellerId': item.sellerId,
            'sellerName': item.sellerName,
            'selectedVariant': item.selectedVariant,
            'stockQuantity': item.stockQuantity,
            'savedForLater': item.savedForLater,
            'quantity': item.quantity,
          }
      ],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() {
  return CartNotifier();
});

final cartTotalsProvider = Provider<CartTotals>((ref) {
  return CartTotals.fromItems(ref.watch(cartProvider));
});

final cartValidationProvider = Provider<List<String>>((ref) {
  final items = ref.watch(cartProvider);
  return [
    for (final item in items)
      if (!item.savedForLater && !item.hasValidQuantity)
        '${item.title} has only ${item.stockQuantity} available.',
  ];
});

final cartConflictProvider = FutureProvider<List<String>>((ref) async {
  final items = ref.watch(cartProvider).where((item) => !item.savedForLater);
  final conflicts = <String>[];
  for (final item in items) {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(item.id)
        .get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      conflicts.add('${item.title} is no longer available.');
      continue;
    }
    final livePrice = (data['salePriceOverride'] as num?)?.toDouble() ??
        (data['price'] as num?)?.toDouble() ??
        item.price;
    final liveStock = (data['stockQuantity'] as num?)?.toInt() ??
        (data['stock'] as num?)?.toInt() ??
        item.stockQuantity;
    final status = data['status'] as String? ?? 'active';
    if (livePrice != item.price) {
      conflicts.add('${item.title} price changed.');
    }
    if (liveStock < item.quantity) {
      conflicts.add('${item.title} has only $liveStock available.');
    }
    if (status == 'draft' || status == 'scheduled' || status == 'inactive') {
      conflicts.add('${item.title} is not currently sellable.');
    }
  }
  return conflicts;
});
