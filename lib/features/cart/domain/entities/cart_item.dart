import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String sellerId;
  final String sellerName;
  final String? selectedVariant;
  final int stockQuantity;
  final bool savedForLater;
  final int quantity;

  const CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    this.selectedVariant,
    this.stockQuantity = 1,
    this.savedForLater = false,
    this.quantity = 1,
  });

  double get lineTotal => savedForLater ? 0 : price * quantity;
  bool get isAvailable => stockQuantity > 0;
  bool get hasValidQuantity => quantity > 0 && quantity <= stockQuantity;

  CartItem copyWith({
    String? id,
    String? title,
    double? price,
    String? imageUrl,
    String? sellerId,
    String? sellerName,
    String? selectedVariant,
    int? stockQuantity,
    bool? savedForLater,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      savedForLater: savedForLater ?? this.savedForLater,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        price,
        sellerId,
        selectedVariant,
        stockQuantity,
        savedForLater,
        quantity,
      ];
}

class CartTotals extends Equatable {
  final double subtotal;
  final double shipping;
  final double discount;
  final double tax;

  const CartTotals({
    required this.subtotal,
    this.shipping = 0,
    this.discount = 0,
    this.tax = 0,
  });

  double get total => subtotal + shipping + tax - discount;

  factory CartTotals.fromItems(
    List<CartItem> items, {
    double shipping = 0,
    double discount = 0,
    double tax = 0,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    return CartTotals(
      subtotal: subtotal,
      shipping: shipping,
      discount: discount,
      tax: tax,
    );
  }

  @override
  List<Object?> get props => [subtotal, shipping, discount, tax];
}
